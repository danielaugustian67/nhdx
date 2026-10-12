/// Build-time configuration (PRD §6.1). Passed per environment with
/// `flutter run --dart-define-from-file=env/dev.json` (see env/example.json).
///
/// Only the publishable key ships in the app; it is safe to expose because
/// every table is protected by RLS. Never put a service_role/secret key here.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// False in unit tests and builds without an env file: the app then runs
  /// fully offline (dictionary, study) and skips auth/sync.
  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
