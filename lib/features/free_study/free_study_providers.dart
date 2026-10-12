import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../kana/kana_providers.dart';
import '../learn/kana_path.dart';
import '../learn/path_providers.dart';
import '../learn/vocab_path.dart';
import '../progress/progress_providers.dart';
import '../word/word_providers.dart';

/// What "Hafalan Bebas" draws its cards from: the path's lessons, the
/// saved words (Koleksiku), or review cards forgotten at least once.
enum StudyKind {
  hiragana,
  katakana,
  kanji,
  word,
  collection,
  forgotten;

  /// Groups come from the path; the others are lists cut into tens.
  bool get fromPath => index <= word.index;
}

/// One group in the picker: the items of one "Kenali" lesson of the path, or
/// ten items of a list.
class StudyGroup {
  const StudyGroup({required this.id, required this.unit, required this.items, this.label});

  /// The path node id, stable across releases ("collection-0" for lists).
  final String id;

  /// Unit number within the kind, for the section headers.
  final int unit;
  final List<Glyph> items;

  /// Shown instead of the unit number: "1–10".
  final String? label;
}

/// Items per group of a list (Koleksiku, Sering lupa).
const listGroupSize = 10;

/// [items] in groups of [listGroupSize]; ids "[prefix]-0", "[prefix]-1", ….
List<StudyGroup> listGroups(String prefix, List<Glyph> items) => [
  for (var i = 0, from = 0; from < items.length; i++, from += listGroupSize)
    StudyGroup(
      id: '$prefix-$i',
      unit: i + 1,
      label: '${from + 1}–${min(from + listGroupSize, items.length)}',
      items: items.sublist(from, min(from + listGroupSize, items.length)),
    ),
];

DictWord _dictWord(WordBrief b) =>
    DictWord(id: b.id, kana: b.kana, kanji: b.kanji, romaji: b.romaji, jlpt: b.jlpt ?? 0, gloss: b.gloss);

/// Saved words, newest first, without those gone from the dictionary.
final collectionItemsProvider = FutureProvider<List<Glyph>>((ref) async {
  final saved = await ref.watch(collectionProvider.future);
  return [
    for (final (_, brief) in saved)
      if (brief != null) VocabWord(_dictWord(brief)),
  ];
});

/// Kana, kanji and words of review cards forgotten at least once, most
/// often forgotten first. A word in both directions counts once, with its
/// higher lapse count.
final forgottenItemsProvider = FutureProvider<List<Glyph>>((ref) async {
  final cards = await ref.watch(liveCardsProvider.future);
  final lapses = <String, ({String type, String id, int lapses})>{};
  for (final c in cards) {
    if (c.lapses == 0 || !const {'kana', 'kanji', 'word'}.contains(c.cardType)) continue;
    final key = '${c.cardType}:${c.itemId}';
    if ((lapses[key]?.lapses ?? 0) < c.lapses) lapses[key] = (type: c.cardType, id: c.itemId, lapses: c.lapses);
  }
  if (lapses.isEmpty) return const [];
  final sorted = lapses.values.toList()..sort((a, b) => b.lapses.compareTo(a.lapses));
  // Only what the cards need: the dictionary is the slowest to open.
  bool any(String type) => sorted.any((c) => c.type == type);
  final kana = {
    if (any('kana'))
      for (final k in await ref.watch(allKanaProvider.future)) k.literal: k,
  };
  final kanji = {
    if (any('kanji'))
      for (final k in await ref.watch(allKanjiProvider.future)) k.literal: k,
  };
  final wordIds = [
    for (final c in sorted)
      if (c.type == 'word') ?int.tryParse(c.id),
  ];
  final briefs = wordIds.isEmpty
      ? const <int, WordBrief>{}
      : (await ref.watch(dictionaryProvider.future)).briefs(wordIds);
  return [
    for (final c in sorted)
      ?switch (c.type) {
        'kana' => kana[c.id],
        'kanji' => kanji[c.id],
        _ => switch (briefs[int.tryParse(c.id)]) {
          final b? => VocabWord(_dictWord(b)),
          null => null,
        },
      },
  ];
});

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
    StudyKind.collection => ref.watch(collectionItemsProvider).whenData((items) => listGroups('collection', items)),
    StudyKind.forgotten => ref.watch(forgottenItemsProvider).whenData((items) => listGroups('forgotten', items)),
    _ => switch (kind) {
      StudyKind.kanji => ref.watch(kanjiPathProvider),
      StudyKind.word => ref.watch(vocabPathProvider),
      _ => ref.watch(kanaPathProvider),
    }.whenData((units) => studyGroups(units, kind)),
  },
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
    _save();
  }

  /// Clears the marks of [keys] ("Reset tanda hafal").
  void clear(Iterable<String> keys) {
    final drop = keys.toSet();
    state = {...state}..removeWhere((k, _) => drop.contains(k));
    _save();
  }

  void _save() {
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
