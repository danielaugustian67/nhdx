import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/providers.dart';
import '../../core/database/user_db.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_providers.dart';
import 'vocab_path.dart';

/// The language being learned, stored as `study_language` and synced.
/// Japanese until another one is chosen. Each language has its own courses
/// on "Hari ini" and its own review cards; progress is kept per language.
enum StudyLanguage {
  ja('🇯🇵'),
  ko('🇰🇷');

  const StudyLanguage(this.flag);
  final String flag;

  static const settingKey = 'study_language';

  static StudyLanguage? parse(String? v) => values.where((l) => l.name == v).firstOrNull;
}

String studyLanguageName(AppLocalizations l10n, StudyLanguage l) => switch (l) {
  StudyLanguage.ja => l10n.languageJapanese,
  StudyLanguage.ko => l10n.languageKorean,
};

/// The hanko on a result screen: 済 done / 習 practise, or in Korean 완
/// (완료, done) / 연 (연습, practice).
String resultStamp(StudyLanguage? language, {required bool passed}) => language == StudyLanguage.ko
    ? (passed ? '완' : '연')
    : (passed ? '済' : '習');

/// SRS card types of the Korean course; every other type is Japanese.
const koreanCardTypes = ['hangul', 'ko_word'];

/// Whether [g] belongs to the Korean course (a Hangul letter or a Korean word).
bool isKoreanItem(Glyph g) => (g is Kana && g.isHangul) || (g is VocabWord && g.word.isKorean);

/// The language being learned, read once from [db].
Future<StudyLanguage> readStudyLanguage(UserDb db) async =>
    StudyLanguage.parse(await db.setting(StudyLanguage.settingKey)) ?? StudyLanguage.ja;

final studyLanguageProvider = StreamProvider<StudyLanguage>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSetting(StudyLanguage.settingKey).map((v) => StudyLanguage.parse(v) ?? StudyLanguage.ja);
});

void selectStudyLanguage(WidgetRef ref, StudyLanguage language) => writeUserDb(
  ref.read(userDbProvider.future),
  (db) => db.setSetting(StudyLanguage.settingKey, language.name),
);

/// Language of authored meanings ('id' or 'en'): the app language, English
/// when the phone's is neither.
final contentLanguageProvider = Provider<String>((ref) {
  final choice = ref.watch(appearanceProvider).value?.language ?? LanguageChoice.system;
  final code = choice.locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return code == 'id' ? 'id' : 'en';
});
