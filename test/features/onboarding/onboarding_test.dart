import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/widgets/app_tab_bar.dart';
import 'package:nihondx/app.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/learn/path_providers.dart';
import 'package:nihondx/features/onboarding/learning_level.dart';
import 'package:nihondx/features/onboarding/onboarding_screen.dart';
import 'package:nihondx/features/progress/progress_providers.dart';
import 'package:nihondx/features/reminders/reminder_plan.dart';
import 'package:nihondx/features/reminders/reminder_service.dart';
import 'package:nihondx/l10n/app_localizations.dart';

class _FakeReminders extends ReminderService {
  _FakeReminders({required this.granted});
  final bool granted;
  int asked = 0;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return granted;
  }

  @override
  Future<void> refresh(Future<UserDb> db, Locale locale) async {}
}

void main() {
  test('the self-check maps to Pra-N5, N5 or N4', () {
    expect(selfCheckLevel(hiragana: false, katakana: true, basicWords: true), LearningLevel.preN5);
    expect(selfCheckLevel(hiragana: true, katakana: false, basicWords: false), LearningLevel.preN5);
    expect(selfCheckLevel(hiragana: true, katakana: true, basicWords: false), LearningLevel.n5);
    expect(selfCheckLevel(hiragana: true, katakana: true, basicWords: true), LearningLevel.n4);
  });

  test('levels pick the course and where the word path starts', () {
    expect(LearningLevel.parse('n4'), LearningLevel.n4);
    expect(LearningLevel.parse('n9'), isNull);
    expect(LearningLevel.preN5.track, LearnTrack.kana);
    expect(LearningLevel.preN5.vocabLevels, [5, 4, 3, 2, 1]);
    expect(LearningLevel.n4.vocabLevels, [4, 3, 2, 1]);
    expect(LearningLevel.n3.vocabLevels, [3, 2, 1]);
    expect(LearningLevel.n1.vocabLevels, [1]);
  });

  test('onboarding is due only without a level and without learning data', () async {
    final db = UserDb.memory();
    final container = ProviderContainer(overrides: [userDbProvider.overrideWith((ref) async => db)]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final sub = container.listen(onboardingNeededProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(onboardingNeededProvider.future), isTrue);

    // Someone who already studied before onboarding existed skips it.
    await db.addCard('vocab', '1', label: 'w');
    container.invalidate(onboardingNeededProvider);
    expect(await container.read(onboardingNeededProvider.future), isFalse);
  });

  Future<UserDb> pump(WidgetTester tester, ReminderService service, Widget home) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = UserDb.memory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDbProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
          reminderServiceProvider.overrideWithValue(service),
        ],
        child: home,
      ),
    );
    await settle(tester);
    return db;
  }

  Widget app(Widget home) => MaterialApp(
    theme: AppTheme.dark(),
    locale: const Locale('id'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('"Belum tahu" suggests a level; goal and a skipped reminder are saved', (tester) async {
    final service = _FakeReminders(granted: true);
    final db = await pump(tester, service, app(const OnboardingScreen()));
    final next = find.text('Lanjut');

    expect(find.text('Kamu di level mana?'), findsOneWidget);
    await tester.tap(next);
    await settle(tester);
    expect(find.text('Kamu di level mana?'), findsOneWidget, reason: 'nothing chosen yet');

    await tester.tap(find.text('Belum tahu'));
    await settle(tester);
    await tester.tap(find.text('Ya').at(0));
    await tester.tap(find.text('Ya').at(1));
    await tester.tap(find.text('Tidak').at(2));
    await settle(tester);
    expect(find.textContaining('Pemula · N5'), findsOneWidget);

    await tester.tap(next);
    await settle(tester);
    expect(find.text('Berapa lama belajar setiap hari?'), findsOneWidget);
    await tester.tap(find.text('Serius'));
    await tester.tap(next);
    await settle(tester);

    expect(find.text('Mau diingatkan setiap hari?'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await settle(tester);
    expect(service.asked, 0);
    expect(await tester.runAsync(() => db.setting(DailyGoal.settingKey)), '40');
    expect(await tester.runAsync(() => db.setting('new_per_day')), '20', reason: 'new cards follow the goal');
    expect(await tester.runAsync(() => db.setting(ReminderTime.settingKey)), 'off');
    expect(await tester.runAsync(() => db.setting(LearningLevel.settingKey)), 'n5');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('a new install sees onboarding, then the tabs', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('id')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final service = _FakeReminders(granted: true);
    final db = await pump(tester, service, const NihondxApp());
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AppTabBar), findsNothing);

    await tester.tap(find.text('Baru mulai dari nol'));
    await tester.pump();
    await tester.tap(find.text('Lanjut'));
    await settle(tester);
    await tester.tap(find.text('Lanjut'));
    await settle(tester);
    await tester.tap(find.text('Ingatkan saya'));
    await settle(tester);
    await settle(tester);

    expect(service.asked, 1);
    expect(await tester.runAsync(() => db.setting(ReminderTime.settingKey)), '19:00');
    expect(await tester.runAsync(() => db.setting(DailyGoal.settingKey)), '20');
    expect(await tester.runAsync(() => db.setting(LearningLevel.settingKey)), 'pre_n5');
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppTabBar), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
