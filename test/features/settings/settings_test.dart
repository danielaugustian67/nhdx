import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/study_day.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/settings/settings_providers.dart';
import 'package:nihondx/features/settings/settings_section.dart';
import 'package:nihondx/features/srs/srs_providers.dart';
import 'package:nihondx/l10n/app_localizations.dart';

void main() {
  group('day start hour', () {
    tearDown(() => setDayStartHour(defaultDayStartHour));

    test('studying before the hour counts for the day before', () {
      final early = DateTime(2026, 10, 11, 3, 30);
      expect(studyDate(early), '2026-10-10');
      setDayStartHour(0);
      expect(studyDate(early), '2026-10-11');
      setDayStartHour(6);
      expect(studyDate(DateTime(2026, 10, 11, 5, 59)), '2026-10-10');
    });

    test('hours outside the choices fall back to the default', () {
      setDayStartHour(13);
      expect(dayStartHour, defaultDayStartHour);
    });
  });

  test('appearance values parse with safe defaults', () {
    expect(ThemeChoice.parse(null), ThemeChoice.dark);
    expect(ThemeChoice.parse('light').mode, ThemeMode.light);
    expect(LanguageChoice.parse('en').locale, const Locale('en'));
    expect(LanguageChoice.parse('xx'), LanguageChoice.system);
    expect(TextSize.parse('larger').factor, greaterThan(1));
  });

  testWidgets('a choice in the sheet is saved and shown on the row', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => setDayStartHour(defaultDayStartHour));
    final db = UserDb.memory();

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
          home: const Scaffold(body: SingleChildScrollView(child: SettingsSection())),
        ),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('10 kartu'), findsOneWidget); // new cards per day
    expect(find.text('04.00'), findsOneWidget);

    await tester.tap(find.text('Kartu baru per hari'));
    await settle();
    await tester.tap(find.text('20 kartu'));
    await settle();
    expect(find.text('20 kartu'), findsOneWidget);
    expect((await tester.runAsync(() => SrsLimits.load(db)))!.newPerDay, 20);

    await tester.tap(find.text('Hari baru dimulai'));
    await settle();
    await tester.tap(find.text('02.00'));
    await settle();
    expect(find.text('02.00'), findsOneWidget);
    expect(dayStartHour, 2);

    await tester.tap(find.text('Tema'));
    await settle();
    await tester.tap(find.text('Terang'));
    await settle();
    expect(await tester.runAsync(() => db.setting(ThemeChoice.settingKey)), 'light');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
