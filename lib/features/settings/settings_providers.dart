import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/providers.dart';
import '../../core/study_day.dart';

/// Light or dark look (ui-design §4.1: dark is the default). Stays on this
/// device.
enum ThemeChoice {
  dark(ThemeMode.dark),
  light(ThemeMode.light),
  system(ThemeMode.system);

  const ThemeChoice(this.mode);
  final ThemeMode mode;

  static const settingKey = 'device.theme';
  static ThemeChoice parse(String? v) => values.firstWhere((t) => t.name == v, orElse: () => dark);
}

/// UI language; [system] follows the phone (English when it is neither).
enum LanguageChoice {
  system(null),
  id(Locale('id')),
  en(Locale('en'));

  const LanguageChoice(this.locale);
  final Locale? locale;

  static const settingKey = 'device.locale';
  static LanguageChoice parse(String? v) => values.firstWhere((l) => l.name == v, orElse: () => system);
}

/// Text size on top of the phone's own setting.
enum TextSize {
  normal(1),
  large(1.15),
  larger(1.3);

  const TextSize(this.factor);
  final double factor;

  static const settingKey = 'device.text_size';
  static TextSize parse(String? v) => values.firstWhere((s) => s.name == v, orElse: () => normal);
}

typedef Appearance = ({ThemeChoice theme, LanguageChoice language, TextSize textSize});

const defaultAppearance = (theme: ThemeChoice.dark, language: LanguageChoice.system, textSize: TextSize.normal);

final appearanceProvider = StreamProvider<Appearance>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db
      .watchSettings(const [ThemeChoice.settingKey, LanguageChoice.settingKey, TextSize.settingKey])
      .map(
        (s) => (
          theme: ThemeChoice.parse(s[ThemeChoice.settingKey]),
          language: LanguageChoice.parse(s[LanguageChoice.settingKey]),
          textSize: TextSize.parse(s[TextSize.settingKey]),
        ),
      );
});

/// `day_start_hour` (synced). Applying it moves "today" for everything that
/// asks [todayStudyDate].
const dayStartKey = 'day_start_hour';

final dayStartHourProvider = StreamProvider<int>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSetting(dayStartKey).map((v) {
    setDayStartHour(int.tryParse(v ?? '') ?? defaultDayStartHour);
    return dayStartHour;
  });
});

/// Stores [value] under [key]; providers watching it pick it up.
void saveSetting(WidgetRef ref, String key, String value) =>
    writeUserDb(ref.read(userDbProvider.future), (db) => db.setSetting(key, value));
