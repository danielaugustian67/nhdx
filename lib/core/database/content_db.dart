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

  /// 'hiragana' | 'katakana'
  final String script;
  final String romaji;

  /// Gojūon row: a, ka, sa, … (yōon use the row of their first kana).
  final String rowGroup;

  /// 'basic' | 'dakuten' | 'handakuten' | 'yoon'
  final String kind;
  final int orderNo;
  final int? exampleWordId;

  bool get isYoon => kind == 'yoon';

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

  /// KanjiVG stroke paths (109×109 coordinate box) in stroke order.
  List<String> strokes(String character) {
    final rows = _db.select('SELECT svg_path FROM char_strokes WHERE codepoint = ? ORDER BY stroke_no', [
      character.runes.first,
    ]);
    return [for (final r in rows) r['svg_path'] as String];
  }

  void close() => _db.close();
}
