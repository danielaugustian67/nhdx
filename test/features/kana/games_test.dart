import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/features/kana/games/kana_quiz.dart';
import 'package:nihondx/features/kana/games/memory_match.dart';

Kana _k(int id, String literal, String romaji) =>
    Kana(id: id, literal: literal, script: 'hiragana', romaji: romaji, rowGroup: 'x', kind: 'basic', orderNo: id);

final _pool = [
  _k(1, 'あ', 'a'),
  _k(2, 'い', 'i'),
  _k(3, 'う', 'u'),
  _k(4, 'え', 'e'),
  _k(5, 'お', 'o'),
  _k(6, 'じ', 'ji'),
  _k(7, 'ぢ', 'ji'),
  _k(8, 'ず', 'zu'),
  _k(9, 'づ', 'zu'),
  _k(10, 'か', 'ka'),
];

void main() {
  group('KanaQuizGenerator', () {
    test('options are distinct and contain the answer exactly once', () {
      final gen = KanaQuizGenerator(_pool, random: Random(1));
      for (final q in gen.session(count: 50)) {
        expect(q.options.toSet(), hasLength(4));
        expect(q.options.where((o) => o == q.answer), hasLength(1));
        final expected = q.direction == QuizDirection.kanaToRomaji ? q.kana.romaji : q.kana.literal;
        expect(q.answer, expected);
      }
    });

    test('ぢ is never a distractor for じ (same romaji)', () {
      final gen = KanaQuizGenerator(_pool, random: Random(2));
      for (var i = 0; i < 200; i++) {
        final q = gen.question(_pool[5], QuizDirection.romajiToKana); // じ
        expect(q.options, isNot(contains('ぢ')));
      }
    });

    test('focus kana come first and every kana appears before repeating', () {
      final gen = KanaQuizGenerator(_pool, random: Random(3));
      final focus = {_pool[9]};
      final qs = gen.session(count: 10, focus: focus);
      expect(qs.first.kana, _pool[9]);
      expect(qs.map((q) => q.kana).toSet(), hasLength(10));
    });

    test('alternates directions when none is given', () {
      final qs = KanaQuizGenerator(_pool, random: Random(4)).session(count: 4);
      expect(qs.map((q) => q.direction), [
        QuizDirection.kanaToRomaji,
        QuizDirection.romajiToKana,
        QuizDirection.kanaToRomaji,
        QuizDirection.romajiToKana,
      ]);
    });
  });

  group('XpRules', () {
    test('combo multiplier', () {
      expect(XpRules.forAnswer(correct: true, comboBefore: 0), 10);
      expect(XpRules.forAnswer(correct: true, comboBefore: 5), 20);
      expect(XpRules.forAnswer(correct: true, comboBefore: 12), 30);
      expect(XpRules.forAnswer(correct: false, comboBefore: 12), 0);
    });
  });

  group('MemoryMatchGame', () {
    test('deals 6 unambiguous pairs', () {
      final game = MemoryMatchGame(_pool, random: Random(5));
      expect(game.cards, hasLength(12));
      final romaji = game.cards.where((c) => c.showsKana).map((c) => c.kana.romaji);
      expect(romaji.toSet(), hasLength(6), reason: 'じ and ぢ never both dealt');
    });

    test('match, mismatch, hide, finish', () {
      final game = MemoryMatchGame(_pool, random: Random(6));
      final first = game.cards.first;
      final partner = game.cards.firstWhere((c) => c != first && c.kana == first.kana);
      final wrong = game.cards.firstWhere((c) => c.kana != first.kana);

      expect(game.flip(first), FlipResult.first);
      expect(game.flip(wrong), FlipResult.mismatch);
      expect(game.flip(partner), FlipResult.ignored, reason: 'locked until hidden');
      game.hideMismatch();
      expect(first.faceUp, isFalse);

      expect(game.flip(first), FlipResult.first);
      expect(game.flip(first), FlipResult.ignored);
      expect(game.flip(partner), FlipResult.match);
      expect(first.matched && partner.matched, isTrue);

      for (final c in game.cards.where((c) => !c.matched).toList()) {
        if (c.matched) continue;
        final p = game.cards.firstWhere((o) => o != c && o.kana == c.kana);
        game.flip(c);
        game.flip(p);
      }
      expect(game.finished, isTrue);
      expect(game.moves, 7);
      expect(game.mistakes, 1);
      expect(game.missed, containsAll([first.kana, wrong.kana]));
    });
  });
}
