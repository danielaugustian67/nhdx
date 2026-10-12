import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/features/srs/sm2.dart';

void main() {
  const fresh = Schedule();
  Schedule run(List<Rating> ratings, [Schedule from = fresh]) => ratings.fold(from, Sm2.answer);
  const review10 = Schedule(state: CardState.review, intervalDays: 10, ease: 2.5, reps: 5);

  group('new and learning', () {
    test('Lagi → 1 m, Sulit → 5.5 m, Baik → 10 m, Mudah → 4 d', () {
      final p = Sm2.preview(fresh);
      expect(p[Rating.again], const Duration(minutes: 1));
      expect(p[Rating.hard], const Duration(minutes: 5, seconds: 30));
      expect(p[Rating.good], const Duration(minutes: 10));
      expect(p[Rating.easy], const Duration(days: 4));
    });

    test('Baik twice graduates to 1 day', () {
      final s = run([Rating.good, Rating.good]);
      expect(s.state, CardState.review);
      expect(s.intervalDays, 1);
      expect(s.reps, 2);
      expect(s.ease, Sm2.startEase);
    });

    test('Lagi in learning goes back to the first step', () {
      final s = run([Rating.good, Rating.again]);
      expect(s.state, CardState.learning);
      expect(s.interval, const Duration(minutes: 1));
    });

    test('Sulit on the last step repeats it', () {
      expect(run([Rating.good, Rating.hard]).interval, const Duration(minutes: 10));
    });

    test('learning never changes ease or lapses', () {
      final s = run([Rating.again, Rating.hard, Rating.again, Rating.good, Rating.good]);
      expect(s.ease, Sm2.startEase);
      expect(s.lapses, 0);
      expect(s.state, CardState.review);
    });
  });

  group('review', () {
    test('Baik multiplies by ease, Sulit by 1.2, Mudah adds the bonus', () {
      final p = Sm2.preview(review10);
      expect(p[Rating.hard], const Duration(days: 12));
      expect(p[Rating.good], const Duration(days: 25));
      expect(p[Rating.easy], const Duration(days: 33)); // 10 × 2.5 × 1.3 = 32.5 → 33
    });

    test('button intervals are strictly increasing, even for short intervals', () {
      for (final days in [1.0, 2.0, 3.0]) {
        for (final ease in [1.3, 1.5, 2.5]) {
          final p = Sm2.preview(Schedule(state: CardState.review, intervalDays: days, ease: ease));
          expect(p[Rating.hard]! < p[Rating.good]!, isTrue, reason: '$days d, ease $ease');
          expect(p[Rating.good]! < p[Rating.easy]!, isTrue, reason: '$days d, ease $ease');
          expect(p[Rating.hard]!.inDays, greaterThan(days));
        }
      }
    });

    test('ease: Sulit −0.15, Baik ±0, Mudah +0.15', () {
      expect(Sm2.answer(review10, Rating.hard).ease, closeTo(2.35, 1e-9));
      expect(Sm2.answer(review10, Rating.good).ease, 2.5);
      expect(Sm2.answer(review10, Rating.easy).ease, closeTo(2.65, 1e-9));
    });

    test('Lagi is a lapse: relearning 10 m, ease −0.2', () {
      final s = Sm2.answer(review10, Rating.again);
      expect(s.state, CardState.relearning);
      expect(s.interval, const Duration(minutes: 10));
      expect(s.lapses, 1);
      expect(s.ease, closeTo(2.3, 1e-9));
    });

    test('relearning: Baik → 1 d review, Mudah → 2 d, Lagi stays', () {
      final lapsed = Sm2.answer(review10, Rating.again);
      expect(Sm2.answer(lapsed, Rating.good), isA<Schedule>().having((s) => s.intervalDays, 'days', 1));
      expect(Sm2.answer(lapsed, Rating.good).state, CardState.review);
      expect(Sm2.answer(lapsed, Rating.easy).intervalDays, 2);
      expect(Sm2.answer(lapsed, Rating.again).state, CardState.relearning);
      expect(Sm2.answer(lapsed, Rating.again).lapses, 1, reason: 'a lapse is counted once');
    });

    test('ease never drops below 1.3', () {
      var s = review10;
      for (var i = 0; i < 20; i++) {
        s = Sm2.answer(Sm2.answer(s, Rating.again), Rating.good);
      }
      expect(s.ease, Sm2.minEase);
      expect(s.lapses, 20);
    });

    test('a steady Baik streak grows the interval geometrically', () {
      final s = run([Rating.good, Rating.good, Rating.good, Rating.good, Rating.good]);
      // 1 d → 3 d (min hard + 1) → 8 d → 20 d
      expect(s.intervalDays, 20);
    });
  });

  test('states round-trip through their database names', () {
    for (final s in CardState.values) {
      expect(CardState.fromDb(s.dbName), s);
    }
    expect(CardState.fromDb('garbage'), CardState.newCard);
  });
}
