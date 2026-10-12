import '../../core/database/content_db.dart';

/// What a node on the learning path opens (ui-design §5.2).
enum NodeType {
  /// Meet new characters (intro cards with stroke order), then a lesson.
  intro,

  /// Writing practice on the unit's characters.
  write,

  /// Kanji course: mixed lesson over the whole unit.
  review,

  /// Memory Match on everything learned so far in this script.
  match,

  /// 60-second Speed Drill on everything learned so far in this script.
  speed,

  /// Reward chest (bonus XP, no game).
  chest,
}

class PathNode {
  const PathNode({required this.id, required this.type, required this.items, required this.reviewPool});

  /// Stable id, e.g. "hiragana-u1-intro-0" (persisted as lesson progress in Fase 2).
  final String id;
  final NodeType type;

  /// Kana or kanji introduced or practised by this node.
  final List<Glyph> items;

  /// Characters available for distractors and review games: everything of
  /// this course (script) introduced up to and including this node.
  final List<Glyph> reviewPool;

  /// [items] as kana, for the kana-only games.
  List<Kana> get kana => items.whereType<Kana>().toList();

  /// Minimum accuracy to complete this node, or null when finishing is enough.
  /// Memory Match is exempt: early mismatches are how the game is played, not
  /// a sign of not knowing the kana.
  double? get passMark => switch (type) {
    NodeType.intro || NodeType.write || NodeType.review || NodeType.speed => lessonPassMark,
    NodeType.match || NodeType.chest => null,
  };

  int get xp => switch (type) {
    NodeType.intro => 15,
    NodeType.write || NodeType.review => 20,
    NodeType.match || NodeType.speed => 20,
    NodeType.chest => 30,
  };
}

class PathUnit {
  const PathUnit({
    required this.id,
    required this.number,
    required this.script,
    this.rows = const [],
    this.theme,
    this.jlpt,
    required this.nodes,
  });

  final String id;
  final int number;

  /// 'hiragana' | 'katakana' | 'kanji'
  final String script;

  /// Gojūon rows taught in this unit (a, ka, …), used for the title.
  final List<String> rows;

  /// Kanji course: the theme this unit teaches ("numbers", "week", …), the
  /// kanji counterpart of [rows].
  final String? theme;

  /// Kanji course: 5 = N5, 4 = N4.
  final int? jlpt;
  final List<PathNode> nodes;

  /// Everything this unit introduces, in order.
  List<Glyph> get introduced => [
    for (final n in nodes)
      if (n.type == NodeType.intro) ...n.items,
  ];
}

/// Accuracy needed to pass a lesson (quiz, writing, speed drill).
const lessonPassMark = 0.8;

/// Unit plan per script: which gojūon rows each unit teaches.
const _unitRows = [
  ['a', 'ka'],
  ['sa', 'ta'],
  ['na', 'ha'],
  ['ma', 'ya', 'ra'],
  ['wa', 'n'],
  ['ga', 'za', 'da', 'ba', 'pa'],
  ['ka', 'sa', 'ta', 'na', 'ha', 'ma', 'ra', 'ga', 'za', 'ba', 'pa'], // yōon
];

/// Builds the kana learning path: hiragana units, then katakana units. Rows
/// with fewer than 4 kana are merged into one intro so a quiz always has
/// enough distinct answers.
List<PathUnit> buildKanaPath(List<Kana> all) {
  final units = <PathUnit>[];
  var number = 0;
  for (final script in const ['hiragana', 'katakana']) {
    final learned = <Kana>[];
    for (var u = 0; u < _unitRows.length; u++) {
      final yoon = u == _unitRows.length - 1;
      final unitKana = [
        for (final row in _unitRows[u])
          ...all.where((k) => k.script == script && k.rowGroup == row && k.isYoon == yoon),
      ];
      if (unitKana.isEmpty) continue;
      final unitId = '$script-u${u + 1}';

      // Intro nodes: one per row, small rows merged with the next.
      final intros = <List<Kana>>[];
      var pending = <Kana>[];
      for (final row in _unitRows[u]) {
        pending.addAll(unitKana.where((k) => k.rowGroup == row));
        if (pending.length >= (yoon ? 6 : 4)) {
          intros.add(pending);
          pending = [];
        }
      }
      if (pending.isNotEmpty) {
        intros.isEmpty ? intros.add(pending) : intros.last.addAll(pending);
      }

      // An intro's quiz only draws distractors from kana met so far, never
      // from rows later in the same unit.
      final introNodes = <PathNode>[];
      for (final (i, group) in intros.indexed) {
        learned.addAll(group);
        introNodes.add(
          PathNode(id: '$unitId-intro-$i', type: NodeType.intro, items: group, reviewPool: List.unmodifiable(learned)),
        );
      }
      final pool = List<Kana>.unmodifiable(learned);

      final writable = unitKana.where((k) => !k.isYoon).toList();
      number++;
      units.add(
        PathUnit(
          id: unitId,
          number: number,
          script: script,
          rows: _unitRows[u],
          nodes: [
            ...introNodes,
            if (writable.isNotEmpty)
              PathNode(id: '$unitId-write', type: NodeType.write, items: writable, reviewPool: pool),
            PathNode(id: '$unitId-match', type: NodeType.match, items: unitKana, reviewPool: pool),
            PathNode(id: '$unitId-chest', type: NodeType.chest, items: const [], reviewPool: pool),
            PathNode(id: '$unitId-speed', type: NodeType.speed, items: unitKana, reviewPool: pool),
          ],
        ),
      );
    }
  }
  return units;
}
