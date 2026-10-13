import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/providers.dart';
import '../../core/database/user_db.dart';
import '../../core/study_day.dart';
import '../learn/path_providers.dart';
import '../learn/study_language.dart';
import '../srs/srs_providers.dart';
import '../word/word_providers.dart';
import 'streak.dart';

/// Daily goal in cards (PRD F8): Santai 10, Rutin 20 (default), Serius 40.
/// Choosing one also sets new cards per day (5 / 10 / 20), which Settings
/// can still change on its own.
enum DailyGoal {
  relaxed(10, 5, 5),
  regular(20, 10, 10),
  serious(40, 20, 20);

  const DailyGoal(this.cards, this.minutes, this.newCards);
  final int cards;

  /// Rough time at ±30 s per card, for the label only.
  final int minutes;

  /// New cards per day that come with this goal.
  final int newCards;

  static const settingKey = 'daily_goal';
  static const fallback = 20;

  Future<void> save(UserDb db) async {
    await db.setSetting(settingKey, '$cards');
    await db.setSetting(SrsLimits.newKey, '$newCards');
  }
}

final dayTotalsProvider = StreamProvider<List<DayTotals>>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchDayTotals();
});

final reviewDaysProvider = StreamProvider<Map<String, ({int answers, int correct})>>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchReviewDays();
});

final _freezeDatesProvider = StreamProvider<Set<String>>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchFreezeDates();
});

final dailyGoalProvider = StreamProvider<int>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSetting(DailyGoal.settingKey).map((v) => int.tryParse(v ?? '') ?? DailyGoal.fallback);
});

void setDailyGoal(WidgetRef ref, DailyGoal goal) => writeUserDb(ref.read(userDbProvider.future), goal.save);

/// Totals keyed by study date.
final dayMapProvider = Provider<Map<String, DayTotals>>(
  (ref) => {for (final d in ref.watch(dayTotalsProvider).value ?? const <DayTotals>[]) d.date: d},
);

final streakProvider = Provider<Streak>((ref) {
  final days = ref.watch(dayTotalsProvider).value ?? const <DayTotals>[];
  final frozen = ref.watch(_freezeDatesProvider).value ?? const <String>{};
  return Streak.compute(
    {
      for (final d in days)
        if (d.active) d.date,
    },
    frozen,
    todayStudyDate(),
  );
});

final liveCardsProvider = StreamProvider<List<SrsCard>>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchLiveCards();
});

/// Cards per learning stage. "Mature" follows the usual 21-day mark.
typedef CardStages = ({int fresh, int learning, int young, int mature});

/// The live cards of the language being learned.
final languageCardsProvider = Provider<List<SrsCard>>((ref) {
  final korean = ref.watch(studyLanguageProvider).value == StudyLanguage.ko;
  return [
    for (final c in ref.watch(liveCardsProvider).value ?? const <SrsCard>[])
      if (koreanCardTypes.contains(c.cardType) == korean) c,
  ];
});

final cardStagesProvider = Provider<CardStages>((ref) {
  var (fresh, learning, young, mature) = (0, 0, 0, 0);
  for (final c in ref.watch(languageCardsProvider)) {
    switch (c.state) {
      case 'new':
        fresh++;
      case 'learning' || 'relearning':
        learning++;
      default:
        if (c.intervalDays >= 21) {
          mature++;
        } else {
          young++;
        }
    }
  }
  return (fresh: fresh, learning: learning, young: young, mature: mature);
});

/// Words studied (any card past "new") out of each JLPT level, N5 → N1.
final jlptProgressProvider = FutureProvider<Map<int, ({int learned, int total})>>((ref) async {
  final cards = await ref.watch(liveCardsProvider.future);
  final totals = await ref.watch(levelCountsProvider.future);
  final dict = await ref.watch(dictionaryProvider.future);
  final ids = [
    for (final c in cards)
      if (c.cardType == 'word' && c.state != 'new') ?int.tryParse(c.itemId),
  ];
  final learned = <int, int>{};
  for (final w in dict.briefs(ids).values) {
    if (w.jlpt case final level?) learned[level] = (learned[level] ?? 0) + 1;
  }
  return {for (final MapEntry(:key, :value) in totals.entries) key: (learned: learned[key] ?? 0, total: value)};
});

/// Cards forgotten most often (PRD F8 "item tersulit"). A word reviewed in
/// both directions shows once, with its higher count.
final hardestCardsProvider = Provider<List<SrsCard>>((ref) {
  final byItem = <String, SrsCard>{};
  for (final c in ref.watch(languageCardsProvider)) {
    if (c.lapses == 0) continue;
    final key = '${c.cardType}:${c.itemId}';
    if ((byItem[key]?.lapses ?? 0) < c.lapses) byItem[key] = c;
  }
  final cards = byItem.values.toList()..sort((a, b) => b.lapses.compareTo(a.lapses));
  return cards.take(5).toList();
});

/// Items studied out of how many there are.
typedef Studied = ({int learned, int total});

/// Hangul letters and Korean course words studied (any card past "new"),
/// the Korean counterpart of [jlptProgressProvider].
final koreanProgressProvider = FutureProvider<({Studied hangul, Studied words})>((ref) async {
  final cards = await ref.watch(liveCardsProvider.future);
  final letters = {for (final k in (await ref.watch(hangulProvider.future)).letters) k.literal};
  final words = {for (final w in (await ref.watch(koWordsProvider.future)).words) '${w.id}'};
  Set<String> studied(String type) => {
    for (final c in cards)
      if (c.cardType == type && c.state != 'new') c.itemId,
  };
  return (
    hangul: (learned: studied('hangul').intersection(letters).length, total: letters.length),
    words: (learned: studied('ko_word').intersection(words).length, total: words.length),
  );
});
