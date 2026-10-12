import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/search/search_service.dart';
import 'content_db.dart';
import 'db_installer.dart';
import 'dictionary_db.dart';
import 'user_db.dart';

final _installerProvider = FutureProvider<DbInstaller>((ref) async {
  final support = await getApplicationSupportDirectory();
  return DbInstaller(targetDir: Directory(p.join(support.path, 'db')));
});

/// Installs (first launch / after an app update) and opens dictionary.db.
final dictionaryProvider = FutureProvider<DictionaryDb>((ref) async {
  final installer = await ref.watch(_installerProvider.future);
  // TODO(fase-2): pass onReplaced to remap word ids in user.db (PRD §7).
  final path = await installer.ensureInstalled('dictionary.db');
  final db = DictionaryDb.open(path);
  ref.onDispose(db.close);
  return db;
});

/// Installs and opens content.db (kana, KanjiVG strokes, curriculum).
final contentProvider = FutureProvider<ContentDb>((ref) async {
  final installer = await ref.watch(_installerProvider.future);
  final path = await installer.ensureInstalled('content.db');
  final db = ContentDb.open(path);
  ref.onDispose(db.close);
  return db;
});

/// The read-write user.db (progress, bookmarks, SRS, settings). Tests
/// override it with [UserDb.memory].
final userDbProvider = FutureProvider<UserDb>((ref) async {
  final support = await getApplicationSupportDirectory();
  final db = UserDb.open(File(p.join(support.path, 'user.db')));
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
