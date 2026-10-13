import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import 'kana_path.dart';
import 'kanji_path.dart';
import 'vocab_path.dart';

/// Most letters or syllables met in one "Kenali" lesson of the Hangul course.
const hangulPerIntro = 6;

/// Builds the Hangul course: one unit per group in content/korean/hangul.json
/// ([units], in course order), letters before syllables, at most
/// [hangulPerIntro] per lesson, then Memory Match, a chest and a Speed Drill
/// over everything learned so far. Hangul has no stroke data, so no writing.
/// Node ids use the unit key ("hangul-vowels-intro-0") so they stay put when
/// units are added.
List<PathUnit> buildHangulPath(List<Kana> all, Map<String, Localized> units) {
  final out = <PathUnit>[];
  final learned = <Kana>[];
  for (final MapEntry(:key, value: title) in units.entries) {
    final unitKana = [
      for (final k in all)
        if (k.rowGroup == key) k,
    ];
    if (unitKana.isEmpty) continue;
    final unitId = 'hangul-$key';
    final syllables = unitKana.where((k) => k.kind == 'syllable' || k.kind == 'final').toList();
    final letters = unitKana.where((k) => !syllables.contains(k)).toList();
    final intros = <PathNode>[];
    for (final group in [...splitEvenly(letters, hangulPerIntro), ...splitEvenly(syllables, hangulPerIntro)]) {
      learned.addAll(group);
      intros.add(
        PathNode(
          id: '$unitId-intro-${intros.length}',
          type: NodeType.intro,
          items: group,
          reviewPool: List.unmodifiable(learned),
        ),
      );
    }
    final pool = List<Kana>.unmodifiable(learned);
    out.add(
      PathUnit(
        id: unitId,
        number: out.length + 1,
        script: 'hangul',
        rows: [key],
        title: title,
        nodes: [
          ...intros,
          PathNode(id: '$unitId-match', type: NodeType.match, items: unitKana, reviewPool: pool),
          PathNode(id: '$unitId-chest', type: NodeType.chest, items: const [], reviewPool: pool),
          PathNode(id: '$unitId-speed', type: NodeType.speed, items: unitKana, reviewPool: pool),
        ],
      ),
    );
  }
  return out;
}

/// [w] as a dictionary word for the shared lessons: its meaning in
/// [language] ('id' or 'en'), no JLPT level.
DictWord koDictWord(KoWord w, String language) =>
    DictWord(id: w.id, kana: w.hangul, romaji: w.romaja, jlpt: 0, gloss: w.meaning.of(language));

/// Builds the Korean vocabulary course: one or more units per topic
/// ([topics], in course order), lessons of about [wordsPerLesson] words,
/// [lessonsPerUnit] a unit, then a unit review and a chest. Meanings are in
/// [language]. Like the Japanese vocabulary, nothing is locked.
List<PathUnit> buildKoreanVocabPath(List<KoWord> words, Map<String, Localized> topics, {required String language}) {
  final out = <PathUnit>[];
  final learned = <VocabWord>[];
  for (final MapEntry(:key, value: title) in topics.entries) {
    final lessons = splitEvenly([
      for (final w in words)
        if (w.topic == key) VocabWord(koDictWord(w, language)),
    ], wordsPerLesson);
    for (var start = 0; start < lessons.length; start += lessonsPerUnit) {
      final unitId = 'ko-$key-u${start ~/ lessonsPerUnit + 1}';
      final intros = <PathNode>[];
      for (final (i, group) in lessons.skip(start).take(lessonsPerUnit).indexed) {
        learned.addAll(group);
        intros.add(
          PathNode(id: '$unitId-intro-$i', type: NodeType.intro, items: group, reviewPool: List.unmodifiable(learned)),
        );
      }
      final pool = List<VocabWord>.unmodifiable(learned);
      out.add(
        PathUnit(
          id: unitId,
          number: out.length + 1,
          script: 'ko_vocab',
          theme: key,
          title: title,
          nodes: [
            ...intros,
            PathNode(
              id: '$unitId-review',
              type: NodeType.review,
              items: [for (final n in intros) ...n.items],
              reviewPool: pool,
            ),
            PathNode(id: '$unitId-chest', type: NodeType.chest, items: const [], reviewPool: pool),
          ],
        ),
      );
    }
  }
  return out;
}
