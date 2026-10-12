import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../../core/database/user_db.dart';
import '../../core/study_day.dart';

/// One dictionary entry for the detail page.
final wordEntryProvider = FutureProvider.family<WordEntry?, int>(
  (ref, id) async => (await ref.watch(dictionaryProvider.future)).entry(id),
);

/// Live bookmarks, newest first (PRD F3).
final bookmarksProvider = StreamProvider<List<Bookmark>>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchBookmarks();
});

final bookmarkedIdsProvider = Provider<Set<int>>(
  (ref) => {for (final b in ref.watch(bookmarksProvider).value ?? const <Bookmark>[]) b.wordId},
);

/// Optimistic toggle: the stream updates as soon as the row is written.
void setBookmark(WidgetRef ref, int wordId, {required bool on, required String label, bool restore = false}) =>
    writeUserDb(
      ref.read(userDbProvider.future),
      (db) => db.setBookmark(wordId, on: on, label: label, restore: restore),
    );

/// Bookmarks joined with their dictionary rows. A null brief means the
/// entry is gone from the dataset ("yatim", shown with its label snapshot).
final collectionProvider = FutureProvider<List<(Bookmark, WordBrief?)>>((ref) async {
  final marks = await ref.watch(bookmarksProvider.future);
  final dict = await ref.watch(dictionaryProvider.future);
  final briefs = dict.briefs(marks.map((b) => b.wordId));
  return [for (final b in marks) (b, briefs[b.wordId])];
});

/// Search history, newest first (local only).
final searchHistoryProvider = StreamProvider<List<String>>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchHistory();
});

final wordOfTheDayProvider = FutureProvider<WordBrief?>(
  (ref) async => (await ref.watch(dictionaryProvider.future)).wordOfTheDay(todayStudyDate()),
);

/// Word count per JLPT level (5 → 1) for the browse chips.
final levelCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  final dict = await ref.watch(dictionaryProvider.future);
  return {for (var level = 5; level >= 1; level--) level: dict.levelCount(level)};
});
