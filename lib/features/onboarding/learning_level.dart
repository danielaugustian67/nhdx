import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/providers.dart';
import '../../l10n/app_localizations.dart';
import '../learn/path_providers.dart';
import '../learn/study_language.dart';

/// Starting level (PRD F7 → *Pilihan Level Awal*), stored as
/// `learning_level` and synced. It picks the course on "Hari ini" and where
/// the vocabulary path starts; it never hides dictionary words.
enum LearningLevel {
  /// Cannot read kana yet: the Kana course, then N5.
  preN5('pre_n5', null),
  n5('n5', 5),
  n4('n4', 4),
  n3('n3', 3),
  n2('n2', 2),
  n1('n1', 1);

  const LearningLevel(this.value, this.jlpt);
  final String value;
  final int? jlpt;

  static const settingKey = 'learning_level';

  static LearningLevel? parse(String? v) => values.where((l) => l.value == v).firstOrNull;

  LearnTrack get track => this == preN5 ? LearnTrack.kana : LearnTrack.vocab;

  /// Levels on the vocabulary path, starting from this one (N4 skips N5).
  List<int> get vocabLevels => switch (this) {
    preN5 || n5 => const [5, 4, 3, 2, 1],
    n4 => const [4, 3, 2, 1],
    n3 => const [3, 2, 1],
    n2 => const [2, 1],
    n1 => const [1],
  };
}

String learningLevelName(AppLocalizations l10n, LearningLevel l) => switch (l) {
  LearningLevel.preN5 => l10n.levelFromZero,
  LearningLevel.n5 => l10n.levelBeginner,
  LearningLevel.n4 => l10n.levelBasic,
  LearningLevel.n3 => l10n.levelIntermediate,
  LearningLevel.n2 => l10n.levelUpperIntermediate,
  LearningLevel.n1 => l10n.levelAdvanced,
};

/// "Pemula · N5"; the level alone for Pra-N5.
String learningLevelLabel(AppLocalizations l10n, LearningLevel l) =>
    l.jlpt == null ? learningLevelName(l10n, l) : '${learningLevelName(l10n, l)} · N${l.jlpt}';

/// "Belum tahu" in v1.0: three yes/no questions (PRD F7), mapped to Pra-N5,
/// N5 or N4. Not a test, only a starting point the user can change.
LearningLevel selfCheckLevel({required bool hiragana, required bool katakana, required bool basicWords}) {
  if (!hiragana || !katakana) return LearningLevel.preN5;
  return basicWords ? LearningLevel.n4 : LearningLevel.n5;
}

final learningLevelProvider = StreamProvider<LearningLevel?>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSetting(LearningLevel.settingKey).map(LearningLevel.parse);
});

/// A new install without a language, a level and any learning data starts
/// with onboarding. Data from before onboarding existed counts as done.
final onboardingNeededProvider = StreamProvider<bool>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  if (await ref.watch(_languageChosenProvider.future)) {
    yield false;
    return;
  }
  yield* db
      .watchSetting(LearningLevel.settingKey)
      .asyncMap((v) async => LearningLevel.parse(v) == null && !await db.hasLearningData());
});

/// Whether a language to learn was chosen (Japanese learners from before
/// there was a choice have only a level).
final _languageChosenProvider = StreamProvider<bool>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSetting(StudyLanguage.settingKey).map((v) => v != null).distinct();
});

/// Saves [level] and opens its course on "Hari ini".
void applyLearningLevel(WidgetRef ref, LearningLevel level) {
  writeUserDb(ref.read(userDbProvider.future), (db) => db.setSetting(LearningLevel.settingKey, level.value));
  ref.read(learnTrackProvider.notifier).select(level.track);
}
