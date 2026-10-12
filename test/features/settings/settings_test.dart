import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/study_day.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/core/theme/theme_palette.dart';
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

  testWidgets('one theme sheet sets mode, palette, custom accent and pure black', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
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
        ],
        child: MaterialApp(
          // The app's button themes: the sheet once overflowed with them.
          theme: AppTheme.dark(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SingleChildScrollView(child: SettingsSection())),
        ),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await settle();
    }

    Future<String?> setting(String key) async => await tester.runAsync<String?>(() => db.setting(key));

    await settle();
    // Colours live under "Tema"; there is no second row for them.
    expect(find.text('Gelap · Sakura Yoru'), findsOneWidget);
    expect(find.textContaining('Nuansa'), findsNothing);
    await tap(find.text('Tema'));
    expect(find.text('Pratinjau'), findsOneWidget);

    await tap(find.text('Terang'));
    expect(await setting(ThemeChoice.settingKey), 'light');
    await tap(find.text('Matcha Zen'));
    expect(await setting(ThemePalette.settingKey), 'matcha');
    expect(find.text('Warna aksen'), findsNothing);

    await tap(find.text('Kustom'));
    expect(await setting(ThemePalette.settingKey), 'custom');
    expect(await setting(ThemePalette.customColorKey), '${0xFFC2406F}');
    await tap(find.bySemanticsLabel('#2563EB'));
    expect(await setting(ThemePalette.customColorKey), '${0xFF2563EB}');

    await tap(find.textContaining('Kode hex'));
    await tester.enterText(find.byType(TextField), '12z');
    await tester.pump();
    await tap(find.text('Terapkan'));
    expect(find.text('Pakai 6 karakter 0–9 atau A–F'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '3b82f6');
    await tap(find.text('Terapkan'));
    expect(await setting(ThemePalette.customColorKey), '${0xFF3B82F6}');

    await tap(find.text('Hitam pekat (AMOLED)'));
    expect(await setting(ThemePalette.pureBlackKey), 'true');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
