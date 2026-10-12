import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/learn/lesson.dart';
import 'package:nihondx/features/learn/path_providers.dart';
import 'package:nihondx/features/learn/vocab_path.dart';

/// [n] words of [level] with distinct meanings; every third has no kanji.
List<DictWord> _words(int level, int n, {int from = 0}) => [
  for (var i = from; i < from + n; i++)
    DictWord(
      id: level * 10000 + i,
      kana: 'かな$i',
      kanji: i % 3 == 0 ? null : '漢$i',
      romaji: 'kana$i',
      jlpt: level,
      gloss: 'meaning $level-$i',
    ),
];

void main() {
  final words = [..._words(5, 67), ..._words(4, 23)];
  final units = buildVocabPath(words);

  test('N5 then N4, about 10 words a lesson, 5 lessons a unit', () {
    final n5 = units.where((u) => u.jlpt == 5).toList();
    final n4 = units.where((u) => u.jlpt == 4).toList();
    // 67 words → 7 lessons (10 10 10 10 9 9 9) → units of 5 + 2.
    expect(n5, hasLength(2));
    expect(n4, hasLength(1));
    expect([for (final u in units) u.number], [1, 2, 3]);
    expect(n5.first.nodes.map((n) => n.type), [...List.filled(5, NodeType.intro), NodeType.review, NodeType.chest]);
    final lessons = [
      for (final u in n5)
        for (final n in u.nodes)
          if (n.type == NodeType.intro) n.items.length,
    ];
    expect(lessons, [10, 10, 10, 10, 9, 9, 9]);
    expect(n5.expand((u) => u.introduced).length, 67);
    // Stable ids per level, for lesson_progress.
    expect(n4.single.nodes.first.id, 'vocab-n4-u1-intro-0');
    // The review covers the whole unit.
    expect(n5.first.nodes[5].items, n5.first.introduced);
  });

  test('vocabulary units are not locked; current is the first unfinished lesson', () {
    final first = units[0].nodes[0].id, second = units[0].nodes[1].id, later = units[2].nodes[0].id;
    expect(nodeState(units, {}, first, free: true), NodeState.current);
    expect(nodeState(units, {}, later, free: true), NodeState.open);
    expect(nodeState(units, {later}, later, free: true), NodeState.done);
    expect(nodeState(units, {first}, second, free: true), NodeState.current);
    // The kana and kanji courses stay strictly in order.
    expect(nodeState(units, {}, later), NodeState.locked);
  });

  group('VocabLessonBuilder', () {
    final node = units[0].nodes[0];
    VocabLessonBuilder builder(int seed) => VocabLessonBuilder(
      focus: node.items.cast<VocabWord>(),
      pool: node.reviewPool.cast<VocabWord>(),
      random: Random(seed),
    );

    test('mixed lesson: choices both ways, matching and typing, no writing', () {
      for (var seed = 0; seed < 20; seed++) {
        final ex = builder(seed).build(LessonMode.mixed, count: 12);
        expect(ex, hasLength(12));
        expect(ex.whereType<WriteExercise>(), isEmpty);
        expect(ex.whereType<MatchExercise>(), hasLength(2));
        expect(ex.whereType<ReadExercise>(), hasLength(3));
        final kinds = ex.whereType<ChoiceExercise>().map((q) => q.kind).toSet();
        expect(kinds, {ChoiceKind.wordMeaning, ChoiceKind.pickWord});
        // Warm-up: the first two are recognition questions.
        expect(ex.take(2), everyElement(isA<ChoiceExercise>()));
      }
    });

    test('choice options are 4 distinct values with the answer among them', () {
      for (final q in builder(3).choices(20, const {}).cast<ChoiceExercise>()) {
        expect(q.options.toSet(), hasLength(4));
        final w = q.item as VocabWord;
        expect(q.answer, q.kind == ChoiceKind.wordMeaning ? w.word.gloss : w.literal);
        expect(q.prompt, q.kind == ChoiceKind.wordMeaning ? w.literal : w.word.gloss);
      }
    });

    test('weak words are asked first', () {
      final weak = node.items[7].id;
      final qs = builder(1).choices(3, {weak}).cast<ChoiceExercise>();
      expect(qs.first.item.id, weak);
    });

    test('typing: kana-only words are recalled from the meaning, kanji words also read', () {
      final typed = builder(2).build(LessonMode.type, count: 30).cast<ReadExercise>();
      for (final r in typed) {
        if (!r.fromMeaning) {
          expect(r.word.kanji, isNotNull);
          expect(r.shown, r.word.kanji);
        } else {
          expect(r.shown, r.word.gloss);
        }
      }
      expect(typed.where((r) => r.fromMeaning), isNotEmpty);
      expect(typed.where((r) => !r.fromMeaning), isNotEmpty);
      expect(typed.first.check('KANA${typed.first.word.romaji.substring(4)}'), isTrue);
    });

    test('matching: 5 pairs with distinct meanings, meanings shuffled', () {
      final m = builder(4).build(LessonMode.match, count: 6).cast<MatchExercise>().first;
      expect(m.words, hasLength(VocabLessonBuilder.pairs));
      expect(m.words.map((w) => w.word.gloss).toSet(), hasLength(5));
      expect(m.meaningOrder.toSet(), {0, 1, 2, 3, 4});
    });

    test('write is not offered', () {
      expect(builder(0).available(LessonMode.write), isFalse);
      expect(builder(0).available(LessonMode.match), isTrue);
      expect(builder(0).available(LessonMode.type), isTrue);
    });
  });
}
