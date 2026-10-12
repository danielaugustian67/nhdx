import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/providers.dart';

/// All grammar points (PRD F13), N5 first.
final grammarProvider = FutureProvider<List<GrammarPoint>>((ref) async {
  final content = await ref.watch(contentProvider.future);
  return content.grammar();
});

/// Path-progress key of a finished grammar point.
String grammarDoneKey(String id) => 'grammar-$id';

/// Ids of grammar points that have a review card.
final grammarCardIdsProvider = StreamProvider<Set<String>>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchCardItems('grammar');
});
