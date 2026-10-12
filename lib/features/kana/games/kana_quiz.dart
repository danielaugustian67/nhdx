import 'dart:math';

import '../../../core/database/content_db.dart';

enum QuizDirection {
  /// Show kana, answer with romaji.
  kanaToRomaji,

  /// Show romaji, answer with kana.
  romajiToKana,
}

class QuizQuestion {
  const QuizQuestion({required this.kana, required this.direction, required this.options, required this.answerIndex});

  final Kana kana;
  final QuizDirection direction;

  /// Display strings (romaji or kana) for the choices.
  final List<String> options;
  final int answerIndex;

  String get prompt => direction == QuizDirection.kanaToRomaji ? kana.literal : kana.romaji;
  String get answer => options[answerIndex];
}

/// Builds multiple-choice questions. Distractors never share the answer's
/// romaji: ぢ/じ ("ji") and づ/ず ("zu") would otherwise make two options
/// correct.
class KanaQuizGenerator {
  /// Questions are asked about [pool]; wrong options come from [distractors]
  /// (defaults to [pool]) so a lesson with only 3 new kana still has 4
  /// distinct choices.
  KanaQuizGenerator(this.pool, {List<Kana>? distractors, Random? random})
    : distractors = distractors ?? pool,
      _random = random ?? Random() {
    if (pool.isEmpty) throw ArgumentError('pool is empty');
    final distinct = {...this.distractors.map((k) => k.romaji), ...pool.map((k) => k.romaji)};
    if (distinct.length < 4) throw ArgumentError('need at least 4 distinct kana, got ${distinct.length}');
  }

  final List<Kana> pool;
  final List<Kana> distractors;
  final Random _random;

  QuizQuestion question(Kana kana, QuizDirection direction) {
    String show(Kana k) => direction == QuizDirection.kanaToRomaji ? k.romaji : k.literal;
    final candidates = {...distractors, ...pool}.where((k) => k.romaji != kana.romaji).toList()..shuffle(_random);
    final wrong = <Kana>[];
    final seen = {show(kana)};
    for (final k in candidates) {
      if (seen.add(show(k))) wrong.add(k);
      if (wrong.length == 3) break;
    }
    final options = [kana, ...wrong]..shuffle(_random);
    return QuizQuestion(
      kana: kana,
      direction: direction,
      options: [for (final k in options) show(k)],
      answerIndex: options.indexOf(kana),
    );
  }

  /// [count] questions, each kana at most once (unless the pool is smaller),
  /// alternating directions when [direction] is null. [focus] kana (weak
  /// ones) are asked first.
  List<QuizQuestion> session({int count = 10, QuizDirection? direction, Set<Kana> focus = const {}}) {
    final ordered = [
      ...(focus.where(pool.contains).toList()..shuffle(_random)),
      ...(pool.where((k) => !focus.contains(k)).toList()..shuffle(_random)),
    ];
    return [
      for (var i = 0; i < count; i++)
        question(
          ordered[i % ordered.length],
          direction ?? (i.isEven ? QuizDirection.kanaToRomaji : QuizDirection.romajiToKana),
        ),
    ];
  }
}

/// XP and combo rules shared by the quiz and Speed Drill (ui-design §5.7).
abstract final class XpRules {
  static const perCorrect = 10;

  /// ×1 for combo 0–4, ×2 for 5–9, ×3 for 10+.
  static int multiplier(int combo) => 1 + min(combo ~/ 5, 2);

  static int forAnswer({required bool correct, required int comboBefore}) =>
      correct ? perCorrect * multiplier(comboBefore) : 0;
}
