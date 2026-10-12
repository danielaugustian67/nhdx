import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session in the platform's secure storage (Android
/// Keystore, iOS Keychain) instead of plain shared preferences (PRD F4).
///
/// The session holds the refresh token, so whoever has it is signed in. Its
/// key never leaves the phone's keystore: a backup restored elsewhere cannot
/// be read and simply asks for a sign-in. Signing in once is enough; the
/// token renews itself while the app is online and the saved session keeps
/// the app open offline.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.key, FlutterSecureStorage? storage, LocalStorage? legacy})
    : _storage = storage ?? const FlutterSecureStorage(),
      _legacy = legacy ?? SharedPreferencesLocalStorage(persistSessionKey: key);

  final String key;
  final FlutterSecureStorage _storage;

  /// Where earlier builds kept the session; moved over once.
  final LocalStorage _legacy;

  /// The key supabase_flutter uses for a project URL.
  static String keyFor(String url) => 'sb-${Uri.parse(url).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    try {
      await _legacy.initialize();
      final old = await _legacy.accessToken();
      if (old == null) return;
      if (!await _storage.containsKey(key: key)) await _storage.write(key: key, value: old);
      await _legacy.removePersistedSession();
    } catch (e) {
      // Not moved: the user signs in again, nothing else is lost.
      debugPrint('session not moved to secure storage: $e');
    }
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: key);

  @override
  Future<String?> accessToken() => _storage.read(key: key);

  @override
  Future<void> persistSession(String persistSessionString) => _storage.write(key: key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: key);
}
