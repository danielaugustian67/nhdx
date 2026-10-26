import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/kana/kana_screen.dart';
import 'package:nihondx/features/learn/path_providers.dart';
import 'package:nihondx/features/today/today_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

import '../helpers/fonts.dart';

/// Goldens for the dark "Malam Festival" hub and kana module (ui-design §5.2,
/// §5.7), using the real content.db.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  final skip = File(contentPath).existsSync() ? false : 'content.db not built';

  setUpAll(loadAppFonts);

  Widget app(Widget home) => ProviderScope(
    overrides: [
      // Locks as a release build shows them.
      openAllLessonsProvider.overrideWithValue(false),
      contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
      dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
      userDbProvider.overrideWith((ref) async {
        final db = UserDb.memory();
        ref.onDispose(db.close);
        return db;
      }),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
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
    ),
  );

  Future<void> pumpPhone(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(home));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    // The current node's "Mulai" tag bounces forever, so pumpAndSettle would
    // never return; advance a fixed time instead.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Drift closes its query streams on a zero timer; let it run before the
  /// test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('Today hub', (tester) async {
    await pumpPhone(tester, const TodayScreen());
    await expectLater(find.byType(TodayScreen), matchesGoldenFile('goldens/today_dark.png'));
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('Kana screen', (tester) async {
    await pumpPhone(tester, const KanaScreen());
    expect(find.text('あ'), findsWidgets);
    await expectLater(find.byType(KanaScreen), matchesGoldenFile('goldens/kana_dark.png'));
    await unmount(tester);
  }, skip: skip != false);
}
