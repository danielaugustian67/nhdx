import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/learn/kanji_path.dart';
import 'package:nihondx/features/learn/lesson.dart';

void main() {
  const contentPath = 'data_pipeline/output/content.db';
  const dictPath = 'data_pipeline/output/dictionary.db';
  final skip = File(contentPath).existsSync() && File(dictPath).existsSync() ? false : 'databases not built';

  late List<Kanji> course;
  late List<Kana> hiragana;
  late List<PathUnit> units;
  late List<DictWord> words;
  late ContentDb content;

  setUpAll(() {
    if (skip != false) return;
    content = ContentDb.open(contentPath);
    course = content.kanji();
    hiragana = content.kana().where((k) => k.script == 'hiragana').toList();
    units = buildKanjiPath(course);
    final dict = DictionaryDb.open(dictPath);
    words = dict.jlptWords();
    dict.close();
  });

  tearDownAll(() {
    if (skip == false) content.close();
  });

  KanjiLessonBuilder builder(PathNode node, {int seed = 1}) => KanjiLessonBuilder(
    focus: node.items.cast<Kanji>(),
    pool: node.reviewPool.cast<Kanji>(),
    hiragana: hiragana,
    dictionary: words,
    random: Random(seed),
  );

  group('course data', () {
    test('N5 to N1, easiest first, with meanings, readings and strokes', () {
      expect(
        [
          for (final n in [5, 4, 3, 2, 1]) course.where((k) => k.jlpt == n).length,
        ],
        [103, 181, 370, 369, 1207],
      );
      final levels = course.map((k) => k.jlpt).toList();
      expect(levels, [...levels]..sort((a, b) => b - a));
      // Unit 1 is the numbers theme, in counting order.
      expect(course.take(5).map((k) => k.literal), ['一', '二', '三', '四', '五']);
      for (final k in course) {
        expect(k.meanings, isNotEmpty, reason: k.literal);
        expect(k.onyomi.isNotEmpty || k.kunyomi.isNotEmpty, isTrue, reason: k.literal);
        expect(content.strokes(k.literal), hasLength(k.strokeCount), reason: k.literal);
      }
    });
  }, skip: skip);

  group('path', () {
    test('every kanji introduced once, in course order', () {
      final introduced = [
        for (final u in units)
          for (final n in u.nodes.where((n) => n.type == NodeType.intro)) ...n.items,
      ];
      expect(introduced, course);
    });

    test('N5 and N4: one unit per theme; N3 to N1: units of up to 15; each within one level', () {
      final themed = units.where((u) => u.theme != null).toList();
      expect(themed.map((u) => u.theme).toSet(), hasLength(themed.length));
      expect(units.first.theme, 'numbers');
      expect(units.where((u) => u.jlpt == 5), hasLength(11));
      expect(units.where((u) => u.jlpt == 4), hasLength(18));
      expect(themed.every((u) => u.jlpt! >= 4), isTrue);
      expect(
        [
          for (final n in [3, 2, 1]) units.where((u) => u.jlpt == n).length,
        ],
        [25, 25, 81],
      );
      // The levels follow each other, easiest first.
      final levels = [for (final u in units) u.jlpt!];
      expect(levels, [...levels]..sort((a, b) => b - a));
      for (final u in units) {
        expect(u.introduced.every((k) => (k as Kanji).jlpt == u.jlpt), isTrue, reason: u.id);
        expect(u.introduced.every((k) => (k as Kanji).theme == (u.theme ?? '')), isTrue, reason: u.id);
        if (u.theme == null) expect(u.introduced.length, lessThanOrEqualTo(kanjiPerUnit), reason: u.id);
        expect(u.nodes.last.type, NodeType.review);
        // Lessons of 3–5 kanji, split evenly.
        final sizes = [for (final n in u.nodes.where((n) => n.type == NodeType.intro)) n.items.length];
        expect(sizes.every((s) => s >= 3 && s <= kanjiPerIntro), isTrue, reason: '${u.id}: $sizes');
        expect(sizes.reduce(max) - sizes.reduce(min), lessThanOrEqualTo(1), reason: '${u.id}: $sizes');
      }
      expect(units.first.nodes.first.items.map((k) => k.literal), ['一', '二', '三', '四', '五']);
      final ids = [for (final u in units) ...u.nodes.map((n) => n.id)];
      expect(ids.toSet(), hasLength(ids.length));
    });
  }, skip: skip);

  group('lessons', () {
    test('first lesson already has words such as 一つ and 二つ', () {
      final b = builder(units.first.nodes.first);
      final spelled = b.words.map((w) => w.word.kanji).toSet();
      expect(spelled, containsAll(['一つ', '二つ']));
      for (final w in b.words) {
        expect(w.glyphs.map((g) => g.literal).join(), w.word.kanji);
      }
    });

    test('words only use kanji learned so far', () {
      for (final u in units) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) {
          final pool = n.reviewPool.toSet();
          for (final w in builder(n).words) {
            expect(w.glyphs.whereType<Kanji>().every(pool.contains), isTrue, reason: '${n.id}: ${w.word.kanji}');
          }
        }
      }
    });

    test('choices alternate meaning and kanji with 4 distinct options', () {
      for (final u in units) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) {
          final qs = builder(n).build(LessonMode.choice).cast<ChoiceExercise>();
          expect(qs.map((q) => q.kind).toSet(), {ChoiceKind.kanjiMeaning, ChoiceKind.pickKanji});
          for (final q in qs) {
            expect(q.options.toSet(), hasLength(4), reason: '${n.id}: ${q.prompt}');
            final k = q.item as Kanji;
            expect(q.answer, q.kind == ChoiceKind.kanjiMeaning ? k.meaning : k.literal);
          }
        }
      }
    });

    test('every intro and review node builds a full mixed lesson', () {
      for (final u in units) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro || n.type == NodeType.review)) {
          final ex = builder(n).build(LessonMode.mixed, count: 12);
          expect(ex, hasLength(12), reason: n.id);
          expect(ex.whereType<WriteExercise>(), isNotEmpty, reason: n.id);
        }
      }
    });

    test('kanji spelling: answer tiles, kana prompt, only kanji count as practised', () {
      final b = builder(units.first.nodes.first);
      final ex = b.build(LessonMode.type).whereType<BuildExercise>().first;
      expect(ex.script, 'kanji');
      expect(ex.prompt, ex.word.kana);
      expect(ex.check(ex.answer), isTrue);
      expect(ex.items.every((g) => g is Kanji), isTrue);
      expect(ex.tiles.toSet().containsAll(ex.answer), isTrue);

      final read = b.readWord(b.words.firstWhere((w) => w.word.kanji == '二'));
      expect(read.shown, '二');
      expect(read.hint, isNotEmpty);
      expect(read.check(read.word.romaji), isTrue);
    });
  }, skip: skip);
}
