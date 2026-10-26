import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../kana/kana_providers.dart';
import '../onboarding/learning_level.dart';
import 'hangul_path.dart';
import 'kana_path.dart';
import 'kanji_path.dart';
import 'lesson.dart';
import 'study_language.dart';
import 'vocab_path.dart';

/// The courses on "Hari ini", each from easiest to hardest.
enum LearnTrack {
  kana(StudyLanguage.ja),
  kanji(StudyLanguage.ja),

  /// JLPT vocabulary (PRD F7); units are not locked.
  vocab(StudyLanguage.ja),

  /// Korean letters and syllables.
  hangul(StudyLanguage.ko),

  /// Basic Korean words by topic; units are not locked.
  koVocab(StudyLanguage.ko);

  const LearnTrack(this.language);
  final StudyLanguage language;

  /// Whether every lesson can be opened, not only the next one.
  bool get free => this == vocab || this == koVocab;

  static List<LearnTrack> of(StudyLanguage language) => [
    for (final t in values)
      if (t.language == language) t,
  ];
}

/// Selected course of the language being learned, remembered on this device
/// per language (`device.learn_track`, `device.learn_track.ko`).
final learnTrackProvider = NotifierProvider<LearnTrackNotifier, LearnTrack>(LearnTrackNotifier.new);

class LearnTrackNotifier extends Notifier<LearnTrack> {
  static const settingKey = 'device.learn_track';

  static String keyOf(StudyLanguage language) =>
      language == StudyLanguage.ja ? settingKey : '$settingKey.${language.name}';

  @override
  LearnTrack build() {
    final language = ref.watch(studyLanguageProvider).value ?? StudyLanguage.ja;
    _load(language);
    return LearnTrack.of(language).first;
  }

  Future<void> _load(StudyLanguage language) async {
    try {
      final saved = await (await ref.read(userDbProvider.future)).setting(keyOf(language));
      final track = LearnTrack.of(language).where((t) => t.name == saved).firstOrNull;
      if (track != null && ref.mounted && state.language == language) state = track;
    } catch (e) {
      debugPrint('LearnTrack: user.db not available ($e)');
    }
  }

  /// Remembers [track] for its language; shows it when that language is
  /// the one being learned.
  void select(LearnTrack track) {
    if (track.language == state.language) state = track;
    writeUserDb(ref.read(userDbProvider.future), (db) => db.setSetting(keyOf(track.language), track.name));
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

/// Kanji introduced by the finished nodes of the kanji course: vocabulary
/// practice writes a word in kanji only when it uses none but these.
final knownKanjiProvider = Provider<Set<String>>((ref) {
  final done = ref.watch(pathProgressProvider);
  final units = ref.watch(kanjiPathProvider).value ?? const <PathUnit>[];
  return {
    for (final unit in units)
      for (final node in unit.nodes)
        if (node.type == NodeType.intro && done.contains(node.id))
          for (final k in node.items) k.literal,
  };
});

/// Path of the selected course.
final activePathProvider = Provider<AsyncValue<List<PathUnit>>>(
  (ref) => switch (ref.watch(learnTrackProvider)) {
    LearnTrack.kana => ref.watch(kanaPathProvider),
    LearnTrack.kanji => ref.watch(kanjiPathProvider),
    LearnTrack.vocab => ref.watch(vocabPathProvider),
    LearnTrack.hangul => ref.watch(hangulPathProvider),
    LearnTrack.koVocab => ref.watch(koVocabPathProvider),
  },
);

/// Hangul letters and syllables with the titles of their units, loaded once.
/// [written]: ids of the letters with stroke data (none in a content.db from
/// before content 1.7.0).
final hangulProvider = FutureProvider<({List<Kana> letters, Map<String, Localized> units, Set<int> written})>((
  ref,
) async {
  final db = await ref.watch(contentProvider.future);
  final letters = db.hangul();
  return (
    letters: letters,
    units: db.koreanGroups('hangul'),
    written: {
      for (final k in letters)
        if (db.strokes(k.literal).isNotEmpty) k.id,
    },
  );
});

final hangulPathProvider = Provider<AsyncValue<List<PathUnit>>>(
  (ref) => ref
      .watch(hangulProvider)
      .whenData((h) => buildHangulPath(h.letters, h.units, hasStrokes: (k) => h.written.contains(k.id))),
);

/// Korean words with the titles of their topics, loaded once.
final koWordsProvider = FutureProvider<({List<KoWord> words, Map<String, Localized> topics})>((ref) async {
  final db = await ref.watch(contentProvider.future);
  return (words: db.koreanWords(), topics: db.koreanGroups('words'));
});

/// Korean words as dictionary words in the app language, for the Hangul
/// course's spelling and reading exercises.
final koDictWordsProvider = Provider<AsyncValue<List<DictWord>>>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(koWordsProvider).whenData((k) => [for (final w in k.words) koDictWord(w, language)]);
});

final koVocabPathProvider = Provider<AsyncValue<List<PathUnit>>>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(koWordsProvider).whenData((k) => buildKoreanVocabPath(k.words, k.topics, language: language));
});

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

/// Lesson builder for a node of any course. Without the dictionary (still
/// being installed on first launch) lessons fall back to choice and writing.
/// Hangul lessons spell and read [koWords] instead.
LessonBuilder lessonFor(
  PathNode node, {
  required List<DictWord> words,
  required List<Kana> allKana,
  List<DictWord> koWords = const [],
  ContentDb? content,
  Set<String> knownKanji = const {},
}) {
  if (node.items.firstOrNull is VocabWord) {
    return VocabLessonBuilder(
      focus: node.items.cast<VocabWord>(),
      pool: node.reviewPool.cast<VocabWord>(),
      canWrite: content == null ? null : (ch) => content.strokes(ch).isNotEmpty,
      knownKanji: knownKanji,
    );
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
  final hangul = node.kana.firstOrNull?.isHangul ?? false;
  return KanaLessonBuilder(
    focus: node.kana,
    pool: node.reviewPool.cast<Kana>(),
    dictionary: hangul ? koWords : words,
    hasStrokes: content == null ? null : (k) => content.strokes(k.literal).isNotEmpty,
  );
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

/// Debug builds open every lesson, to try any of them without playing up to
/// it. Release builds keep the order.
final openAllLessonsProvider = Provider<bool>((ref) => kDebugMode);

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
/// An unfinished [PathNode.catchUp] node before a finished one is open and
/// does not lock what follows.
Map<String, NodeState> nodeStates(List<PathUnit> units, Set<String> done, {bool free = false}) {
  final states = <String, NodeState>{};
  final nodes = [for (final unit in units) ...unit.nodes];
  final lastDone = nodes.lastIndexWhere((n) => done.contains(n.id));
  var passedUnfinished = false;
  for (final (i, node) in nodes.indexed) {
    if (done.contains(node.id)) {
      states[node.id] = NodeState.done;
    } else if (node.catchUp && i < lastDone) {
      states[node.id] = passedUnfinished && !free ? NodeState.locked : NodeState.open;
    } else {
      states[node.id] = passedUnfinished ? (free ? NodeState.open : NodeState.locked) : NodeState.current;
      passedUnfinished = true;
    }
  }
  return states;
}
