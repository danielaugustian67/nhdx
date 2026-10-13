import 'package:drift/drift.dart';

import '../../core/database/user_db.dart';
import 'sync_remote.dart';

/// How a table resolves two versions of one row (PRD §8.4). The server's
/// push RPCs use the same rules, so both sides pick the same winner.
enum _Merge { lastWrite, srs, lesson, appendOnly }

/// One synced table: its local and cloud names and how columns map. Local
/// `updated_at` is the device time of the change and travels as the cloud's
/// `client_updated_at`; the cloud's own `updated_at` is only the pull cursor.
class _Table {
  const _Table({
    required this.local,
    required this.remote,
    required this.rpc,
    required this.keys,
    required this.columns,
    this.merge = _Merge.lastWrite,
    this.bools = const {},
    this.times = const {},
    this.softDelete = false,
  });

  final String local;
  final String remote;
  final String rpc;

  /// Primary key columns (same names on both sides).
  final List<String> keys;

  /// Data columns besides the keys and `updated_at`, same names on both sides.
  final List<String> columns;
  final _Merge merge;

  /// Integer 0/1 locally, boolean in the cloud.
  final Set<String> bools;

  /// Timestamps, kept locally as UTC ISO-8601 text.
  final Set<String> times;

  /// Has `deleted_at`; tombstones older than 30 days are purged in the cloud.
  final bool softDelete;

  bool get appendOnly => merge == _Merge.appendOnly;
}

const _tables = [
  _Table(local: 'user_settings', remote: 'user_settings', rpc: 'sync_push_settings', keys: ['key'], columns: ['value']),
  _Table(
    local: 'bookmarks',
    remote: 'user_bookmarks',
    rpc: 'sync_push_bookmarks',
    keys: ['id'],
    columns: ['word_id', 'label_snapshot', 'created_at', 'deleted_at'],
    times: {'created_at', 'deleted_at'},
    softDelete: true,
  ),
  _Table(
    local: 'srs_cards',
    remote: 'user_srs_cards',
    rpc: 'sync_push_srs_cards',
    keys: ['id'],
    columns: [
      'card_type',
      'item_id',
      'direction',
      'label_snapshot',
      'state',
      'due_at',
      'interval_days',
      'ease',
      'reps',
      'lapses',
      'is_orphan',
      'created_at',
      'deleted_at',
    ],
    merge: _Merge.srs,
    bools: {'is_orphan'},
    times: {'due_at', 'created_at', 'deleted_at'},
    softDelete: true,
  ),
  _Table(
    local: 'lesson_progress',
    remote: 'user_lesson_progress',
    rpc: 'sync_push_lesson_progress',
    keys: ['id'],
    columns: ['lesson_id', 'status', 'score', 'completed_at', 'deleted_at'],
    merge: _Merge.lesson,
    times: {'completed_at', 'deleted_at'},
    softDelete: true,
  ),
  _Table(
    local: 'daily_stats',
    remote: 'user_daily_stats',
    rpc: 'sync_push_daily_stats',
    keys: ['date', 'device_id'],
    columns: ['new_count', 'review_count', 'correct_count', 'study_ms', 'xp'],
  ),
  _Table(
    local: 'review_logs',
    remote: 'user_review_logs',
    rpc: 'sync_push_review_logs',
    keys: ['id'],
    columns: [
      'card_id',
      'rating',
      'reviewed_at',
      'study_date',
      'prev_state',
      'prev_interval',
      'new_interval',
      'duration_ms',
    ],
    merge: _Merge.appendOnly,
    times: {'reviewed_at'},
  ),
  _Table(
    local: 'exercise_attempts',
    remote: 'user_exercise_attempts',
    rpc: 'sync_push_exercise_attempts',
    keys: ['id'],
    columns: ['exercise_type', 'item_id', 'correct', 'answered_at', 'study_date', 'duration_ms'],
    merge: _Merge.appendOnly,
    bools: {'correct'},
    times: {'answered_at'},
  ),
  _Table(
    local: 'game_scores',
    remote: 'user_game_scores',
    rpc: 'sync_push_game_scores',
    keys: ['id'],
    columns: ['game', 'score', 'accuracy', 'played_at'],
    merge: _Merge.appendOnly,
    times: {'played_at'},
  ),
  _Table(
    local: 'streak_freezes',
    remote: 'user_streak_freezes',
    rpc: 'sync_push_streak_freezes',
    keys: ['id'],
    columns: ['covered_date', 'created_at'],
    merge: _Merge.appendOnly,
    times: {'created_at'},
  ),
];

/// Local tables that sync; writes to them start a push.
final syncedTables = {for (final t in _tables) t.local};

