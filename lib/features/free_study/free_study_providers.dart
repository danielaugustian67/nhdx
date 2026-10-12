import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/providers.dart';
import '../learn/kana_path.dart';
import '../learn/path_providers.dart';
import '../learn/vocab_path.dart';

/// What "Hafalan Bebas" draws its cards from.
enum StudyKind { hiragana, katakana, kanji, word }

/// One group in the picker: the items of one "Kenali" lesson of the path.
class StudyGroup {
  const StudyGroup({required this.id, required this.unit, required this.items});

  /// The path node id, stable across releases.
  final String id;

  /// Unit number within the kind, for the section headers.
  final int unit;
  final List<Glyph> items;
}

/// Where an item's "hafal" mark is stored: "kana:あ", "kanji:休", "word:1234".
String studyKey(Glyph g) => switch (g) {
  VocabWord() => 'word:${g.id}',
  Kanji() => 'kanji:${g.literal}',
  _ => 'kana:${g.literal}',
};

/// The "Kenali" lessons of [kind] as picker groups, in path order.
List<StudyGroup> studyGroups(List<PathUnit> units, StudyKind kind) {
  final groups = <StudyGroup>[];
  var unit = 0;
  for (final u in units) {
    if (kind == StudyKind.hiragana && u.script != 'hiragana') continue;
    if (kind == StudyKind.katakana && u.script != 'katakana') continue;
    unit++;
    for (final node in u.nodes) {
      if (node.type == NodeType.intro) groups.add(StudyGroup(id: node.id, unit: unit, items: node.items));
    }
  }
  return groups;
}

final studyGroupsProvider = Provider.family<AsyncValue<List<StudyGroup>>, StudyKind>(
  (ref, kind) => switch (kind) {
    StudyKind.hiragana || StudyKind.katakana => ref.watch(kanaPathProvider),
    StudyKind.kanji => ref.watch(kanjiPathProvider),
    StudyKind.word => ref.watch(vocabPathProvider),
  }.whenData((units) => studyGroups(units, kind)),
);

enum StudyMark { known, notYet }

/// Items marked "Hafal" or "Belum", synced with the account like other
/// settings. An item without a mark has not been studied here yet.
class StudyMarksNotifier extends Notifier<Map<String, StudyMark>> {
  static const knownKey = 'free_study.known';
  static const notYetKey = 'free_study.not_yet';

  @override
  Map<String, StudyMark> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    try {
      final db = await ref.read(userDbProvider.future);
      final saved = await db.settings(const [knownKey, notYetKey]);
      if (!ref.mounted) return;
      state = {
        for (final k in _decode(saved[notYetKey])) k: StudyMark.notYet,
        for (final k in _decode(saved[knownKey])) k: StudyMark.known,
        // Marks made before the load finished win.
        ...state,
      };
    } catch (e) {
      debugPrint('StudyMarks: user.db not available ($e)');
    }
  }

  static List<String> _decode(String? json) {
    if (json == null) return const [];
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  /// Sets or (with null) clears the mark of [key].
  void set(String key, StudyMark? mark) {
    state = {...state}..remove(key);
    if (mark != null) state = {...state, key: mark};
    final known = [
      for (final e in state.entries)
        if (e.value == StudyMark.known) e.key,
    ];
    final notYet = [
      for (final e in state.entries)
        if (e.value == StudyMark.notYet) e.key,
    ];
    writeUserDb(ref.read(userDbProvider.future), (db) async {
      await db.setSetting(knownKey, jsonEncode(known));
      await db.setSetting(notYetKey, jsonEncode(notYet));
    });
  }
}

final studyMarksProvider = NotifierProvider<StudyMarksNotifier, Map<String, StudyMark>>(StudyMarksNotifier.new);

/// The picker's last choice on this device, for "Lanjutkan" and the options.
class StudyChoice {
  const StudyChoice({
    this.kind = StudyKind.hiragana,
    this.groups = const [],
    this.shuffle = true,
    this.meaningFirst = false,
  });

  final StudyKind kind;

  /// Group ids of the last session, empty before the first one.
  final List<String> groups;
  final bool shuffle;

  /// Show the reading or meaning first and recall the Japanese.
  final bool meaningFirst;

  StudyChoice copyWith({StudyKind? kind, List<String>? groups, bool? shuffle, bool? meaningFirst}) => StudyChoice(
    kind: kind ?? this.kind,
    groups: groups ?? this.groups,
    shuffle: shuffle ?? this.shuffle,
    meaningFirst: meaningFirst ?? this.meaningFirst,
  );

  Map<String, Object> toJson() => {
    'kind': kind.name,
    'groups': groups,
    'shuffle': shuffle,
    'meaningFirst': meaningFirst,
  };

  static StudyChoice fromJson(String? json) {
    if (json == null) return const StudyChoice();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return StudyChoice(
        kind: StudyKind.values.where((k) => k.name == m['kind']).firstOrNull ?? StudyKind.hiragana,
        groups: (m['groups'] as List?)?.cast<String>() ?? const [],
        shuffle: m['shuffle'] as bool? ?? true,
        meaningFirst: m['meaningFirst'] as bool? ?? false,
      );
    } catch (_) {
      return const StudyChoice();
    }
  }
}

class StudyChoiceNotifier extends Notifier<StudyChoice> {
  static const settingKey = 'device.free_study.choice';

  @override
  StudyChoice build() {
    _load();
    return const StudyChoice();
  }

  Future<void> _load() async {
    try {
      final saved = await (await ref.read(userDbProvider.future)).setting(settingKey);
      if (saved != null && ref.mounted) state = StudyChoice.fromJson(saved);
    } catch (e) {
      debugPrint('StudyChoice: user.db not available ($e)');
    }
  }

  void update(StudyChoice choice) {
    state = choice;
    writeUserDb(ref.read(userDbProvider.future), (db) => db.setSetting(settingKey, jsonEncode(choice.toJson())));
  }
}

final studyChoiceProvider = NotifierProvider<StudyChoiceNotifier, StudyChoice>(StudyChoiceNotifier.new);
