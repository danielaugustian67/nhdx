import '../../core/study_day.dart';

/// Streak recomputed from activity, never stored as a number (PRD §8).
///
/// Streak freezes (PRD §15 no. 3): every [earnEvery] active days in a row
/// earn one, up to [maxFreezes] held. A whole day without activity uses one
/// automatically. Earning and use are replayed from the activity dates, so
/// every device arrives at the same freezes once activity is synced, and a
/// day that later turns out active (synced from another phone) gives its
/// freeze back.
class Streak {
  const Streak({
    required this.current,
    required this.longest,
    required this.activeToday,
    this.freezes = 0,
    this.frozenDays = const {},
  });

  static const none = Streak(current: 0, longest: 0, activeToday: false);
  static const earnEvery = 7;
  static const maxFreezes = 2;

  /// Consecutive active days ending today, or yesterday while today has no
  /// activity yet: a streak only breaks once a whole day passes without any.
  final int current;
  final int longest;
  final bool activeToday;

  /// Freezes held now.
  final int freezes;

  /// Days kept by a freeze: earned ones used automatically, plus stored ones.
  final Set<String> frozenDays;

  /// Active days left until the next freeze; null while [maxFreezes] are held.
  int? get untilNextFreeze => freezes >= maxFreezes ? null : earnEvery - current % earnEvery;

  /// [active] are study dates with any learning (all devices); [stored] are
  /// dates covered by a stored freeze (`streak_freezes`, bought with coins in
  /// v2.0). A frozen day keeps the chain going but does not count as a day.
  /// Dates are `yyyy-MM-dd`.
  factory Streak.compute(Set<String> active, Set<String> stored, String today) {
    if (active.isEmpty) return none;
    var run = 0;
    var longest = 0;
    var held = 0;
    final frozen = <String>{};
    final first = (active.toList()..sort()).first;
    for (var d = first; d.compareTo(today) <= 0; d = addDays(d, 1)) {
      if (active.contains(d)) {
        run++;
        if (run > longest) longest = run;
        if (run % earnEvery == 0 && held < maxFreezes) held++;
      } else if (stored.contains(d)) {
        frozen.add(d);
      } else if (d == today) {
        // Today is not over yet.
      } else if (held > 0) {
        held--;
        frozen.add(d);
      } else {
        run = 0;
      }
    }
    return Streak(
      current: run,
      longest: longest,
      activeToday: active.contains(today),
      freezes: held,
      frozenDays: frozen,
    );
  }
}

/// The days of one month for a Monday-first calendar: leading nulls for the
/// days before the 1st, then each date (`yyyy-MM-dd`).
List<String?> monthCells(int year, int month) {
  final first = DateTime.utc(year, month);
  final days = DateTime.utc(year, month + 1, 0).day;
  return [
    for (var i = 1; i < first.weekday; i++) null,
    for (var d = 1; d <= days; d++) formatDate(DateTime.utc(year, month, d)),
  ];
}

/// A small fixed tilt per date (−8°…8°), so a page of stamps looks pressed by
/// hand but never changes between visits (ui-design §7).
double stampTiltDegrees(String date) {
  var h = 0;
  for (final unit in date.codeUnits) {
    h = (h * 31 + unit) & 0x7fffffff;
  }
  return (h % 17) - 8.0;
}
