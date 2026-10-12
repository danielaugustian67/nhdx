import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../../core/database/user_db.dart';
import '../../core/study_day.dart';
import '../kana/kana_providers.dart';
import 'sm2.dart';

/// Daily limits (PRD F5), chosen in Settings and synced.
class SrsLimits {
  const SrsLimits({this.newPerDay = defaultNew, this.reviewsPerDay = defaultReviews});

  final int newPerDay;
  final int reviewsPerDay;

  static const newKey = 'new_per_day';
  static const reviewsKey = 'reviews_per_day';
  static const defaultNew = 10;
  static const defaultReviews = 100;
  static const newOptions = [5, 10, 15, 20, 30];
  static const reviewOptions = [50, 100, 200, 500];

  static SrsLimits parse(Map<String, String?> s) {
    int pick(String key, List<int> options, int fallback) {
      final v = int.tryParse(s[key] ?? '');
      return options.contains(v) ? v! : fallback;
    }

    return SrsLimits(
      newPerDay: pick(newKey, newOptions, defaultNew),
      reviewsPerDay: pick(reviewsKey, reviewOptions, defaultReviews),
    );
  }

  static Future<SrsLimits> load(UserDb db) async => parse(await db.settings(const [newKey, reviewsKey]));
}

final srsLimitsProvider = StreamProvider<SrsLimits>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSettings(const [SrsLimits.newKey, SrsLimits.reviewsKey]).map(SrsLimits.parse);
});

/// Ids of the words that already have a card ("Sudah di belajar").
final studyWordIdsProvider = StreamProvider<Set<int>>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchCardItems('word').map((ids) => {for (final id in ids) ?int.tryParse(id)});
});

/// Due and new card counts for the review button; [fresh] only counts the new
/// cards today's limit still lets in. Re-evaluated when cards change; "now"
/// is taken when the provider is (re)built.
final cardCountsProvider = StreamProvider<({int due, int fresh})>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  // Rebuilt when the limit changes.
  ref.watch(srsLimitsProvider);
  yield* db.watchCardCounts(nowUtc()).asyncMap((c) async {
    final left = await newLeftToday(db);
    return (due: c.due, fresh: c.fresh < left ? c.fresh : left);
  });
});

/// New cards that may still be introduced today.
Future<int> newLeftToday(UserDb db) async {
  final limits = await SrsLimits.load(db);
  final done = await db.doneOn(todayStudyDate());
  final left = limits.newPerDay - done.newCount;
  return left < 0 ? 0 : left;
}

/// Which side a new word card asks from (PRD F5, a setting). Kana cards
/// always show the kana.
enum CardDirection {
  /// Japanese → meaning (default).
  jpToMeaning('jp_to_meaning'),

  /// Meaning → Japanese.
  meaningToJp('meaning_to_jp'),

  /// One card each way.
  both('both');

  const CardDirection(this.value);
  final String value;

  static const settingKey = 'card_direction';

  static CardDirection parse(String? v) => values.firstWhere((d) => d.value == v, orElse: () => jpToMeaning);

  /// Directions of the cards to create, as stored in `srs_cards.direction`.
  List<String> get cardDirections => switch (this) {
    both => [jpToMeaning.value, meaningToJp.value],
    _ => [value],
  };
}

final cardDirectionProvider = StreamProvider<CardDirection>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSetting(CardDirection.settingKey).map(CardDirection.parse);
});

void setCardDirection(WidgetRef ref, CardDirection d) =>
    writeUserDb(ref.read(userDbProvider.future), (db) => db.setSetting(CardDirection.settingKey, d.value));

/// Adds word cards in the direction(s) chosen in Settings.
Future<void> addWordCards(UserDb db, Iterable<({int id, String label})> words) async {
  final directions = CardDirection.parse(await db.setting(CardDirection.settingKey)).cardDirections;
  for (final w in words) {
    for (final d in directions) {
      await db.addCard('word', '${w.id}', label: w.label, direction: d);
    }
  }
}

