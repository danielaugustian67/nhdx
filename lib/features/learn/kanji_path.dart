import '../../core/database/content_db.dart';
import 'kana_path.dart';

/// Most kanji per "Kenali" lesson.
const kanjiPerIntro = 5;

/// Builds the kanji learning path (ui-design §5.2): one unit per theme
/// ("Angka", "Hari", …; the kanji counterpart of the kana rows), N5 first,
/// in the course order of content.db (themes easiest first). Each unit:
/// "Kenali" lessons of up to 5 kanji, split evenly, then writing, chest and
/// a mixed review over the unit.
List<PathUnit> buildKanjiPath(List<Kanji> course) {
  final units = <PathUnit>[];
  final learned = <Kanji>[];
  for (final theme in _themes(course)) {
    final number = units.length + 1;
    final unitId = 'kanji-u$number';
    final intros = <PathNode>[];
    for (final (i, group) in splitEvenly(theme, kanjiPerIntro).indexed) {
      learned.addAll(group);
      intros.add(
        PathNode(id: '$unitId-intro-$i', type: NodeType.intro, items: group, reviewPool: List.unmodifiable(learned)),
      );
    }
    final pool = List<Kanji>.unmodifiable(learned);
    units.add(
      PathUnit(
        id: unitId,
        number: number,
        script: 'kanji',
        theme: theme.first.theme.isEmpty ? null : theme.first.theme,
        jlpt: theme.first.jlpt,
        nodes: [
          ...intros,
          PathNode(id: '$unitId-write', type: NodeType.write, items: theme, reviewPool: pool),
          PathNode(id: '$unitId-chest', type: NodeType.chest, items: const [], reviewPool: pool),
          PathNode(id: '$unitId-review', type: NodeType.review, items: theme, reviewPool: pool),
        ],
      ),
    );
  }
  return units;
}

/// Kanji per unit for levels without themes (N3 to N1).
const kanjiPerUnit = 15;

/// Consecutive runs of the same theme and level; kanji without a theme
/// (N3 to N1) in runs of [kanjiPerUnit].
List<List<Kanji>> _themes(List<Kanji> course) {
  final out = <List<Kanji>>[];
  for (final k in course) {
    final last = out.lastOrNull;
    final fits = k.theme.isNotEmpty || (last?.length ?? 0) < kanjiPerUnit;
    if (last != null && fits && last.first.theme == k.theme && last.first.jlpt == k.jlpt) {
      last.add(k);
    } else {
      out.add([k]);
    }
  }
  return out;
}

/// Splits [list] into the fewest lessons of at most [max], as even as
/// possible (14 → 5 5 4, 7 → 4 3).
List<List<T>> splitEvenly<T>(List<T> list, int max) {
  final n = (list.length / max).ceil();
  final out = <List<T>>[];
  var start = 0;
  for (var i = 0; i < n; i++) {
    final size = (list.length - start) ~/ (n - i) + ((list.length - start) % (n - i) == 0 ? 0 : 1);
    out.add(list.sublist(start, start + size));
    start += size;
  }
  return out;
}
