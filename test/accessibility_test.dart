import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/app.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/korean_dict_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/database/user_db.dart';
import 'package:nihondx/core/widgets/app_tab_bar.dart';
import 'package:nihondx/features/learn/study_language.dart';
import 'package:nihondx/features/onboarding/learning_level.dart';

import 'helpers/fonts.dart';

/// Accessibility audit (development plan, Fase 5): on a small phone (360 ×
/// 780 dp) every main tab meets Flutter's tap target (48dp) and label
/// guidelines and lays out without overflow at 200% text. Text contrast is
/// checked on the color tokens (core/theme_contrast_test.dart): the widget
/// guideline estimates colors from anti-aliased pixels and misreports.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  if (!File(contentPath).existsSync()) {
    test('accessibility audit', () {}, skip: 'content.db not built');
    return;
  }

  // Real fonts, so text widths match the phone.
  setUpAll(loadAppFonts);

  const koreanPath = 'data_pipeline/output/korean.db';

  Future<void> pumpApp(
    WidgetTester tester, {
    double textScale = 1,
    bool onboarded = true,
    bool korean = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('id')];
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = UserDb.memory();
    // A chosen level skips onboarding.
    if (onboarded) await tester.runAsync(() => db.setSetting(LearningLevel.settingKey, LearningLevel.n5.value));
    if (korean) await tester.runAsync(() => db.setSetting(StudyLanguage.settingKey, StudyLanguage.ko.name));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDbProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
          koreanDictProvider.overrideWith((ref) async => KoreanDictDb.open(koreanPath)),
        ],
        child: const NihondxApp(),
      ),
    );
    await settle(tester);
  }

  Future<void> openTab(WidgetTester tester, int index) async {
    final bar = find.byType(AppTabBar);
    tester.widget<AppTabBar>(bar).onSelected(index);
    await settle(tester);
  }

  const tabs = ['Hari ini', 'Kana', 'Kamus', 'Koleksi', 'Saya'];

  for (final (i, name) in tabs.indexed) {
    testWidgets('$name meets tap target and label guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester);
      await openTab(tester, i);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
      await unmount(tester);
    });

    testWidgets('$name lays out at 200% text', (tester) async {
      await pumpApp(tester, textScale: 2);
      await openTab(tester, i);
      // An overflow is reported by the framework and fails the test.
      await unmount(tester);
    });
  }
  // The same tabs while Korean is being learned: Hangul course, Korean
  // dictionary, Korean progress.
  const koreanTabs = ['Hari ini', 'Hangul', 'Kamus', 'Koleksi', 'Saya'];
  final koreanSkip = File(koreanPath).existsSync() ? null : 'korean.db not built';

  Future<void> openKoreanWord(WidgetTester tester) async {
    await openTab(tester, 2);
    await tester.enterText(find.byType(TextField), 'sagwa');
    await settle(tester);
    await tester.tap(find.text('사과').first);
    await settle(tester);
    expect(find.text('Arti dari Wiktionary (bahasa Inggris)'), findsOneWidget);
  }

  for (final (i, name) in koreanTabs.indexed) {
    testWidgets('Korean $name meets tap target and label guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, korean: true);
      await openTab(tester, i);
      expect(find.text('Hangul'), findsWidgets);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
      await unmount(tester);
    }, skip: koreanSkip != null);

    testWidgets('Korean $name lays out at 200% text', (tester) async {
      await pumpApp(tester, textScale: 2, korean: true);
      await openTab(tester, i);
      await unmount(tester);
    }, skip: koreanSkip != null);
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('Korean word page at ${scale}x text', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, textScale: scale, korean: true);
      await openKoreanWord(tester);
      if (scale == 1) {
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }
      semantics.dispose();
      await unmount(tester);
    }, skip: koreanSkip != null);
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('Korean grammar and conjugation drill at ${scale}x text', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, textScale: scale, korean: true);
      await openTab(tester, 2);
      Future<void> open(Finder target) async {
        await tester.scrollUntilVisible(target, 300, scrollable: find.byType(Scrollable).first);
        await tester.tap(target);
        await settle(tester);
      }

      Future<void> check() async {
        if (scale == 1) {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }
      }

      await open(find.text('Tata bahasa'));
      expect(find.text('TOPIK I'), findsOneWidget);
      await check();
      await open(find.text('N은/는'));
      await check();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byType(BackButton));
        await settle(tester);
      }

      await open(find.text('Latihan konjugasi'));
      await check();
      await open(find.text('Mulai (10 soal)'));
      expect(find.text('1 / 10'), findsOneWidget);
      await check();
      semantics.dispose();
      await unmount(tester);
    }, skip: koreanSkip != null);
  }

  Future<void> audit(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  Future<void> openFirstLesson(WidgetTester tester) async {
    await openTab(tester, 0);
    // content.db opens in the background.
    for (var i = 0; i < 20 && find.text('Mulai').evaluate().isEmpty; i++) {
      await settle(tester);
    }
    await tester.tap(find.text('Mulai').first);
    await settle(tester);
    await tester.tap(find.text('Mulai').last);
    await settle(tester);
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('onboarding at ${scale}x text', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, textScale: scale, onboarded: false);
      expect(find.text('Lanjut'), findsOneWidget);
      if (scale == 1) await audit(tester);
      semantics.dispose();
      await unmount(tester);
    });

    testWidgets('first lesson at ${scale}x text', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, textScale: scale);
      await openFirstLesson(tester);
      expect(find.byType(AppTabBar), findsNothing, reason: 'the lesson covers the tabs');
      if (scale == 1) await audit(tester);
      semantics.dispose();
      await unmount(tester);
    });
  }
}

/// Lets async loads finish. The current node's "Mulai" tag bounces forever,
/// so pumpAndSettle would never return; advance a fixed time instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    for (var j = 0; j < 4; j++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
}

/// Disposes the app and lets its timers (sync debounce, …) run out.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump(const Duration(minutes: 1));
}
