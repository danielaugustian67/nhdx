import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/database/providers.dart';
import 'core/theme/app_text.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_tab_bar.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/kana/kana_screen.dart';
import 'features/onboarding/learning_level.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/progress/me_screen.dart';
import 'features/reminders/reminder_service.dart';
import 'features/search/quick_search.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_providers.dart';
import 'features/sync/sync_controller.dart';
import 'features/today/today_screen.dart';
import 'l10n/app_localizations.dart';

/// Bottom navigation with 5 tabs (ui-design §3.1). First launch opens on
/// "Hari ini"; later launches reopen the last tab (`device.last_tab`).
/// Learning modules open full screen above the tabs.
final _router = GoRouter(
  initialLocation: '/today',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/today', builder: (_, _) => const TodayScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/kana', builder: (_, _) => const KanaScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/dictionary', builder: (_, _) => const SearchScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/collection', builder: (_, _) => const CollectionScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/me', builder: (_, _) => const MeScreen())],
        ),
      ],
    ),
  ],
);

/// Theme, language and text size come from Settings (`device.*`); until
/// user.db answers the defaults apply (dark, phone language, normal size).
class NihondxApp extends ConsumerWidget {
  const NihondxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(appearanceProvider).value ?? defaultAppearance;
    // Keeps "today" on the chosen day start hour.
    ref.watch(dayStartHourProvider);
    final signIn = ref.watch(signInNeededProvider);
    final onboarding = ref.watch(onboardingNeededProvider).value ?? false;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: look.theme.mode,
      locale: look.language.locale,
      builder: (context, child) {
        // First launch: sign in, then onboarding until a level is chosen; each
        // replaces the tabs. Their own navigator hosts pickers and dialogs.
        if (signIn || onboarding) {
          child = Navigator(
            key: ValueKey(signIn),
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => signIn ? const SignInScreen() : const OnboardingScreen()),
          );
        }
        if (look.textSize != TextSize.normal) {
          final media = MediaQuery.of(context);
          final factor = media.textScaler.scale(16) / 16 * look.textSize.factor;
          child = MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(factor)),
            child: child!,
          );
        }
        return SyncScheduler(child: ReminderScheduler(child: child!));
      },
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  static const _lastTabKey = 'device.last_tab';
  static const _dictionaryTab = 2;

  @override
  void initState() {
    super.initState();
    _restoreTab();
  }

  /// Reopens the tab used last (development_plan Fase 2); the first launch
  /// stays on "Hari ini". Skipped if the user already switched tabs.
  Future<void> _restoreTab() async {
    try {
      final db = await ref.read(userDbProvider.future);
      final saved = int.tryParse(await db.setting(_lastTabKey) ?? '');
      if (!mounted || saved == null || saved <= 0 || saved >= 5 || widget.shell.currentIndex != 0) return;
      widget.shell.goBranch(saved);
    } catch (e) {
      debugPrint('last tab not restored: $e');
    }
  }

  void _select(int i) {
    final shell = widget.shell;
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
    writeUserDb(ref.read(userDbProvider.future), (db) => db.setSetting(_lastTabKey, '$i'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shell = widget.shell;
    ref.listen(quickSearchProvider, (_, open) {
      if (open && shell.currentIndex != _dictionaryTab) _select(_dictionaryTab);
    });
    return Scaffold(
      body: PullToSearch(enabled: shell.currentIndex != _dictionaryTab, child: shell),
      // Tab labels stay on one line with large text; screens scale fully.
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: AppTabBar(
          selectedIndex: shell.currentIndex,
          onSelected: _select,
          // TODO(design): replace Material icons with the chosen line icon set (Phosphor).
          tabs: [
            (icon: const Icon(Icons.circle_outlined), selectedIcon: const Icon(Icons.circle), label: l10n.tabToday),
            (icon: const _GlyphIcon('あ'), selectedIcon: null, label: l10n.tabKana),
            (icon: const Icon(Icons.search), selectedIcon: null, label: l10n.tabDictionary),
            (
              icon: const Icon(Icons.bookmark_border),
              selectedIcon: const Icon(Icons.bookmark),
              label: l10n.tabCollection,
            ),
            (icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.tabMe),
          ],
        ),
      ),
    );
  }
}

/// A kana drawn as a tab icon, in the icon color of the navigation bar.
class _GlyphIcon extends StatelessWidget {
  const _GlyphIcon(this.glyph);
  final String glyph;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    return SizedBox.square(
      dimension: icon.size ?? 24,
      child: Center(
        child: Text(
          glyph,
          locale: const Locale('ja'),
          style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 21, height: 1, color: icon.color),
        ),
      ),
    );
  }
}
