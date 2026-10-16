import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/learn/lesson.dart';

void main() {
  const contentPath = 'data_pipeline/output/content.db';
  const dictPath = 'data_pipeline/output/dictionary.db';
  final skip = File(contentPath).existsSync() && File(dictPath).existsSync() ? false : 'databases not built';

  late List<Kana> all;
  late List<PathUnit> units;
  late List<DictWord> words;

  setUpAll(() {
    if (skip != false) return;
    final content = ContentDb.open(contentPath);
    all = content.kana();
    content.close();
    units = buildKanaPath(all);
    final dict = DictionaryDb.open(dictPath);
    words = dict.jlptWords();
    dict.close();
  });

  LessonBuilder builder(PathNode node, {List<DictWord>? dictionary, int seed = 1}) => KanaLessonBuilder(
    focus: node.kana,
    pool: node.reviewPool.cast<Kana>(),
    dictionary: dictionary ?? words,
    random: Random(seed),
  );

  group('dictionary words', () {
    test('unit 1 (あ, か rows) already has N5 words like あか and いえ', () {
      final b = builder(units[0].nodes[1]); // ka-row intro, pool a+ka
      final spelled = b.words.map((w) => w.word.kana).toSet();
      expect(spelled, containsAll(['あか', 'いえ', 'えき', 'こえ']));
      expect(b.words.first.word.jlpt, 5);
    });

    test('only kana learned so far are used', () {
      for (final u in units) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) {
          final pool = n.reviewPool.toSet();
          for (final w in builder(n).words) {
            expect(pool.containsAll(w.glyphs), isTrue, reason: '${n.id}: ${w.word.kana}');
            expect(w.glyphs.map((k) => k.literal).join(), w.word.kana);
          }
        }
      }
    });

    test('words with the new kana come first', () {
      final node = units[0].nodes[1]; // introduces か row
      final first = builder(node).words.first;
      expect(first.glyphs.any(node.kana.contains), isTrue);
    });

    test('yōon spell as one tile', () {
      final yoon = all.where((k) => k.script == 'hiragana').toList();
      final byLiteral = {for (final k in yoon) k.literal: k};
      expect(spellWith('しゃしん', byLiteral)!.map((k) => k.literal), ['しゃ', 'し', 'ん']);
      expect(spellWith('きって', byLiteral), isNull); // っ is not taught as a kana
    });
  });

  group('modes', () {
    test('mixed lesson has every exercise type, warm-up choices first', () {
      final ex = builder(units[0].nodes[1]).build(LessonMode.mixed, count: 10);
      expect(ex, hasLength(10));
      expect(ex.take(2).every((e) => e is ChoiceExercise), isTrue);
      expect(ex.whereType<WriteExercise>(), isNotEmpty);
      expect(ex.whereType<BuildExercise>(), isNotEmpty);
      expect(ex.whereType<ReadExercise>(), isNotEmpty);
    });

    test('single-type modes only contain that type', () {
      final b = builder(units[0].nodes[1]);
      expect(b.build(LessonMode.choice).every((e) => e is ChoiceExercise), isTrue);
      expect(b.build(LessonMode.write).every((e) => e is WriteExercise), isTrue);
      expect(b.build(LessonMode.type).every((e) => e is BuildExercise || e is ReadExercise), isTrue);
    });

    test('without the dictionary, mixed falls back and Ketik is unavailable', () {
      final b = builder(units[0].nodes[0], dictionary: const []);
      expect(b.available(LessonMode.type), isFalse);
      final ex = b.build(LessonMode.mixed, count: 10);
      expect(ex, hasLength(10));
      expect(ex.every((e) => e is ChoiceExercise || e is WriteExercise), isTrue);
    });

    test('yōon are written one kana after the other', () {
      final yoon = units.firstWhere((u) => u.nodes.first.kana.first.isYoon).nodes.first;
      final b = builder(yoon);
      expect(b.available(LessonMode.write), isTrue);
      expect(b.writable, containsAll(yoon.kana));
    });

    test('every intro node builds a full mixed lesson', () {
      for (final u in units) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) {
          final count = (n.kana.length * 2).clamp(6, 10);
          expect(builder(n).build(LessonMode.mixed, count: count), hasLength(count), reason: n.id);
        }
      }
    });
  });

  group('intro practice and quiz', () {
    test('every character is practised by writing, then reading', () {
      final node = units[0].nodes[1];
      final b = builder(node);
      for (final k in node.kana) {
        final p = b.practice(k);
        expect(p, hasLength(2), reason: k.literal);
        expect((p[0] as WriteExercise).target, k);
        expect((p[0] as WriteExercise).hint, k.romaji);
        expect((p[1] as GlyphReadExercise).glyph, k);
        expect((p[1] as GlyphReadExercise).answer, k.romaji);
      }
    });

    test('quiz words always use a character of the node', () {
      for (final u in units) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) {
          for (var seed = 0; seed < 5; seed++) {
            final ex = builder(n, seed: seed).build(LessonMode.quiz);
            final words = [
              for (final e in ex.whereType<BuildExercise>()) (e.word, e.items),
              for (final e in ex.whereType<ReadExercise>()) (e.word, e.items),
            ];
            for (final (word, items) in words) {
              expect(items.any(n.kana.contains), isTrue, reason: '${n.id}: ${word.kana}');
            }
          }
        }
      }
    });

    test('quiz has at most three writing questions and reads both ways', () {
      for (final u in units) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) {
          final ex = builder(n).build(LessonMode.quiz);
          expect(ex.whereType<WriteExercise>().length, lessThanOrEqualTo(LessonBuilder.maxQuizWrites), reason: n.id);
          expect(ex.whereType<WriteExercise>(), isNotEmpty, reason: n.id);
          final kinds = ex.whereType<ChoiceExercise>().map((c) => c.kind).toSet();
          expect(kinds, containsAll([ChoiceKind.kanaReading, ChoiceKind.pickKana]), reason: n.id);
          expect(ex.take(2).every((e) => e is ChoiceExercise), isTrue);
        }
      }
    });

    test('quiz questions only ask about the node, distractors may be older', () {
      final node = units[0].nodes[1];
      final ex = builder(node).build(LessonMode.quiz);
      for (final e in ex.whereType<ChoiceExercise>()) {
        expect(node.kana, contains(e.item));
      }
      for (final e in ex.whereType<WriteExercise>()) {
        expect(node.kana, contains(e.target));
      }
    });

    test('without the dictionary the quiz has no word questions', () {
      final ex = builder(units[0].nodes[1], dictionary: const []).build(LessonMode.quiz);
      expect(ex, isNotEmpty);
      expect(ex.whereType<BuildExercise>(), isEmpty);
      expect(ex.whereType<ReadExercise>(), isEmpty);
    });
  });

  group('checking answers', () {
    test('build tiles contain the answer and check the order', () {
      final ex = builder(units[0].nodes[1]).build(LessonMode.type).whereType<BuildExercise>().first;
      for (final k in ex.answer) {
        expect(ex.tiles.where((t) => t == k).length, greaterThanOrEqualTo(ex.answer.where((a) => a == k).length));
      }
      expect(ex.check(ex.answer), isTrue);
      if (ex.answer.toSet().length > 1) expect(ex.check(ex.answer.reversed.toList()), isFalse);
    });

    test('reading accepts any romanisation of the same kana', () {
      const word = DictWord(id: 1, kana: 'おおきい', romaji: 'ookii', jlpt: 5, gloss: 'big');
      const ex = ReadExercise(word: word, shown: 'おおきい', items: []);
      expect(ex.check('ookii'), isTrue);
      expect(ex.check(' OOKII '), isTrue);
      expect(ex.check('okii'), isFalse);
      expect(ex.check(''), isFalse);

      const shashin = ReadExercise(
        word: DictWord(id: 2, kana: 'しゃしん', romaji: 'shashin', jlpt: 5, gloss: 'photo'),
        shown: 'しゃしん',
        items: [],
      );
      expect(shashin.check('syasin'), isTrue);
      const tv = ReadExercise(
        word: DictWord(id: 3, kana: 'テレビ', romaji: 'terebi', jlpt: 5, gloss: 'TV'),
        shown: 'テレビ',
        items: [],
      );
      expect(tv.check('terebi'), isTrue);
    });
  });
}
