import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/study_day.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/progress/me_screen.dart';
import 'package:nihondx/features/today/today_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

void main() {
  const contentPath = 'data_pipeline/output/content.db';
  final skip = File(contentPath).existsSync() ? false : 'content.db not built';

  testWidgets('the top bar shows the streak and XP; tapping opens the streak card', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = UserDb.memory();
    final today = todayStudyDate();
    await tester.runAsync(() async {
      await db.addDailyStats(addDays(today, -2), xp: 20, newCount: 1);
      await db.addDailyStats(addDays(today, -1), xp: 30, newCount: 1);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
          userDbProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
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
          home: const TodayScreen(),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    // The current node's tag bounces forever: no pumpAndSettle.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final chip = find.bySemanticsLabel('Streak 2 hari, 50 XP');
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(GoalCard), findsOneWidget);
    expect(find.text('Streak 2 hari'), findsOneWidget);
    expect(find.text('Belajar hari ini agar streak berlanjut.'), findsOneWidget);
    expect(find.text('Total 50 XP'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }, skip: skip != false);
}
