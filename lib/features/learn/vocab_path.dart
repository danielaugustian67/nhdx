import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import 'kana_path.dart';
import 'kanji_path.dart';

/// A dictionary word as a lesson item of the vocabulary course (PRD F7).
class VocabWord implements Glyph {
  const VocabWord(this.word);
  final DictWord word;

  @override
  int get id => word.id;

  /// The headword: kanji form when the word has one, else the kana.
  @override
  String get literal => word.kanji ?? word.kana;

  @override
  bool operator ==(Object other) => other is VocabWord && other.word.id == word.id;

  @override
  int get hashCode => word.id.hashCode;
}

/// Most words per "Kenali" lesson (PRD F7: ±10 words a lesson).
const wordsPerLesson = 10;

/// "Kenali" lessons per unit, followed by a unit review and a chest.
const lessonsPerUnit = 5;

/// Builds the vocabulary path (PRD F7): JLPT words per level, N5 then N4,
/// most frequent first, in lessons of about 10 words, 5 lessons a unit, then
/// a mixed review over the unit and a chest. Units are not locked: any
/// lesson can be opened (`LearnTrack.vocab.free`).
List<PathUnit> buildVocabPath(List<DictWord> words, {List<int> levels = const [5, 4]}) {
  final units = <PathUnit>[];
  for (final level in levels) {
    final lessons = splitEvenly([
      for (final w in words)
        if (w.jlpt == level) VocabWord(w),
    ], wordsPerLesson);
    final learned = <VocabWord>[];
    for (var start = 0; start < lessons.length; start += lessonsPerUnit) {
      final unitId = 'vocab-n$level-u${start ~/ lessonsPerUnit + 1}';
      final intros = <PathNode>[];
      for (final (i, group) in lessons.skip(start).take(lessonsPerUnit).indexed) {
        learned.addAll(group);
        intros.add(
          PathNode(id: '$unitId-intro-$i', type: NodeType.intro, items: group, reviewPool: List.unmodifiable(learned)),
        );
      }
      final unitWords = [for (final n in intros) ...n.items];
      final pool = List<VocabWord>.unmodifiable(learned);
      units.add(
        PathUnit(
          id: unitId,
          number: units.length + 1,
          script: 'vocab',
          jlpt: level,
          nodes: [
            ...intros,
            PathNode(id: '$unitId-review', type: NodeType.review, items: unitWords, reviewPool: pool),
            PathNode(id: '$unitId-chest', type: NodeType.chest, items: const [], reviewPool: pool),
          ],
        ),
      );
    }
  }
  return units;
}
