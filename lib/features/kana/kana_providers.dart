import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/providers.dart';
import '../../core/study_day.dart';

/// All kana rows (both scripts), loaded once from content.db.
final allKanaProvider = FutureProvider<List<Kana>>((ref) async {
  final db = await ref.watch(contentProvider.future);
  return db.kana();
});

/// Kana categories as shown by the filter chips.
enum KanaGroup {
  basic({'basic'}),
  dakuten({'dakuten', 'handakuten'}),
  yoon({'yoon'});

  const KanaGroup(this.kinds);
  final Set<String> kinds;
}

/// Which kana a game uses: script + group (ui-design §5.7).
class KanaSelection {
  const KanaSelection(this.script, this.group);
  final String script;
  final KanaGroup group;

  bool includes(Kana k) => k.script == script && group.kinds.contains(k.kind);

  @override
  bool operator ==(Object other) => other is KanaSelection && other.script == script && other.group == group;

  @override
  int get hashCode => Object.hash(script, group);
}

final kanaSelectionProvider = NotifierProvider<KanaSelectionNotifier, KanaSelection>(KanaSelectionNotifier.new);

class KanaSelectionNotifier extends Notifier<KanaSelection> {
  @override
  KanaSelection build() => const KanaSelection('hiragana', KanaGroup.basic);

  void setScript(String script) => state = KanaSelection(script, state.group);
  void setGroup(KanaGroup group) => state = KanaSelection(state.script, group);
}

final selectedKanaProvider = Provider<AsyncValue<List<Kana>>>((ref) {
  final selection = ref.watch(kanaSelectionProvider);
  return ref.watch(allKanaProvider).whenData((all) => all.where(selection.includes).toList());
});

/// Total XP and the glyphs that need practice. Every answer is stored in
/// user.db (exercise_attempts + today's daily_stats) and loaded back on
/// launch.
class KanaProgress {
  const KanaProgress({this.xp = 0, this.mistakes = const {}});

  final int xp;

  /// Glyph id (kana or kanji) → wrong answers minus correct answers (never
  /// below 0).
  final Map<int, int> mistakes;

  Set<int> get weakIds => {
    for (final e in mistakes.entries)
      if (e.value > 0) e.key,
  };
}

final kanaProgressProvider = NotifierProvider<KanaProgressNotifier, KanaProgress>(KanaProgressNotifier.new);

class KanaProgressNotifier extends Notifier<KanaProgress> {
  /// exercise_attempts.exercise_type of each glyph kind.
  static String typeOf(Glyph glyph) => glyph is Kanji ? 'kanji' : (glyph is Kana ? 'kana' : 'word');

  @override
  KanaProgress build() {
    _load();
    return const KanaProgress();
  }

  Future<void> _load() async {
    try {
      final db = await ref.read(userDbProvider.future);
      final xp = await db.totalXp();
      final mistakes = <int, int>{};
      for (final a in await db.attempts(const ['kana', 'kanji', 'word'])) {
        final id = int.tryParse(a.itemId ?? '');
        if (id != null) mistakes[id] = _next(mistakes[id] ?? 0, correct: a.correct == 1);
      }
      if (ref.mounted) state = KanaProgress(xp: xp, mistakes: mistakes);
    } catch (e) {
      debugPrint('KanaProgress: user.db not available ($e)');
    }
  }

  static int _next(int current, {required bool correct}) => correct ? (current - 1).clamp(0, 99) : current + 1;

  void record(Glyph glyph, {required bool correct, int xp = 0}) {
    final mistakes = Map.of(state.mistakes);
    mistakes[glyph.id] = _next(mistakes[glyph.id] ?? 0, correct: correct);
    state = KanaProgress(xp: state.xp + xp, mistakes: mistakes);
    final date = todayStudyDate();
    writeUserDb(ref.read(userDbProvider.future), (db) async {
      await db.addAttempt(type: typeOf(glyph), itemId: '${glyph.id}', correct: correct, studyDate: date);
      await db.addDailyStats(date, xp: xp, correctCount: correct ? 1 : 0);
    });
  }

  void addXp(int xp) {
    state = KanaProgress(xp: state.xp + xp, mistakes: state.mistakes);
    final date = todayStudyDate();
    writeUserDb(ref.read(userDbProvider.future), (db) => db.addDailyStats(date, xp: xp));
  }

  /// Stores the result of a finished game or lesson (game_scores).
  void recordGame(String game, {required int score, required double accuracy}) =>
      writeUserDb(ref.read(userDbProvider.future), (db) => db.addGameScore(game, score: score, accuracy: accuracy));
}
