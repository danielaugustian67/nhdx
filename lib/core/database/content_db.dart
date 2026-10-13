import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

/// A character taught by a course: a kana or a kanji. Ids are codepoints
/// (yōon combine two), so kana and kanji never collide in progress maps.
abstract interface class Glyph {
  int get id;
  String get literal;
}

/// One row of the kana table (PRD §9.B).
class Kana implements Glyph {
  const Kana({
    required this.id,
    required this.literal,
    required this.script,
    required this.romaji,
    required this.rowGroup,
    required this.kind,
    required this.orderNo,
    this.exampleWordId,
  });

  @override
  final int id;
  @override
  final String literal;

  /// 'hiragana' | 'katakana' | 'hangul'
  final String script;

  /// Romaji; Revised Romanization for Hangul.
  final String romaji;

  /// Gojūon row: a, ka, sa, … (yōon use the row of their first kana).
  /// Hangul: the unit key ("vowels", …).
  final String rowGroup;

  /// 'basic' | 'dakuten' | 'handakuten' | 'yoon'; Hangul: 'vowel' |
  /// 'consonant' | 'syllable' | 'final'.
  final String kind;
  final int orderNo;
  final int? exampleWordId;

  bool get isYoon => kind == 'yoon';

  bool get isHangul => script == 'hangul';

  @override
  bool operator ==(Object other) => other is Kana && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Kana($literal)';
}

/// One kanji of the kanji course (KANJIDIC2, N5 to N1), in course order.
class Kanji implements Glyph {
  const Kanji({
    required this.id,
    required this.literal,
    required this.jlpt,
    this.grade,
    required this.strokeCount,
    required this.meanings,
    required this.onyomi,
    required this.kunyomi,
    required this.theme,
    required this.orderNo,
  });

  @override
  final int id;
  @override
  final String literal;

  /// 5 = N5 … 1 = N1
  final int jlpt;
  final int? grade;
  final int strokeCount;

  /// English meanings, most important first.
  final List<String> meanings;

  /// Katakana, e.g. イチ.
  final List<String> onyomi;

  /// Hiragana with okurigana after '.', e.g. ひと.つ.
  final List<String> kunyomi;

  /// Theme key from data_pipeline/scripts/kanji_themes.py ("numbers",
  /// "week", …); one path unit per theme. Empty for N3 to N1.
  final String theme;
  final int orderNo;

  String get meaning => meanings.isEmpty ? '' : meanings.first;

  @override
  bool operator ==(Object other) => other is Kanji && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Kanji($literal)';
}

/// Text in Indonesian and English; [of] picks the app language.
class Localized {
  const Localized(this.id, this.en);
  final String id;
  final String en;

  String of(String localeName) => localeName.startsWith('id') ? id : en;

  static Localized parse(Object? json) {
    final m = (json as Map?) ?? const {};
    return Localized('${m['id'] ?? ''}', '${m['en'] ?? ''}');
  }
}

/// An example sentence of a grammar point. [chunks] spell [japanese]
/// without its final punctuation, for the sentence-building exercise.
class GrammarExample {
  const GrammarExample({required this.japanese, required this.kana, required this.translation, this.chunks = const []});
  final String japanese;
  final String kana;
  final Localized translation;
  final List<String> chunks;
}

/// A fill-the-gap question: [question] has one ＿＿, [options][answer] fills it.
class GrammarQuiz {
  const GrammarQuiz({required this.question, required this.options, required this.answer, required this.translation});
  final String question;
  final List<String> options;
  final int answer;
  final Localized translation;

  static const gap = '＿＿';
}

/// One grammar point (PRD F13), from content/grammar/n*.json.
class GrammarPoint {
  const GrammarPoint({
    required this.id,
    required this.jlpt,
    required this.orderNo,
    required this.pattern,
    required this.formation,
    required this.meaning,
    required this.explanation,
    required this.examples,
    required this.quiz,
  });

  /// 'n5-wa-desu'; also the SRS item id of its `grammar` card.
  final String id;
  final int jlpt;
  final int orderNo;
  final String pattern;
  final String formation;
  final Localized meaning;
  final Localized explanation;
  final List<GrammarExample> examples;
  final List<GrammarQuiz> quiz;

  @override
  String toString() => 'GrammarPoint($id)';
}

/// Ids of Korean words start here, far above the JMdict ids they share
/// progress maps with.
const koWordIdBase = 90000000;

/// A basic Korean word (TOPIK I) of the Korean course, from
/// content/korean/words.json.
class KoWord {
  const KoWord({
    required this.id,
    required this.hangul,
    required this.romaja,
    required this.meaning,
    required this.topic,
    required this.orderNo,
  });

  /// [koWordIdBase] + a hash of [hangul]; also the SRS item id of its
  /// `ko_word` card.
  final int id;
  final String hangul;

  /// Revised Romanization as pronounced ("hangugeo").
  final String romaja;
  final Localized meaning;

  /// Key of its topic in [ContentDb.koreanGroups].
  final String topic;
  final int orderNo;

  @override
  String toString() => 'KoWord($hangul)';
}

/// Read-only access to `content.db` (kana, KanjiVG strokes, curriculum).
class ContentDb {
  ContentDb._(this._db);

  final Database _db;

  factory ContentDb.open(String path) => ContentDb._(sqlite3.open(path, mode: OpenMode.readOnly));

