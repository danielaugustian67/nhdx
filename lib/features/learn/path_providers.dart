import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../kana/kana_providers.dart';
import '../onboarding/learning_level.dart';
import 'kana_path.dart';
import 'kanji_path.dart';
import 'lesson.dart';
import 'vocab_path.dart';

/// The courses on "Hari ini", each from easiest to hardest.
enum LearnTrack {
  kana,
  kanji,

  /// JLPT vocabulary (PRD F7); units are not locked.
  vocab;

  /// Whether every lesson can be opened, not only the next one.
  bool get free => this == vocab;
}

/// Selected course, remembered on this device (`device.learn_track`).
final learnTrackProvider = NotifierProvider<LearnTrackNotifier, LearnTrack>(LearnTrackNotifier.new);

class LearnTrackNotifier extends Notifier<LearnTrack> {
  static const settingKey = 'device.learn_track';

  @override
  LearnTrack build() {
    _load();
    return LearnTrack.kana;
  }

  Future<void> _load() async {
    try {
      final saved = await (await ref.read(userDbProvider.future)).setting(settingKey);
      final track = LearnTrack.values.where((t) => t.name == saved).firstOrNull;
      if (track != null && ref.mounted) state = track;
    } catch (e) {
      debugPrint('LearnTrack: user.db not available ($e)');
    }
  }

  void select(LearnTrack track) {
    state = track;
    writeUserDb(ref.read(userDbProvider.future), (db) => db.setSetting(settingKey, track.name));
  }
}

final kanaPathProvider = Provider<AsyncValue<List<PathUnit>>>(
  (ref) => ref.watch(allKanaProvider).whenData(buildKanaPath),
);

/// The kanji course (N5 to N1), easiest first, loaded once from content.db.
final allKanjiProvider = FutureProvider<List<Kanji>>((ref) async => (await ref.watch(contentProvider.future)).kanji());

final kanjiPathProvider = Provider<AsyncValue<List<PathUnit>>>(
  (ref) => ref.watch(allKanjiProvider).whenData(buildKanjiPath),
);

/// Path of the selected course.
final activePathProvider = Provider<AsyncValue<List<PathUnit>>>(
  (ref) => switch (ref.watch(learnTrackProvider)) {
    LearnTrack.kana => ref.watch(kanaPathProvider),
    LearnTrack.kanji => ref.watch(kanjiPathProvider),
    LearnTrack.vocab => ref.watch(vocabPathProvider),
  },
);

/// The vocabulary course: N5 to N1 dictionary words, loaded once, starting
/// at the chosen level (empty for levels without curated content yet).
final vocabPathProvider = Provider<AsyncValue<List<PathUnit>>>((ref) {
  final level = ref.watch(learningLevelProvider).value ?? LearningLevel.n5;
  return ref.watch(_vocabWordsProvider).whenData((words) => buildVocabPath(words, levels: level.vocabLevels));
});

final _vocabWordsProvider = FutureProvider<List<DictWord>>(
  (ref) async => (await ref.watch(dictionaryProvider.future)).jlptWords(maxLength: 100),
);

/// JLPT dictionary words for spelling/reading exercises, loaded once.
final lessonWordsProvider = FutureProvider<List<DictWord>>(
  (ref) async => (await ref.watch(dictionaryProvider.future)).jlptWords(),
);

/// Lesson builder for a node of either course. Without the dictionary (still
/// being installed on first launch) lessons fall back to choice and writing.
LessonBuilder lessonFor(PathNode node, {required List<DictWord> words, required List<Kana> allKana}) {
  if (node.items.firstOrNull is VocabWord) {
    return VocabLessonBuilder(focus: node.items.cast<VocabWord>(), pool: node.reviewPool.cast<VocabWord>());
  }
  if (node.items.firstOrNull is Kanji) {
    return KanjiLessonBuilder(
      focus: node.items.cast<Kanji>(),
      pool: node.reviewPool.cast<Kanji>(),
      hiragana: [
        for (final k in allKana)
          if (k.script == 'hiragana') k,
      ],
      dictionary: words,
    );
  }
  return KanaLessonBuilder(focus: node.kana, pool: node.reviewPool.cast<Kana>(), dictionary: words);
}

/// Completed path node ids, stored in user.db as lesson_progress (the node
/// id is the lesson id, e.g. `hiragana-u1-intro-0`).
final pathProgressProvider = NotifierProvider<PathProgressNotifier, Set<String>>(PathProgressNotifier.new);

class PathProgressNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    try {
      final done = await (await ref.read(userDbProvider.future)).doneLessons();
      if (ref.mounted) state = {...state, ...done};
    } catch (e) {
      debugPrint('PathProgress: user.db not available ($e)');
    }
  }

  /// Records that a lesson was opened (`in_progress` in lesson_progress).
  void start(String nodeId) => writeUserDb(ref.read(userDbProvider.future), (db) => db.startLesson(nodeId));

  void complete(String nodeId, {double? score}) {
    state = {...state, nodeId};
    writeUserDb(ref.read(userDbProvider.future), (db) => db.completeLesson(nodeId, score: score));
  }
}

enum NodeState {
  done,
  current,

  /// Not done and not next, but can be opened (courses without locks).
  open,
  locked,
}

/// Nodes unlock strictly in order: everything before the first unfinished
/// node is done, that node is current, the rest are locked. With [free]
/// (PRD F7: units not locked) the rest are [NodeState.open] instead, and
/// current is the first unfinished node anywhere.
NodeState nodeState(List<PathUnit> units, Set<String> done, String nodeId, {bool free = false}) =>
    nodeStates(units, done, free: free)[nodeId] ?? NodeState.locked;

/// [nodeState] of every node in one pass (a long path has over 1000 nodes).
Map<String, NodeState> nodeStates(List<PathUnit> units, Set<String> done, {bool free = false}) {
  final states = <String, NodeState>{};
  var passedUnfinished = false;
  for (final unit in units) {
    for (final node in unit.nodes) {
      if (done.contains(node.id)) {
        states[node.id] = NodeState.done;
      } else {
        states[node.id] = passedUnfinished ? (free ? NodeState.open : NodeState.locked) : NodeState.current;
        passedUnfinished = true;
      }
    }
  }
  return states;
}
