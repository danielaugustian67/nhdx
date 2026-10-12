import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/database/providers.dart';
import '../../core/database/user_db.dart';
import '../auth/auth_service.dart';
import 'sync_engine.dart';
import 'sync_remote.dart';

/// Null without a Supabase project (tests, builds without env): no sync.
final syncRemoteProvider = Provider<SyncRemote?>(
  (ref) => Env.hasSupabase ? SupabaseSyncRemote(Supabase.instance.client) : null,
);

enum SyncPhase {
  /// Signed out or no cloud: nothing to sync.
  off,
  idle,
  syncing,

  /// The last try failed; another one is scheduled.
  failed,
}

@immutable
class SyncStatus {
  const SyncStatus({this.phase = SyncPhase.off, this.pending = 0, this.lastSyncedAt, this.offline = false});

  final SyncPhase phase;

  /// Changes made here that the cloud does not have yet.
  final int pending;
  final DateTime? lastSyncedAt;

  /// The last failure looked like no connection.
  final bool offline;

  SyncStatus copyWith({SyncPhase? phase, int? pending, DateTime? lastSyncedAt, bool? offline}) => SyncStatus(
    phase: phase ?? this.phase,
    pending: pending ?? this.pending,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    offline: offline ?? this.offline,
  );
}

/// When to sync (development_plan Fase 4): after sign-in, at launch, when the
/// app comes back to the foreground, a few seconds after a local change, and
/// again with growing pauses after a failure.
class SyncController extends Notifier<SyncStatus> {
  static const _lastSyncKey = 'last_sync_at';
  static const debounce = Duration(seconds: 3);
  static const firstRetry = Duration(seconds: 30);
  static const maxRetry = Duration(minutes: 15);

  SyncEngine? _engine;

  /// Set up the engine of the current account; sync waits for it.
  Future<void>? _ready;

  /// Counts builds, so a start that finishes after the next build is dropped.
  int _generation = 0;
  Future<bool>? _running;
  String? _userId;
  bool _again = false;
  Timer? _debounce;
  Timer? _retry;
  int _failures = 0;
  StreamSubscription<void>? _changes;

  @override
  SyncStatus build() {
    final remote = ref.watch(syncRemoteProvider);
    final auth = ref.watch(authServiceProvider);
    // Before the first auth event the saved session already knows the user;
    // falling back to it inside select avoids a rebuild when the event comes.
    final userId = ref.watch(authUserProvider.select((u) => u.value?.id ?? auth?.currentUser?.id));
    ref.onDispose(() {
      _debounce?.cancel();
      _retry?.cancel();
      _changes?.cancel();
      _engine = null;
    });
    _engine = null;
    _ready = null;
    _userId = userId;
    _failures = 0;
    final generation = ++_generation;
    // While signing in, the sign-in screen restores the account itself.
    if (remote == null || userId == null || ref.watch(signingInProvider)) return const SyncStatus();
    final ready = _ready = _start(remote, generation);
    unawaited(ready.then((_) => sync()));
    return const SyncStatus(phase: SyncPhase.idle);
  }

  Future<void> _start(SyncRemote remote, int generation) async {
    final UserDb db;
    try {
      db = await ref.read(userDbProvider.future);
    } catch (e) {
      debugPrint('sync not started: $e');
      return;
    }
    final last = DateTime.tryParse(await db.meta(_lastSyncKey) ?? '');
    if (!ref.mounted || generation != _generation) return;
    final engine = _engine = SyncEngine(db, remote);
    _changes = db
        .tableUpdates()
        .where((updates) => updates.any((u) => syncedTables.contains(u.table)))
        .listen((_) => _changed());
    final pending = await engine.pendingCount();
    if (!_live(engine)) return;
    state = state.copyWith(lastSyncedAt: last, pending: pending);
  }

  /// Waits for the engine of the newest build (a rebuild may start another).
  Future<void> _whenReady() async {
    while (true) {
      final ready = _ready;
      await ready;
      if (identical(ready, _ready)) return;
    }
  }

  /// Still the engine of the current account (the user may sign out mid-sync).
  bool _live(SyncEngine engine) => ref.mounted && identical(_engine, engine);

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(debounce, () async {
      final engine = _engine;
      if (engine == null) return;
      final pending = await engine.pendingCount();
      if (!_live(engine)) return;
      state = state.copyWith(pending: pending);
      // Pulled rows arrive already synced, so a pull does not start another sync.
      if (pending > 0) unawaited(sync());
    });
  }

  /// Syncs now unless the data here belongs to another account (claimed at
  /// sign-in). [full] pulls everything, for restoring an account. Returns
  /// whether the cloud and this phone agree afterwards.
  Future<bool> sync({bool full = false}) async {
    await _whenReady();
    if (_running case final running?) {
      if (!full) {
        _again = true;
        return running;
      }
      await running;
    }
    final run = _run(full: full);
    _running = run;
    try {
      return await run;
    } finally {
      if (identical(_running, run)) _running = null;
      if (_again) {
        _again = false;
        unawaited(sync());
      }
    }
  }

  Future<bool> _run({required bool full}) async {
    final engine = _engine;
    final userId = _userId;
    if (engine == null || userId == null) return false;
    if (await engine.db.meta('owner_user_id') != userId) return false;
    _retry?.cancel();
    state = state.copyWith(phase: SyncPhase.syncing);
    try {
      await engine.sync(full: full);
      if (!_live(engine)) return false;
      final now = DateTime.now();
      await engine.db.setMeta(_lastSyncKey, now.toUtc().toIso8601String());
      _failures = 0;
      final pending = await engine.pendingCount();
      if (!_live(engine)) return false;
      state = SyncStatus(phase: SyncPhase.idle, pending: pending, lastSyncedAt: now);
      return true;
    } catch (e) {
      debugPrint('sync failed: $e');
      if (!_live(engine)) return false;
      final wait = firstRetry * pow(2, min(_failures, 5)).toInt();
      _failures++;
      _retry = Timer(wait > maxRetry ? maxRetry : wait, () => unawaited(sync()));
      final pending = await engine.pendingCount();
      if (!_live(engine)) return false;
      state = state.copyWith(phase: SyncPhase.failed, pending: pending, offline: authFailure(e) == AuthFailure.offline);
      return false;
    }
  }

  /// Pushes what is left before signing out, giving up after [timeout].
  /// Returns how many changes are still only on this phone.
  Future<int> flush({Duration timeout = const Duration(seconds: 10)}) async {
    await _whenReady();
    final engine = _engine;
    if (engine == null) return 0;
    try {
      await sync().timeout(timeout);
    } catch (e) {
      debugPrint('sync before sign out: $e');
    }
    return engine.pendingCount();
  }
}

final syncProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);

/// Keeps sync running while the app is open and syncs when it comes back to
/// the foreground.
class SyncScheduler extends ConsumerStatefulWidget {
  const SyncScheduler({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SyncScheduler> createState() => _SyncSchedulerState();
}

class _SyncSchedulerState extends ConsumerState<SyncScheduler> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(ref.read(syncProvider.notifier).sync()));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncProvider);
    return widget.child;
  }
}
