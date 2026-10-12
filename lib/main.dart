import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/config/licenses.dart';
import 'features/auth/session_storage.dart';
import 'features/onboarding/learning_level.dart';
import 'features/settings/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  if (Env.hasSupabase) {
    // Restores the saved session without a network call, so the app still
    // opens offline (PRD F4).
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(key: SecureSessionStorage.keyFor(Env.supabaseUrl)),
      ),
    );
  }
  final container = ProviderContainer();
  // Theme, language, day start and whether onboarding is due are read before
  // the first frame, so a light-theme user never sees a dark flash and a new
  // user never sees the tabs flash. Bounded: a slow disk only
  // delays the look, never the launch.
  final watch = Stopwatch()..start();
  // Listened, not just read: Riverpod pauses providers nobody listens to.
  final look = container.listen(appearanceProvider, (_, _) {});
  final dayStart = container.listen(dayStartHourProvider, (_, _) {});
  final onboarding = container.listen(onboardingNeededProvider, (_, _) {});
  try {
    await Future.wait([
      container.read(appearanceProvider.future),
      container.read(dayStartHourProvider.future),
      container.read(onboardingNeededProvider.future),
    ]).timeout(const Duration(milliseconds: 1500));
    debugPrint('settings preloaded in ${watch.elapsedMilliseconds} ms');
  } catch (e) {
    debugPrint('settings not preloaded: $e');
  }
  look.close();
  dayStart.close();
  onboarding.close();
  runApp(UncontrolledProviderScope(container: container, child: const NihondxApp()));
}
