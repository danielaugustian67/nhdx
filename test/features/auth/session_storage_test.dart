import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/features/auth/session_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Prefs extends LocalStorage {
  _Prefs([this.value]);
  String? value;

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => value != null;
  @override
  Future<String?> accessToken() async => value;
  @override
  Future<void> persistSession(String persistSessionString) async => value = persistSessionString;
  @override
  Future<void> removePersistedSession() async => value = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'sb-abc-auth-token';

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('the key matches the one supabase_flutter uses', () {
    expect(SecureSessionStorage.keyFor('https://abc.supabase.co'), key);
  });

  test('a session saved by an earlier build moves over, so nobody signs in again', () async {
    final prefs = _Prefs('{"session":1}');
    final storage = SecureSessionStorage(key: key, legacy: prefs);
    await storage.initialize();
    expect(await storage.accessToken(), '{"session":1}');
    expect(prefs.value, isNull, reason: 'no plain copy is left behind');

    await storage.initialize();
    expect(await storage.accessToken(), '{"session":1}');
  });

  test('saves, reads and forgets the session', () async {
    final storage = SecureSessionStorage(key: key, legacy: _Prefs());
    await storage.initialize();
    expect(await storage.hasAccessToken(), isFalse);

    await storage.persistSession('{"session":2}');
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), '{"session":2}');

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });
}