  String? meta(String key) {
    final rows = _db.select('SELECT value FROM meta WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  List<Kana> kana({String? script}) {
    final rows = _db.select(
      'SELECT id, literal, script, romaji, row_group, kind, order_no, example_word_id FROM kana '
      '${script == null ? '' : 'WHERE script = ?'} ORDER BY script, order_no',
      [?script],
    );
    return [
      for (final r in rows)
        Kana(
          id: r['id'] as int,
          literal: r['literal'] as String,
          script: r['script'] as String,
          romaji: r['romaji'] as String,
          rowGroup: r['row_group'] as String,
          kind: r['kind'] as String,
          orderNo: r['order_no'] as int,
          exampleWordId: r['example_word_id'] as int?,
        ),
    ];
  }

  /// The kanji course, easiest first. Empty for a content.db built before
  /// the kanji table existed.
  List<Kanji> kanji() {
    final hasTable = _db.select("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'kanji'").isNotEmpty;
    if (!hasTable) return const [];
    List<String> split(Object? v, String sep) =>
        (v as String?)?.split(sep).where((s) => s.isNotEmpty).toList() ?? const [];
    return [
      for (final r in _db.select(
        'SELECT id, literal, jlpt_level, grade, stroke_count, meanings_en, onyomi, kunyomi, theme, order_no '
        'FROM kanji ORDER BY order_no',
      ))
        Kanji(
          id: r['id'] as int,
          literal: r['literal'] as String,
          jlpt: r['jlpt_level'] as int,
          grade: r['grade'] as int?,
          strokeCount: r['stroke_count'] as int,
          meanings: split(r['meanings_en'], '; '),
          onyomi: split(r['onyomi'], '、'),
          kunyomi: split(r['kunyomi'], '、'),
          theme: r['theme'] as String,
          orderNo: r['order_no'] as int,
        ),
    ];
  }

  /// Grammar points, N5 first, in authored order. Empty for a content.db
  /// built before the grammar table existed.
  List<GrammarPoint> grammar() {
    final hasTable = _db.select("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'grammar'").isNotEmpty;
    if (!hasTable) return const [];
    return [
      for (final r in _db.select(
        'SELECT id, jlpt_level, order_no, pattern, formation, meaning, explanation, examples, quiz '
        'FROM grammar ORDER BY jlpt_level DESC, order_no',
      ))
        GrammarPoint(
          id: r['id'] as String,
          jlpt: r['jlpt_level'] as int,
          orderNo: r['order_no'] as int,
          pattern: r['pattern'] as String,
          formation: r['formation'] as String,
          meaning: Localized.parse(jsonDecode(r['meaning'] as String)),
          explanation: Localized.parse(jsonDecode(r['explanation'] as String)),
          examples: [
            for (final e in jsonDecode(r['examples'] as String) as List)
              GrammarExample(
                japanese: e['ja'] as String,
                kana: e['kana'] as String,
                translation: Localized.parse(e['tr']),
                chunks: [for (final c in (e['chunks'] as List? ?? const [])) c as String],
              ),
          ],
          quiz: [
            for (final q in jsonDecode(r['quiz'] as String) as List)
              GrammarQuiz(
                question: q['q'] as String,
                options: [for (final o in q['options'] as List) o as String],
                answer: q['answer'] as int,
                translation: Localized.parse(q['tr']),
              ),
          ],
        ),
    ];
  }

  bool _hasTable(String name) =>
      _db.select("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?", [name]).isNotEmpty;

  /// Hangul letters and syllables of the Korean course, in course order
  /// (script 'hangul'). Empty for a content.db built before Korean.
  List<Kana> hangul() {
    if (!_hasTable('hangul')) return const [];
    return [
      for (final r in _db.select('SELECT id, literal, romaji, unit, kind, order_no FROM hangul ORDER BY order_no'))
        Kana(
          id: r['id'] as int,
          literal: r['literal'] as String,
          script: 'hangul',
          romaji: r['romaji'] as String,
          rowGroup: r['unit'] as String,
          kind: r['kind'] as String,
          orderNo: r['order_no'] as int,
        ),
    ];
  }

  /// Korean words by topic, in authored order.
  List<KoWord> koreanWords() {
    if (!_hasTable('ko_words')) return const [];
    return [
      for (final r in _db.select('SELECT id, hangul, romaja, meaning, topic, order_no FROM ko_words ORDER BY order_no'))
        KoWord(
          id: r['id'] as int,
          hangul: r['hangul'] as String,
          romaja: r['romaja'] as String,
          meaning: Localized.parse(jsonDecode(r['meaning'] as String)),
          topic: r['topic'] as String,
          orderNo: r['order_no'] as int,
        ),
    ];
  }

  /// Titles of the Hangul units ([kind] 'hangul') or word topics ('words'),
  /// by key, in course order.
  Map<String, Localized> koreanGroups(String kind) {
    if (!_hasTable('ko_groups')) return const {};
    return {
      for (final r in _db.select('SELECT key, title FROM ko_groups WHERE kind = ? ORDER BY order_no', [kind]))
        r['key'] as String: Localized.parse(jsonDecode(r['title'] as String)),
    };
  }

  /// KanjiVG stroke paths (109×109 coordinate box) in stroke order.
  List<String> strokes(String character) {
    final rows = _db.select('SELECT svg_path FROM char_strokes WHERE codepoint = ? ORDER BY stroke_no', [
      character.runes.first,
    ]);
    return [for (final r in rows) r['svg_path'] as String];
  }

  void close() => _db.close();
}