void addWordCard(WidgetRef ref, int wordId, String label) =>
    writeUserDb(ref.read(userDbProvider.future), (db) => addWordCards(db, [(id: wordId, label: label)]));

/// Adds the next [count] words of a JLPT level that have no card yet, most
/// common first (empty-state "Tambah 10 kata N5").
Future<void> addNextLevelWords(WidgetRef ref, {required int level, required int count}) async {
  try {
    final db = await ref.read(userDbProvider.future);
    final dict = await ref.read(dictionaryProvider.future);
    final have = await db.watchCardItems('word').first;
    final words = dict.levelWords(level, limit: 10000).where((w) => !have.contains('${w.id}')).take(count);
    await addWordCards(db, [for (final w in words) (id: w.id, label: w.headword)]);
  } catch (e, st) {
    debugPrint('addNextLevelWords failed: $e\n$st');
  }
}

void addKanaCards(WidgetRef ref, Iterable<String> literals) {
  final list = literals.toList();
  writeUserDb(ref.read(userDbProvider.future), (db) async {
    for (final k in list) {
      await db.addCard('kana', k, label: k);
    }
  });
}

void removeWordCard(WidgetRef ref, int wordId) =>
    writeUserDb(ref.read(userDbProvider.future), (db) => db.removeCard('word', '$wordId'));

/// One card with what its two sides show.
class ReviewItem {
  const ReviewItem({required this.card, required this.front, this.reading, this.romaji, required this.back, this.jlpt});

  final SrsCard card;
  final String front;

  /// Kana reading shown on the back when [front] has kanji.
  final String? reading;
  final String? romaji;
  final String back;
  final int? jlpt;

  /// Meaning → Japanese: the front asks with [back], the answer is [front].
  bool get reversed => card.direction == CardDirection.meaningToJp.value;

  Schedule get schedule => Schedule(
    state: CardState.fromDb(card.state),
    intervalDays: card.intervalDays,
    ease: card.ease,
    reps: card.reps,
    lapses: card.lapses,
  );
}

/// Today's review session, resolved against the dictionary and kana table.
/// Cards whose item is gone are left out (they show as orphans elsewhere).
/// Loaded fresh for every session: the queue depends on the clock.
Future<List<ReviewItem>> loadReviewQueue(WidgetRef ref) async {
  final db = await ref.read(userDbProvider.future);
  final dict = await ref.read(dictionaryProvider.future);
  final kana = {for (final k in await ref.read(allKanaProvider.future)) k.literal: k};
  final limits = await SrsLimits.load(db);
  final done = await db.doneOn(todayStudyDate());
  final cards = await db.queue(
    nowIso: nowUtc(),
    newLeft: await newLeftToday(db),
    reviewLeft: limits.reviewsPerDay - done.reviewCount,
  );
  return [
    for (final c in cards)
      ?switch (c.cardType) {
        'word' => _wordItem(c, dict),
        'kana' => switch (kana[c.itemId]) {
          final k? => ReviewItem(card: c, front: k.literal, back: k.romaji),
          null => null,
        },
        _ => null,
      },
  ];
}

/// New cards in the deck that today's limit holds back (all of them once the
/// queue is empty).
Future<int> waitingNewCards(WidgetRef ref) async {
  final db = await ref.read(userDbProvider.future);
  return (await db.watchCardCounts(nowUtc()).first).fresh;
}

ReviewItem? _wordItem(SrsCard c, DictionaryDb dict) {
  final id = int.tryParse(c.itemId);
  final e = id == null ? null : dict.entry(id);
  if (e == null) return null;
  return ReviewItem(
    card: c,
    front: e.headword,
    reading: e.kanji == null ? null : e.kana,
    romaji: e.romaji,
    back: [for (final s in e.senses.take(3)) s.gloss.split('; ').take(3).join(', ')].join(' · '),
    jlpt: e.jlpt,
  );
}
