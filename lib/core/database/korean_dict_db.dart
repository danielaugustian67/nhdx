import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import 'dictionary_db.dart';

/// Read-only access to `korean.db`, the Korean dictionary (English Wiktionary
/// plus the course words, `data_pipeline/scripts/build_korean_dict.py`).
/// Word ids are at least [koWordIdBase]; a course word has its course id.
class KoreanDictDb {
  KoreanDictDb._(this.db);

  final Database db;

  factory KoreanDictDb.open(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    // Fail fast if the file is not a pipeline-built Korean dictionary.
    db.select("SELECT rowid FROM words_fts WHERE words_fts MATCH 'water' LIMIT 1");
    return KoreanDictDb._(db);
  }

  static const _briefColumns = 'id, hangul, romaja, gloss, gloss_id';

  /// Everything the Korean word page shows, or null if the id is unknown.
  KoEntry? entry(int id) {
    final rows = db.select('SELECT * FROM words WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return KoEntry(
      id: id,
      hangul: r['hangul'] as String,
      romaja: r['romaja'] as String,
      hanja: r['hanja'] as String?,
      gloss: r['gloss'] as String,
      glossId: r['gloss_id'] as String?,
      topic: r['topic'] as String?,
      senses: [
        for (final s in jsonDecode(r['senses'] as String) as List)
          KoSense(
            pos: (s as Map)['pos'] as String?,
            hanja: s['hanja'] as String?,
            glosses: [for (final g in s['glosses'] as List) g as String],
          ),
      ],
    );
  }

  /// List rows for the given ids (collection); missing ids are left out.
  /// [language] picks the Indonesian meaning where there is one.
  Map<int, WordBrief> briefs(Iterable<int> ids, {String language = 'en'}) {
    final list = ids.toSet().toList();
    if (list.isEmpty) return const {};
    final rows = db.select(
      'SELECT $_briefColumns FROM words WHERE id IN (${List.filled(list.length, '?').join(',')})',
      list,
    );
    return {for (final r in rows) r['id'] as int: _brief(r, language)};
  }

  /// One course word per study date, the same all day.
  WordBrief? wordOfTheDay(String date, {String language = 'en'}) {
    final count = db.select('SELECT count(*) AS n FROM words WHERE topic IS NOT NULL').first['n'] as int;
    if (count == 0) return null;
    var h = 0;
    for (final unit in date.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    final rows = db.select('SELECT $_briefColumns FROM words WHERE topic IS NOT NULL ORDER BY id LIMIT 1 OFFSET ?', [
      h % count,
    ]);
    return rows.isEmpty ? null : _brief(rows.first, language);
  }

  /// The course words of one topic, in rank order.
  List<WordBrief> topicWords(String topic, {String language = 'en'}) => [
    for (final r in db.select('SELECT $_briefColumns FROM words WHERE topic = ? ORDER BY rank', [topic]))
      _brief(r, language),
  ];

  static WordBrief _brief(Row r, String language) => WordBrief(
    id: r['id'] as int,
    kanji: null,
    kana: r['hangul'] as String,
    romaji: r['romaja'] as String,
    jlpt: null,
    gloss: language == 'id' ? (r['gloss_id'] as String? ?? r['gloss'] as String) : r['gloss'] as String,
  );

  void close() => db.close();
}

/// A Korean dictionary word: Hangul headword, romanization, hanja and its
/// meaning groups (one per homonym or part of speech).
class KoEntry {
  const KoEntry({
    required this.id,
    required this.hangul,
    required this.romaja,
    required this.hanja,
    required this.gloss,
    required this.glossId,
    required this.topic,
    required this.senses,
  });

  final int id;
  final String hangul;

  /// Revised Romanization as pronounced.
  final String romaja;
  final String? hanja;

  /// Short English meaning.
  final String gloss;

  /// Indonesian meaning, for course words.
  final String? glossId;

  /// Course topic key; null outside the course.
  final String? topic;
  final List<KoSense> senses;

  bool get inCourse => topic != null;

  /// The short meaning in [language] ('id' or 'en').
  String meaning(String language) => language == 'id' ? (glossId ?? gloss) : gloss;
}

class KoSense {
  const KoSense({required this.pos, required this.hanja, required this.glosses});

  /// Wiktionary part of speech (noun, verb, adj, …); null for a course word
  /// Wiktionary does not have.
  final String? pos;
  final String? hanja;
  final List<String> glosses;
}
