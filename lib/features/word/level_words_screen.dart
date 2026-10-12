import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../search/search_service.dart';
import 'word_tile.dart';

/// All words of one JLPT level, most common first (PRD F7 "telusur per
/// level"). A level has at most a few thousand words, so they load at once.
final levelWordsProvider = FutureProvider.family<List<WordBrief>, int>(
  (ref, level) async => (await ref.watch(dictionaryProvider.future)).levelWords(level, limit: 10000),
);

class LevelWordsScreen extends ConsumerWidget {
  const LevelWordsScreen({super.key, required this.level});

  /// 5 (N5) … 1 (N1)
  final int level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(levelWordsProvider(level)).value ?? const <WordBrief>[];
    return Scaffold(
      appBar: AppBar(title: Text('JLPT N$level')),
      body: ListView.separated(
        itemCount: words.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (_, i) => WordTile(hit: SearchHit.fromBrief(words[i])),
      ),
    );
  }
}
