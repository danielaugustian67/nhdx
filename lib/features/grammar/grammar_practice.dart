import 'dart:math';

import '../../core/database/content_db.dart';

/// One exercise of a grammar point (PRD F13).
sealed class GrammarExercise {
  const GrammarExercise(this.point);
  final GrammarPoint point;

  /// The finished sentence, shown and read aloud after answering.
  String get sentence;
  String get sentenceKana;
}

/// Fill the ＿＿ by picking one of [options].
class GapExercise extends GrammarExercise {
  const GapExercise(super.point, this.quiz, this.options, this.answer);
  final GrammarQuiz quiz;

  /// [GrammarQuiz.options], shuffled.
  final List<String> options;
  final int answer;

  String filled(String option) => quiz.question.replaceFirst(GrammarQuiz.gap, option);

  @override
  String get sentence => filled(options[answer]);

  // Quiz questions have no separate reading; the TTS reads the kanji.
  @override
  String get sentenceKana => sentence;
}

/// Put the shuffled [tiles] of an example sentence in order.
class BuildExercise extends GrammarExercise {
  const BuildExercise(super.point, this.example, this.tiles);
  final GrammarExample example;
  final List<String> tiles;

  /// Right when the picked tiles spell the sentence (two orders can).
  bool accepts(List<String> picked) => picked.join() == example.chunks.join();

  @override
  String get sentence => example.japanese;

  @override
  String get sentenceKana => example.kana;
}

/// Exercises over [points]: every fill-in question and every example with
/// tiles, shuffled, at most [count], taken round-robin so each point gets
/// its share.
List<GrammarExercise> buildGrammarExercises(List<GrammarPoint> points, {int count = 10, Random? random}) {
  final rnd = random ?? Random();
  final perPoint = [
    for (final p in points)
      <GrammarExercise>[
        for (final q in p.quiz) _gap(p, q, rnd),
        for (final e in p.examples)
          if (e.chunks.length >= 2) BuildExercise(p, e, _shuffled(e.chunks, rnd)),
      ]..shuffle(rnd),
  ]..shuffle(rnd);
  final picked = <GrammarExercise>[];
  for (var round = 0; picked.length < count; round++) {
    var any = false;
    for (final list in perPoint) {
      if (round < list.length && picked.length < count) {
        picked.add(list[round]);
        any = true;
      }
    }
    if (!any) break;
  }
  return picked..shuffle(rnd);
}

GapExercise _gap(GrammarPoint p, GrammarQuiz q, Random rnd) {
  final order = List.generate(q.options.length, (i) => i)..shuffle(rnd);
  return GapExercise(p, q, [for (final i in order) q.options[i]], order.indexOf(q.answer));
}

/// [chunks] in a different order (when they can be).
List<String> _shuffled(List<String> chunks, Random rnd) {
  final out = [...chunks];
  for (var i = 0; i < 5; i++) {
    out.shuffle(rnd);
    if (out.join() != chunks.join()) break;
  }
  return out;
}
