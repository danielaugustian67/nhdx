import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../learn/study_language.dart';
import '../search/search_service.dart';
import 'word_tile.dart';

/// The course words of one Korean topic, meanings in the app language.
final koTopicWordsProvider = FutureProvider.family<List<WordBrief>, String>((ref, topic) async {
  final language = ref.watch(contentLanguageProvider);
  return (await ref.watch(koreanDictProvider.future)).topicWords(topic, language: language);
});

/// Browse one topic of the Korean course from the Kamus tab, as the JLPT
/// level lists do for Japanese.
class KoreanTopicWordsScreen extends ConsumerWidget {
  const KoreanTopicWordsScreen({super.key, required this.topic, required this.title});

  final String topic;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(koTopicWordsProvider(topic)).value ?? const <WordBrief>[];
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        itemCount: words.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (_, i) => WordTile(hit: SearchHit.fromBrief(words[i])),
      ),
    );
  }
}
