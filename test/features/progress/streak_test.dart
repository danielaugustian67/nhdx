import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/study_day.dart';
import 'package:nihondx/features/progress/streak.dart';

void main() {
  const today = '2026-10-11';

  test('no activity, no streak', () {
    final s = Streak.compute({}, {}, today);
    expect((s.current, s.longest, s.activeToday), (0, 0, false));
  });

  test('counts back from today', () {
    final s = Streak.compute({'2026-10-09', '2026-10-10', '2026-10-11'}, {}, today);
    expect((s.current, s.longest, s.activeToday), (3, 3, true));
  });

  test('stays alive until today ends', () {
    final s = Streak.compute({'2026-10-09', '2026-10-10'}, {}, today);
    expect((s.current, s.activeToday), (2, false));
  });

  test('a missed day breaks it; the longest run is kept', () {
    final s = Streak.compute({'2026-10-01', '2026-10-02', '2026-10-03', '2026-10-04', '2026-10-09'}, {}, today);
    expect((s.current, s.longest), (0, 4));
  });

  test('a frozen day bridges the gap without counting', () {
    final s = Streak.compute({'2026-10-08', '2026-10-10', '2026-10-11'}, {'2026-10-09'}, today);
    expect((s.current, s.longest), (3, 3));
  });

  Set<String> days(String from, int count) => {for (var i = 0; i < count; i++) addDays(from, i)};

  test('seven days in a row earn a freeze, which covers a missed day', () {
    // 1–7 Oct earn one; 8 Oct is missed; 9–11 Oct continue the chain.
    final s = Streak.compute({...days('2026-10-01', 7), ...days('2026-10-09', 3)}, {}, today);
    expect((s.current, s.longest, s.freezes), (10, 10, 0));
    expect(s.frozenDays, {'2026-10-08'});
    expect(s.untilNextFreeze, 4);
  });

  test('at most two freezes are held; a third missed day breaks the streak', () {
    // 21 days earn three, but only two are kept.
    final held = Streak.compute(days('2026-09-01', 21), {}, '2026-09-21');
    expect((held.freezes, held.untilNextFreeze), (2, null));
    final s = Streak.compute({...days('2026-09-01', 21), '2026-09-25'}, {}, '2026-09-25');
    expect(s.frozenDays, {'2026-09-22', '2026-09-23'});
    expect((s.current, s.longest, s.freezes), (1, 21, 0));
  });

  test('today never uses a freeze, and activity synced later gives it back', () {
    final s = Streak.compute(days('2026-10-04', 7), {}, '2026-10-11');
    expect((s.current, s.freezes), (7, 1));
    expect(s.frozenDays, isEmpty);
    final later = Streak.compute(days('2026-10-03', 7), {}, '2026-10-11');
    expect((later.current, later.freezes), (7, 0));
    expect(later.frozenDays, {'2026-10-10'});
    final synced = Streak.compute({...days('2026-10-03', 7), '2026-10-10'}, {}, '2026-10-11');
    expect((synced.current, synced.freezes), (8, 1));
    expect(synced.frozenDays, isEmpty);
  });

  test('crosses month and year ends', () {
    final s = Streak.compute({'2025-12-31', '2026-01-01'}, {}, '2026-01-01');
    expect(s.current, 2);
    final m = Streak.compute({'2026-02-28', '2026-03-01'}, {}, '2026-03-01');
    expect(m.current, 2);
  });

  test('month grid starts on Monday', () {
    // 1 Oct 2026 is a Thursday: three blanks.
    final cells = monthCells(2026, 10);
    expect(cells.take(4), [null, null, null, '2026-10-01']);
    expect(cells.last, '2026-10-31');
    expect(monthCells(2026, 2).whereType<String>(), hasLength(28));
  });

  test('stamp tilt is stable and small', () {
    expect(stampTiltDegrees('2026-10-11'), stampTiltDegrees('2026-10-11'));
    for (var d = 1; d <= 28; d++) {
      expect(stampTiltDegrees('2026-10-${d.toString().padLeft(2, '0')}').abs(), lessThanOrEqualTo(8));
    }
  });
}
