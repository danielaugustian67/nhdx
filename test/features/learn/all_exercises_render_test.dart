import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/core/database/providers.dart';
import 'package:nihondx/core/svg/svg_path.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/kana/widgets/answer_option.dart';
import 'package:nihondx/features/kana/writing/stroke_scorer.dart';
import 'package:nihondx/features/learn/hangul_path.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/learn/kanji_path.dart';
import 'package:nihondx/features/learn/lesson.dart';
import 'package:nihondx/features/learn/lesson_screen.dart';
import 'package:nihondx/features/learn/path_providers.dart';
import 'package:nihondx/features/learn/vocab_path.dart';
import 'package:nihondx/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

/// Shows every distinct exercise of every course (pipeline output) on a small
/// phone, in either app language: nothing may overflow or throw. A spread of word
/// writing exercises is then written stroke by stroke and must pass.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  const dictPath = 'data_pipeline/output/dictionary.db';
  final available = File(contentPath).existsSync() && File(dictPath).existsSync();
  final skip = !available;

  late ContentDb content;
  late List<Exercise> exercises;

  setUpAll(() async {
    if (!available) return;
    await loadAppFonts();
    content = ContentDb.open(contentPath);
    final dict = DictionaryDb.open(dictPath);
    final words = dict.jlptWords();
    final allKana = content.kana();
    final knownKanji = {for (final k in content.kanji()) k.literal};
    final courses = <(List<PathUnit>, List<DictWord>)>[
      (buildKanaPath(allKana), const []),
      (buildKanjiPath(content.kanji()), const []),
      (buildVocabPath(dict.jlptWords(maxLength: 100), levels: const [5, 4, 3, 2, 1]), const []),
      (
        buildHangulPath(
          content.hangul(),
          content.koreanGroups('hangul'),
          hasStrokes: (k) => content.strokes(k.literal).isNotEmpty,
        ),
        [for (final w in content.koreanWords()) koDictWord(w, 'id')],
      ),
      (buildKoreanVocabPath(content.koreanWords(), content.koreanGroups('words'), language: 'id'), const []),
    ];
    final seen = <String>{};
    exercises = [];
    for (final (units, koWords) in courses) {
      for (final unit in units) {
        for (final node in unit.nodes) {
          if (node.items.isEmpty) continue;
          LessonBuilder lesson() => lessonFor(
            node,
            words: words,
            allKana: allKana,
            koWords: koWords,
            content: content,
            knownKanji: knownKanji,
          );
          final found = switch (node.type) {
            NodeType.intro => [
              for (final item in node.items) ...lesson().practice(item),
              ...lesson().build(LessonMode.quiz),
            ],
            NodeType.write when node.items.first is Kanji => lesson().build(LessonMode.write),
            NodeType.review => lesson().build(LessonMode.mixed, count: 12),
            _ => const <Exercise>[],
          };
          for (final ex in found) {
            if (seen.add(_key(ex))) exercises.add(ex);
          }
        }
      }
    }
    dict.close();
  });

  Future<void> show(WidgetTester tester, Exercise ex, Locale locale, void Function(bool) onAnswer) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [contentProvider.overrideWith((ref) async => content)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ExerciseView(
                    key: ObjectKey(ex),
                    exercise: ex,
                    answered: false,
                    onAnswer: (correct, {required title, detail, word}) => onAnswer(correct),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  void smallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('every exercise fits a small phone', (tester) async {
    smallPhone(tester);
    final problems = <String>[];
    // Alternating languages keeps the run short; both see every kind.
    for (final (i, ex) in exercises.indexed) {
      final locale = i.isEven ? const Locale('id') : const Locale('en');
      await show(tester, ex, locale, (_) {});
      await tester.pump();
      final error = tester.takeException();
      if (error != null) problems.add('${_key(ex)} ($locale): ${error.toString().split('\n').first}');
    }
    expect(exercises.length, greaterThan(1000));
    expect(problems.take(30).toList(), isEmpty, reason: '${problems.length} of ${exercises.length}');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 20)));

  testWidgets('every answered choice fits a small phone, with its romaji', (tester) async {
    smallPhone(tester);
    final problems = <String>[];
    for (final (i, ex) in exercises.whereType<ChoiceExercise>().indexed) {
      final locale = i.isEven ? const Locale('id') : const Locale('en');
      await show(tester, ex, locale, (_) {});
      await tester.pump();
      await tester.tap(find.byType(AnswerOption).first);
      await tester.pump();
      final error = tester.takeException();
      if (error != null) problems.add('${_key(ex)} ($locale): ${error.toString().split('\n').first}');
    }
    expect(problems.take(30).toList(), isEmpty, reason: '${problems.length} overflow');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 20)));

  testWidgets('every word writing exercise can be written', (tester) async {
    smallPhone(tester);
    final all = [
      for (final ex in exercises)
        if (ex is WriteExercise && ex.literal.runes.length > 1) ex,
    ];
    // Every course's words are alike; a spread of 300 covers them.
    final step = (all.length / 300).ceil();
    final words = [for (var i = 0; i < all.length; i += step) all[i]];
    final failed = <String>[];
    for (final ex in words) {
      bool? result;
      await show(tester, ex, const Locale('id'), (correct) => result = correct);
      await tester.pump();
      await tester.pump();
      final chars = ex.literal.runes.map(String.fromCharCode).toList();
      for (final ch in chars) {
        final canvas = tester.getRect(find.byWidgetPredicate((w) => w is GestureDetector && w.onPanStart != null));
        final scale = canvas.width / box;
        for (final path in content.strokes(ch).map(parseSvgPath)) {
          final pts = resamplePath(path, 40);
          final gesture = await tester.startGesture(canvas.topLeft + pts.first * scale);
          for (final p in pts.skip(1)) {
            await gesture.moveTo(canvas.topLeft + p * scale);
          }
          await gesture.up();
          await tester.pump();
        }
        await tester.tap(find.text('Periksa'));
        await tester.pump();
      }
      if (result != true) failed.add('${ex.literal}: ${result ?? 'no verdict'}');
    }
    expect(words.length, greaterThan(100));
    expect(words.any((w) => w.target is VocabWord && (w.target as VocabWord).word.isKorean), isTrue);
    expect(failed.take(30).toList(), isEmpty, reason: '${failed.length} of ${words.length}');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 20)));
}

String _key(Exercise ex) => switch (ex) {
  ChoiceExercise() => 'choice ${ex.kind.name} ${ex.prompt} ${ex.options.length}',
  WriteExercise() => 'write ${ex.literal}',
  BuildExercise() => 'build ${ex.target} ${ex.tiles.length}',
  ReadExercise() => 'read ${ex.shown} ${ex.fromMeaning} ${ex.hint}',
  GlyphReadExercise() => 'glyph ${ex.glyph.literal}',
  MatchExercise() => 'match ${ex.words.length}',
};
