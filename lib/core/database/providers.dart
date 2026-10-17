import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/search/korean_search_service.dart';
import '../../features/search/search_service.dart';
import 'content_db.dart';
import 'dictionary_db.dart';
import 'korean_dict_db.dart';
import 'sqlite_platform.dart';
import 'user_db.dart';

/// Installs (first launch / after an app update) and opens dictionary.db.
final dictionaryProvider = FutureProvider<DictionaryDb>((ref) async {
  // TODO(fase-2): remap word ids in user.db when the dataset changes (PRD §7).
  final db = DictionaryDb.of(await openBundled('dictionary.db'));
  ref.onDispose(db.close);
  return db;
});

/// Installs and opens content.db (kana, KanjiVG strokes, curriculum).
final contentProvider = FutureProvider<ContentDb>((ref) async {
  final db = ContentDb(await openBundled('content.db'));
  ref.onDispose(db.close);
  return db;
});

/// Installs and opens korean.db, the Korean dictionary. Only opened while
/// Korean is being learned.
final koreanDictProvider = FutureProvider<KoreanDictDb>((ref) async {
  final db = KoreanDictDb.of(await openBundled('korean.db'));
  ref.onDispose(db.close);
  return db;
});

/// The read-write user.db (progress, bookmarks, SRS, settings). Tests
/// override it with [UserDb.memory].
final userDbProvider = FutureProvider<UserDb>((ref) async {
  final db = UserDb(await openUserDb());
  ref.onDispose(db.close);
  return db;
});

/// Runs a write on user.db once it is open. Failures are logged, not
/// thrown: the state in memory stays right for this session either way.
/// Pass `ref.read(userDbProvider.future)` (works with Ref and WidgetRef).
void writeUserDb(Future<UserDb> db, Future<void> Function(UserDb db) write) {
  db.then(write).catchError((Object e) {
    debugPrint('user.db write failed: $e');
  });
}

final searchServiceProvider = FutureProvider<SearchService>((ref) async {
  final dict = await ref.watch(dictionaryProvider.future);
  return SearchService(dict.db);
});

final koreanSearchServiceProvider = FutureProvider<KoreanSearchService>(
  (ref) async => KoreanSearchService(await ref.watch(koreanDictProvider.future)),
);
