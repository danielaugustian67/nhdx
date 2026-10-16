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
import 'package:nihondx/features/learn/lesson_intro_screen.dart';
import 'package:nihondx/features/kana/games/writing_screen.dart';
import 'package:nihondx/features/learn/lesson_screen.dart';
import 'package:nihondx/features/today/today_screen.dart';
import 'package:nihondx/l10n/app_localizations.dart';

/// A "Kenali …" lesson starts with the intro cards and practice; replaying a
/// finished one also offers a shortcut to the quiz.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  final skip = File(contentPath).existsSync() ? false : 'content.db not built';

  Future<void> pumpToday(WidgetTester tester, {required Set<String> done}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => ContentDb.open(contentPath)),
          dictionaryProvider.overrideWith((ref) => Completer<Never>().future),
          userDbProvider.overrideWith((ref) async {
            final db = UserDb.memory();
            ref.onDispose(db.close);
            for (final id in done) {
              await db.completeLesson(id);
            }
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
    // The current node's "Mulai" tag bounces forever; advance a fixed time.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Opens the bubble of the node labelled [node] and taps [button].
  Future<void> startLesson(WidgetTester tester, Pattern node, String button) async {
    await tester.tap(find.bySemanticsLabel(node).first);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.text(button));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Opens the first hiragana lesson's bubble and taps its main button.
  Future<void> startFirstLesson(WidgetTester tester, String button) =>
      startLesson(tester, RegExp(r'^Kenali あ'), button);

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('a new lesson starts with the intro cards', (tester) async {
    await pumpToday(tester, done: const {});
    await startFirstLesson(tester, 'Mulai');

    expect(find.byType(LessonIntroScreen), findsOneWidget);
    expect(find.textContaining('· Kenali'), findsOneWidget);
    expect(find.text('Langsung ke quiz'), findsNothing);
    await unmount(tester);
  }, skip: skip != false);

  testWidgets('replaying a finished lesson can go straight to the quiz', (tester) async {
    await pumpToday(tester, done: const {'hiragana-u1-intro-0'});
    await startFirstLesson(tester, 'Ulangi');

    expect(find.byType(LessonIntroScreen), findsOneWidget);
    await tester.tap(find.text('Langsung ke quiz'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(LessonScreen), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);

  // Nodes zigzag sideways; the third one sits furthest out and used to
  // ignore taps.
  testWidgets('the third node of a unit can be started', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    await pumpToday(tester, done: const {'hiragana-u1-intro-0', 'hiragana-u1-intro-1'});
    await startLesson(tester, RegExp('^Tulis huruf unit ini'), 'Mulai');

    expect(find.byType(WritingScreen), findsOneWidget);
    await unmount(tester);
  }, skip: skip != false);
}