/// Rows of a table that are still to be pushed. Settings of this device
/// (`device.*`) never leave it.
String _pendingWhere(_Table t) =>
    t.local == 'user_settings' ? "sync_status = 1 AND key NOT LIKE 'device.%'" : 'sync_status = 1';

/// Outbox sync of user.db with the cloud (PRD §8, development_plan Fase 4):
/// rows changed here are marked pending and pushed in batches; rows changed
/// elsewhere are pulled by server time and merged with the same rules the
/// server uses.
class SyncEngine {
  SyncEngine(this.db, this.remote, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final UserDb db;
  final SyncRemote remote;
  final DateTime Function() _clock;

  static const batchSize = 500;
  static const pageSize = 1000;

  /// Rows changed in the cloud while a pull runs may carry an earlier
  /// `updated_at` than the newest already read; re-reading this much avoids
  /// missing them.
  static const overlap = Duration(minutes: 5);

  /// Tombstones live this long in the cloud; a device away longer pulls
  /// everything again.
  static const purgeAfter = Duration(days: 30);

  Future<int> pendingCount() async {
    var n = 0;
    for (final t in _tables) {
      final row = await db.customSelect('SELECT COUNT(*) AS n FROM ${t.local} WHERE ${_pendingWhere(t)}').getSingle();
      n += row.read<int>('n');
    }
    return n;
  }

  /// Pushes, then pulls. [full] pulls everything (sign-in recovery).
  ///
  /// Each table goes on its own: a table the cloud rejects (a value its
  /// schema does not allow yet, say) stays pending while the others still
  /// sync. The first error is rethrown afterwards so the sync counts as
  /// failed and is retried.
  Future<void> sync({bool full = false}) async {
    final errors = <(Object, StackTrace)>[];
    void collect(Object e, StackTrace st) => errors.add((e, st));
    await push(onError: collect);
    await pull(full: full, onError: collect);
    if (errors.isNotEmpty) Error.throwWithStackTrace(errors.first.$1, errors.first.$2);
  }

  /// Runs [body] for every table; without [onError] the first error stops.
  Future<void> _eachTable(Future<void> Function(_Table t) body, void Function(Object, StackTrace)? onError) async {
    for (final t in _tables) {
      try {
        await body(t);
      } catch (e, st) {
        if (onError == null) rethrow;
        onError(e, st);
      }
    }
  }

  Future<void> push({void Function(Object error, StackTrace stack)? onError}) => _eachTable((t) async {
    while (true) {
      final rows = await db.customSelect('SELECT * FROM ${t.local} WHERE ${_pendingWhere(t)} LIMIT $batchSize').get();
      if (rows.isEmpty) break;
      await remote.push(t.rpc, [for (final r in rows) _toRemote(t, r.data)]);
      await db.transaction(() async {
        for (final r in rows) {
          // Only rows unchanged since they were read count as synced; a
          // change made during the push goes in the next one.
          final where = [for (final k in t.keys) '$k = ?', if (!t.appendOnly) 'updated_at = ?'].join(' AND ');
          await db.customUpdate(
            'UPDATE ${t.local} SET sync_status = 0 WHERE $where',
            variables: [for (final k in t.keys) Variable(r.data[k]), if (!t.appendOnly) Variable(r.data['updated_at'])],
            updates: {_tableInfo(t)},
          );
        }
      });
      if (rows.length < batchSize) break;
    }
  }, onError);

  Future<void> pull({bool full = false, void Function(Object error, StackTrace stack)? onError}) =>
      _eachTable((t) async {
        final last = full ? null : await _lastPull(t.remote);
        final stale = last != null && _clock().toUtc().difference(DateTime.parse(last)) > purgeAfter;
        final since = last == null || stale ? null : DateTime.parse(last).subtract(overlap).toUtc().toIso8601String();
        // After a long absence deletions may have been purged in the cloud; rows
        // not seen in a full pull are gone there (only synced ones are dropped).
        final seen = stale && t.softDelete ? <String>{} : null;
        String? newest;
        for (var offset = 0; ; offset += pageSize) {
          final page = await remote.pull(t.remote, since: since, order: t.keys, offset: offset, limit: pageSize);
          if (page.isEmpty) break;
          await db.transaction(() async {
            for (final row in page) {
              await _apply(t, row);
              seen?.add('${row['id']}');
            }
          });
          for (final row in page) {
            final at = row['updated_at'] as String?;
            if (at != null && (newest == null || DateTime.parse(at).isAfter(DateTime.parse(newest)))) newest = at;
          }
          if (page.length < pageSize) break;
        }
        if (seen != null) {
          final gone = await db.customSelect('SELECT id FROM ${t.local} WHERE sync_status = 0').get();
          for (final r in gone) {
            final id = r.read<String>('id');
            if (seen.contains(id)) continue;
            await db.customUpdate(
              'DELETE FROM ${t.local} WHERE id = ? AND sync_status = 0',
              variables: [Variable(id)],
              updates: {_tableInfo(t)},
              updateKind: UpdateKind.delete,
            );
          }
        }
        if (newest != null) {
          await db.customStatement(
            'INSERT INTO sync_state (table_name, last_pull_at) VALUES (?, ?) '
            'ON CONFLICT (table_name) DO UPDATE SET last_pull_at = excluded.last_pull_at',
            [t.remote, DateTime.parse(newest).toUtc().toIso8601String()],
          );
        }
      }, onError);

  Future<String?> _lastPull(String table) async {
    final row = await db
        .customSelect('SELECT last_pull_at FROM sync_state WHERE table_name = ?', variables: [Variable(table)])
        .getSingleOrNull();
    return row?.read<String?>('last_pull_at');
  }

  TableInfo _tableInfo(_Table t) => db.allTables.firstWhere((x) => x.actualTableName == t.local);

  Row _toRemote(_Table t, Map<String, Object?> local) => {
    for (final k in t.keys) k: local[k],
    for (final c in t.columns) c: t.bools.contains(c) ? local[c] == 1 : local[c],
    if (!t.appendOnly) 'client_updated_at': local['updated_at'],
  };

  /// Merges one cloud row: a row synced here takes the cloud version (the
  /// server already picked the winner); a row still pending here keeps
  /// whichever wins by the table's rule.
  Future<void> _apply(_Table t, Row remote) async {
    final values = <String, Object?>{
      for (final k in t.keys) k: remote[k],
      for (final c in t.columns) c: _fromRemote(t, c, remote[c]),
    };
    if (t.local == 'user_settings') values['value'] = _settingValue(remote['value']);
    if (t.appendOnly) {
      await _write(t, values, ignoreExisting: true);
      return;
    }
    values['updated_at'] = _time(remote['client_updated_at']);
    final where = [for (final k in t.keys) '$k = ?'].join(' AND ');
    final local = await db
        .customSelect('SELECT * FROM ${t.local} WHERE $where', variables: [for (final k in t.keys) Variable(values[k])])
        .getSingleOrNull();
    if (local != null && local.data['sync_status'] == 1 && !_remoteWins(t, local.data, values)) return;
    await _write(t, values);
  }

  Future<void> _write(_Table t, Map<String, Object?> values, {bool ignoreExisting = false}) {
    final columns = [...values.keys, 'sync_status'];
    final placeholders = List.filled(columns.length, '?').join(', ');
    final verb = ignoreExisting ? 'INSERT OR IGNORE' : 'INSERT OR REPLACE';
    return db.customUpdate(
      '$verb INTO ${t.local} (${columns.join(', ')}) VALUES ($placeholders)',
      variables: [for (final v in values.values) Variable(v), const Variable(0)],
      updates: {_tableInfo(t)},
      updateKind: UpdateKind.insert,
    );
  }

  static bool _remoteWins(_Table t, Map<String, Object?> local, Map<String, Object?> remote) {
    int at(Map<String, Object?> r) => DateTime.parse(r['updated_at']! as String).microsecondsSinceEpoch;
    final List<num> l, r;
    switch (t.merge) {
      case _Merge.srs:
        l = [local['reps']! as int, at(local)];
        r = [remote['reps']! as int, at(remote)];
      case _Merge.lesson:
        int rank(Object? s) => switch (s) {
          'done' => 2,
          'in_progress' => 1,
          _ => 0,
        };
        l = [rank(local['status']), (local['score'] as num?) ?? -1, at(local)];
        r = [rank(remote['status']), (remote['score'] as num?) ?? -1, at(remote)];
      case _Merge.lastWrite || _Merge.appendOnly:
        l = [at(local)];
        r = [at(remote)];
    }
    for (var i = 0; i < l.length; i++) {
      if (r[i] != l[i]) return r[i] > l[i];
    }
    return false;
  }

  static Object? _fromRemote(_Table t, String column, Object? v) {
    if (v == null) return null;
    if (t.bools.contains(column)) return v == true ? 1 : 0;
    if (t.times.contains(column)) return _time(v);
    return v;
  }

  /// Cloud timestamps come back as `…+00:00`; local ones are `…Z`, and
  /// queries compare them as text.
  static String? _time(Object? v) => v == null ? null : DateTime.parse(v as String).toUtc().toIso8601String();

  /// Settings are text here and JSON in the cloud (pushed as JSON strings).
  static String? _settingValue(Object? v) => switch (v) {
    null => null,
    final String s => s,
    _ => '$v',
  };
}
