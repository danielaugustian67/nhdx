import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/features/learn/hangul_path.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/learn/kanji_path.dart';
import 'package:nihondx/features/learn/lesson.dart';
import 'package:nihondx/features/learn/path_providers.dart';
import 'package:nihondx/features/learn/vocab_path.dart';

/// Builds every lesson of every course from the pipeline output
/// (`python data_pipeline/build_all.py`) and checks each exercise.
void main() {
  const contentPath = 'data_pipeline/output/content.db';
  const dictPath = 'data_pipeline/output/dictionary.db';
  final available = File(contentPath).existsSync() && File(dictPath).existsSync();
  final skip = available ? false : 'content.db or dictionary.db not built';

  late ContentDb content;
  late DictionaryDb dict;
  setUpAll(() {
    if (!available) return;
    content = ContentDb.open(contentPath);
    dict = DictionaryDb.open(dictPath);
  });

  void checkAll(List<PathUnit> units, {List<DictWord> words = const [], List<DictWord> koWords = const []}) {
    final allKana = content.kana();
    final allKanji = {for (final k in content.kanji()) k.literal};
    final problems = <String>[];
    var count = 0;
    for (final unit in units) {
      for (final node in unit.nodes) {
        if (node.items.isEmpty) continue;
        for (final known in [<String>{}, allKanji]) {
          LessonBuilder lesson() => lessonFor(
            node,
            words: words,
            allKana: allKana,
            koWords: koWords,
            content: content,
            knownKanji: known,
          );
          final exercises = <Exercise>[];
          try {
            switch (node.type) {
              case NodeType.intro:
                final l = lesson();
                for (final item in node.items) {
                  exercises.addAll(l.practice(item));
                }
                exercises.addAll(lesson().build(LessonMode.quiz));
              case NodeType.write:
                if (node.items.first is Kanji) {
                  exercises.addAll(lesson().build(LessonMode.write));
                } else {
                  for (final k in node.kana) {
                    if (content.strokes(k.literal).isEmpty) problems.add('${node.id}: ${k.literal} has no strokes');
                  }
                }
              case NodeType.review:
                exercises.addAll(lesson().build(LessonMode.mixed, count: 12));
              default:
                continue;
            }
          } catch (e, s) {
            problems.add('${node.id}: $e\n$s');
            continue;
          }
          if ((node.type == NodeType.intro || node.type == NodeType.review) && exercises.isEmpty) {
            problems.add('${node.id}: no exercises');
          }
          for (final ex in exercises) {
            count++;
            final p = _problem(ex, content);
            if (p != null) problems.add('${node.id}: $p');
          }
        }
      }
    }
    expect(count, greaterThan(0));
    expect(problems.toSet().take(30).toList(), isEmpty, reason: '${problems.toSet().length} problems');
  }

  test('kana', () => checkAll(buildKanaPath(content.kana()), words: dict.jlptWords()), skip: skip);
  test('kanji', () => checkAll(buildKanjiPath(content.kanji()), words: dict.jlptWords()), skip: skip);
  test(
    'japanese vocabulary N5 to N1',
    () => checkAll(buildVocabPath(dict.jlptWords(maxLength: 100), levels: const [5, 4, 3, 2, 1])),
    skip: skip,
  );
  for (final language in ['en', 'id']) {
    test('hangul ($language)', () {
      final ko = [for (final w in content.koreanWords()) koDictWord(w, language)];
      final letters = content.hangul();
      final units = buildHangulPath(
        letters,
        content.koreanGroups('hangul'),
        hasStrokes: (k) => content.strokes(k.literal).isNotEmpty,
      );
      checkAll(units, koWords: ko);
    }, skip: skip);
    test('korean vocabulary ($language)', () {
      final units = buildKoreanVocabPath(content.koreanWords(), content.koreanGroups('words'), language: language);
      checkAll(units);
    }, skip: skip);
  }
}

String? _problem(Exercise ex, ContentDb content) {
  switch (ex) {
    case ChoiceExercise():
      if (ex.options.length < 2) return 'choice "${ex.prompt}" has ${ex.options.length} options';
      if (ex.answerIndex < 0 || ex.answerIndex >= ex.options.length) return 'choice "${ex.prompt}" answer out of range';
      if (ex.options.toSet().length != ex.options.length) return 'choice "${ex.prompt}" repeats an option: ${ex.options}';
      if (ex.options.any((o) => o.trim().isEmpty)) return 'choice "${ex.prompt}" has an empty option';
      if (ex.prompt.trim().isEmpty) return 'choice with empty prompt';
    case WriteExercise():
      final chars = ex.literal.runes.map(String.fromCharCode).toList();
      if (chars.isEmpty) return 'write with nothing to write';
      for (final c in chars) {
        if (content.strokes(c).isEmpty) return 'write "${ex.literal}": $c has no strokes';
      }
    case BuildExercise():
      if (ex.answer.isEmpty) return 'build "${ex.target}" with no answer';
      if (!ex.answer.every(ex.tiles.contains)) return 'build "${ex.target}" lacks a tile';
    case ReadExercise():
      if (ex.shown.trim().isEmpty) return 'read with nothing shown';
      if (ex.word.romaji.trim().isEmpty && !ex.word.isKorean) return 'read "${ex.shown}" with no romaji';
    case GlyphReadExercise():
      if (ex.answers.isEmpty || ex.answers.any((a) => a.trim().isEmpty)) {
        return 'read ${ex.glyph.literal} with answers ${ex.answers}';
      }
    case MatchExercise():
      break;
  }
  return null;
}
