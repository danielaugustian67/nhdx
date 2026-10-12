import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/study_day.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/progress/me_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

void main() {
  testWidgets('shows streak and goal; changing the goal is saved', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = UserDb.memory();
    final today = todayStudyDate();
    await tester.runAsync(() async {
      await db.addDailyStats(previousDate(today), xp: 20);
      await db.addDailyStats(today, newCount: 3, reviewCount: 4, xp: 35);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDbProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
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
          home: const MeScreen(),
        ),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await settle();
    expect(find.text('Streak 2 hari'), findsOneWidget);
    expect(find.text('13 kartu lagi untuk target hari ini'), findsOneWidget);
    expect(find.text('7/20', findRichText: true), findsOneWidget);

    // The goal comes back from user_settings through its stream, so the new
    // text proves the setting was saved.
    await tester.scrollUntilVisible(find.text('Target harian'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Target harian'));
    await settle();
    await tester.pump(const Duration(milliseconds: 400)); // sheet opens
    await tester.tap(find.text('Santai'));
    await settle();
    await tester.pump(const Duration(milliseconds: 400)); // sheet closes
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await settle();
    expect(find.text('3 kartu lagi untuk target hari ini'), findsOneWidget);
    expect(find.text('7/10', findRichText: true), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
