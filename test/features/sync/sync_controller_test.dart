import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/features/auth/auth_service.dart';
import 'package:nihondx/features/sync/sync_controller.dart';

import 'fake_cloud.dart';

class _SignedIn implements AuthService {
  _SignedIn([this.currentUser = (id: 'user-1', email: 'ana@contoh.id')]);
  final _changes = StreamController<Account?>.broadcast();

  @override
  Account? currentUser;

  @override
  Stream<Account?> get userChanges => _changes.stream;

  @override
  Future<void> signOut() async {
    currentUser = null;
    _changes.add(null);
  }

  @override
  Future<void> signIn(String email, String password) => throw UnimplementedError();
  @override
  Future<void> sendCode(String email) => throw UnimplementedError();

  @override
  Future<bool> signUp(String email, String password) => throw UnimplementedError();

  @override
  Future<void> confirmSignUp(String email, String code) => throw UnimplementedError();

  @override
  Future<void> resendSignUpCode(String email) => throw UnimplementedError();
  @override
  Future<void> verifyCode(String email, String code) => throw UnimplementedError();
  @override
  Future<void> setPassword(String password) => throw UnimplementedError();
  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late FakeCloud cloud;
  late UserDb db;
  late _SignedIn auth;

  setUp(() async {
    cloud = FakeCloud();
    db = UserDb.memory();
    auth = _SignedIn();
    await db.claimFor('user-1');
    await db.setSetting('learning_level', 'n5');
    await db.setBookmark(42, on: true, label: 'x');
  });
  tearDown(() => db.close());

  ProviderContainer start() {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        userDbProvider.overrideWith((ref) async => db),
        syncRemoteProvider.overrideWithValue(cloud),
      ],
    );
    addTearDown(container.dispose);
    container.listen(syncProvider, (_, _) {});
    return container;
  }

  Future<void> until(bool Function() done, {Duration max = const Duration(seconds: 6)}) async {
    final watch = Stopwatch()..start();
    while (!done()) {
      if (watch.elapsed > max) fail('timed out');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test('syncs at launch', () async {
    final container = start();
    await until(() => container.read(syncProvider).lastSyncedAt != null);
    expect(container.read(syncProvider).phase, SyncPhase.idle);
    expect(container.read(syncProvider).pending, 0);
    expect(cloud.rows('user_bookmarks'), hasLength(1));
  });

  test('offline: shows it, keeps the changes, and gets them out before sign-out once online', () async {
    cloud.offline = true;
    final container = start();
    await until(() => container.read(syncProvider).phase == SyncPhase.failed);
    expect(container.read(syncProvider).offline, isTrue);
    expect(container.read(syncProvider).pending, 2);
    expect(await container.read(syncProvider.notifier).flush(), 2);

    cloud.offline = false;
    expect(await container.read(syncProvider.notifier).flush(), 0);
    expect(container.read(syncProvider).phase, SyncPhase.idle);
    expect(cloud.rows('user_settings').single['value'], 'n5');
  });

  test('a change here is pushed a moment later', () async {
    final container = start();
    await until(() => container.read(syncProvider).lastSyncedAt != null);
    await db.setBookmark(7, on: true, label: 'y');
    await until(() => cloud.rows('user_bookmarks').length == 2);
    await until(() => container.read(syncProvider).pending == 0);
  });

  test("another account's data on this phone is never pushed", () async {
    auth = _SignedIn((id: 'user-2', email: 'budi@contoh.id'));
    final container = start();
    expect(await container.read(syncProvider.notifier).flush(), 2);
    expect(cloud.tables, isEmpty);
  });

  test('signed out: sync is off', () async {
    final container = start();
    await until(() => container.read(syncProvider).lastSyncedAt != null);
    await auth.signOut();
    await until(() => container.read(syncProvider).phase == SyncPhase.off);
  });
}
