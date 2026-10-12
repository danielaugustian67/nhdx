import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/study_day.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/reminders/reminder_plan.dart';
import 'package:nihondx/features/reminders/reminder_service.dart';
import 'package:nihondx/features/settings/settings_section.dart';
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
}

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  const time = ReminderTime(19, 0);
  ReminderContext ctx({bool active = false, bool goal = false, int streak = 0, int due = 0}) =>
      (today: '2026-10-11', activeToday: active, goalReached: goal, streak: streak, dueCards: due);

  test('reminder time parses HH:mm and treats anything else as off', () {
    expect(ReminderTime.parse('07:30'), const ReminderTime(7, 30));
    expect(const ReminderTime(7, 5).value, '07:05');
    expect(ReminderTime.parse('off'), isNull);
    expect(ReminderTime.parse(null), isNull);
    expect(ReminderTime.parse('25:00'), isNull);
  });

  test('a week of reminders, today worded from today', () {
    final plan = planReminders(now: DateTime(2026, 10, 11, 10), time: time, context: ctx(due: 12), l10n: en);
    expect(plan, hasLength(7));
    expect(plan.first.at, DateTime(2026, 10, 11, 19));
    expect(plan.first.body, '12 cards are waiting. About 6 min.');
    expect(plan[1].at, DateTime(2026, 10, 12, 19));
    expect(plan[1].body, en.reminderPlain);
    expect(plan.last.at, DateTime(2026, 10, 17, 19));
  });

  test('a streak not yet kept today comes first in the wording', () {
    final plan = planReminders(now: DateTime(2026, 10, 11, 10), time: time, context: ctx(streak: 5, due: 3), l10n: en);
    expect(plan.first.body, contains('5-day streak'));
    // Already studied today: the cards, not the streak.
    final studied = planReminders(
      now: DateTime(2026, 10, 11, 10),
      time: time,
      context: ctx(active: true, streak: 5, due: 1),
      l10n: en,
    );
    expect(studied.first.body, '1 card is waiting. About 1 min.');
  });

  test("today's reminder is skipped once the goal is reached or its time passed", () {
    final done = planReminders(now: DateTime(2026, 10, 11, 10), time: time, context: ctx(goal: true), l10n: en);
    expect(done.first.at, DateTime(2026, 10, 12, 19));
    expect(done, hasLength(7));
    final late = planReminders(now: DateTime(2026, 10, 11, 20), time: time, context: ctx(due: 4), l10n: en);
    expect(late.first.at, DateTime(2026, 10, 12, 19));
    expect(late.first.body, en.reminderPlain);
  });

  test('a reminder after midnight but before the day start belongs to today', () {
    addTearDown(() => setDayStartHour(defaultDayStartHour));
    setDayStartHour(4);
    final plan = planReminders(
      now: DateTime(2026, 10, 11, 23),
      time: const ReminderTime(2, 0),
      context: ctx(goal: true),
      l10n: en,
    );
    // 12 Oct 02:00 is still study day 11 Oct, already done.
    expect(plan.first.at, DateTime(2026, 10, 13, 2));
  });

  test('the context counts new cards only up to the daily new limit', () async {
    final db = UserDb.memory();
    addTearDown(db.close);
    expect(await loadReminderContext(db), (
      today: todayStudyDate(),
      activeToday: false,
      goalReached: false,
      streak: 0,
      dueCards: 0,
    ));
    for (var i = 0; i < 12; i++) {
      await db.addCard('vocab', '$i', label: 'w$i');
    }
    await db.setSetting('new_per_day', '5');
    expect((await loadReminderContext(db)).dueCards, 5);
  });

  Future<UserDb> pumpSettings(WidgetTester tester, ReminderService service) async {
    tester.view.physicalSize = const Size(390, 2000);
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
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('id'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SingleChildScrollView(child: SettingsSection())),
        ),
      ),
    );
    await settle(tester);
    return db;
  }

  testWidgets('switching the reminder on asks permission and saves 19.00', (tester) async {
    final service = _FakeReminders(granted: true);
    final db = await pumpSettings(tester, service);
    expect(find.text('Jam pengingat'), findsNothing);

    await tester.tap(find.text('Pengingat harian'));
    await settle(tester);
    expect(service.asked, 1);
    expect(find.text('19.00'), findsOneWidget);
    expect(await tester.runAsync(() => db.setting(ReminderTime.settingKey)), '19:00');

    await tester.tap(find.text('Pengingat harian'));
    await settle(tester);
    expect(find.text('Jam pengingat'), findsNothing);
    expect(await tester.runAsync(() => db.setting(ReminderTime.settingKey)), 'off');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('a refused permission leaves the reminder off', (tester) async {
    final service = _FakeReminders(granted: false);
    final db = await pumpSettings(tester, service);

    await tester.tap(find.text('Pengingat harian'));
    await settle(tester);
    expect(find.text('Buka pengaturan'), findsOneWidget);
    expect(find.text('Jam pengingat'), findsNothing);
    expect(await tester.runAsync(() => db.setting(ReminderTime.settingKey)), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}
