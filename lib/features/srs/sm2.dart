import 'dart:math' as math;

/// SM-2 scheduling (PRD F5), Anki-style: short learning steps for new and
/// lapsed cards, then day intervals multiplied by a per-card ease.
///
/// Pure: no clock, no I/O. The learning step is not stored; it is read back
/// from the interval (the schema has no step column), so the steps below
/// must stay strictly increasing.

enum Rating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const Rating(this.value);

  /// Stored in `review_logs.rating`.
  final int value;
}

enum CardState {
  newCard('new'),
  learning('learning'),
  review('review'),
  relearning('relearning');

  const CardState(this.dbName);

  /// Stored in `srs_cards.state`.
  final String dbName;

  static CardState fromDb(String name) => values.firstWhere((s) => s.dbName == name, orElse: () => newCard);
}

/// The scheduling part of a card.
class Schedule {
  const Schedule({
    this.state = CardState.newCard,
    this.intervalDays = 0,
    this.ease = Sm2.startEase,
    this.reps = 0,
    this.lapses = 0,
  });

  final CardState state;

  /// Fractions of a day while learning (10 min = 10 / 1440).
  final double intervalDays;
  final double ease;
  final int reps;
  final int lapses;

  Duration get interval => Duration(seconds: (intervalDays * Duration.secondsPerDay).round());

  @override
  bool operator ==(Object other) =>
      other is Schedule &&
      other.state == state &&
      other.intervalDays == intervalDays &&
      other.ease == ease &&
      other.reps == reps &&
      other.lapses == lapses;

  @override
  int get hashCode => Object.hash(state, intervalDays, ease, reps, lapses);

  @override
  String toString() => 'Schedule(${state.dbName}, ${intervalDays}d, ease $ease, reps $reps, lapses $lapses)';
}

abstract final class Sm2 {
  static const startEase = 2.5;
  static const minEase = 1.3;

  static const _minute = 1 / (24 * 60);

  /// New cards: Lagi → 1 m, Baik → 10 m, Baik again → graduate.
  static const learningSteps = [1 * _minute, 10 * _minute];

  /// Lapsed cards wait 10 m before coming back as reviews.
  static const relearningSteps = [10 * _minute];

  static const graduatingDays = 1.0;
  static const easyDays = 4.0;

  /// First review interval after a lapse, as days (Anki "new interval" 0 %).
  static const lapseDays = 1.0;

  static const hardFactor = 1.2;
  static const easyBonus = 1.3;

  /// The schedule after answering [card] with [rating].
  static Schedule answer(Schedule card, Rating rating) {
    final reps = card.reps + 1;
    switch (card.state) {
      case CardState.newCard:
      case CardState.learning:
        return _step(card, rating, learningSteps, reps: reps, lapses: card.lapses, ease: card.ease);
      case CardState.relearning:
        return _step(card, rating, relearningSteps, reps: reps, lapses: card.lapses, ease: card.ease);
      case CardState.review:
        return _review(card, rating, reps);
    }
  }

  static Schedule _step(
    Schedule card,
    Rating rating,
    List<double> steps, {
    required int reps,
    required int lapses,
    required double ease,
  }) {
    final relearning = card.state == CardState.relearning;
    final learning = relearning ? CardState.relearning : CardState.learning;
    final graduate = relearning ? lapseDays : graduatingDays;
    // A new card is on the first step; a learning card on the last step whose
    // interval it holds.
    final current = card.state == CardState.newCard ? 0 : _stepIndex(card.intervalDays, steps);
    switch (rating) {
      case Rating.again:
        return Schedule(state: learning, intervalDays: steps.first, ease: ease, reps: reps, lapses: lapses);
      case Rating.hard:
        // Repeat the current step; on the first step, halfway to the next.
        final delay = current == 0 && steps.length > 1 ? (steps[0] + steps[1]) / 2 : steps[current];
        return Schedule(state: learning, intervalDays: delay, ease: ease, reps: reps, lapses: lapses);
      case Rating.good:
        final next = current + 1;
        if (next < steps.length) {
          return Schedule(state: learning, intervalDays: steps[next], ease: ease, reps: reps, lapses: lapses);
        }
        return Schedule(state: CardState.review, intervalDays: graduate, ease: ease, reps: reps, lapses: lapses);
      case Rating.easy:
        return Schedule(
          state: CardState.review,
          intervalDays: relearning ? graduate + 1 : easyDays,
          ease: ease,
          reps: reps,
          lapses: lapses,
        );
    }
  }

  static int _stepIndex(double interval, List<double> steps) {
    var index = 0;
    for (var i = 0; i < steps.length; i++) {
      if (interval >= steps[i] - 1e-9) index = i;
    }
    return index;
  }

  static Schedule _review(Schedule card, Rating rating, int reps) {
    final last = math.max(card.intervalDays, 1.0);
    switch (rating) {
      case Rating.again:
        return Schedule(
          state: CardState.relearning,
          intervalDays: relearningSteps.first,
          ease: math.max(minEase, card.ease - 0.2),
          reps: reps,
          lapses: card.lapses + 1,
        );
      case Rating.hard:
        return Schedule(
          state: CardState.review,
          intervalDays: _days(last * hardFactor, atLeast: last + 1),
          ease: math.max(minEase, card.ease - 0.15),
          reps: reps,
          lapses: card.lapses,
        );
      case Rating.good:
        final hard = _days(last * hardFactor, atLeast: last + 1);
        return Schedule(
          state: CardState.review,
          intervalDays: _days(last * card.ease, atLeast: hard + 1),
          ease: card.ease,
          reps: reps,
          lapses: card.lapses,
        );
      case Rating.easy:
        final hard = _days(last * hardFactor, atLeast: last + 1);
        final good = _days(last * card.ease, atLeast: hard + 1);
        return Schedule(
          state: CardState.review,
          intervalDays: _days(last * card.ease * easyBonus, atLeast: good + 1),
          ease: card.ease + 0.15,
          reps: reps,
          lapses: card.lapses,
        );
    }
  }

  /// Whole days, never below [atLeast].
  static double _days(double days, {required double atLeast}) => math.max(days.roundToDouble(), atLeast);

  /// The interval each button would give, for the labels on the rating bar.
  static Map<Rating, Duration> preview(Schedule card) => {for (final r in Rating.values) r: answer(card, r).interval};
}
