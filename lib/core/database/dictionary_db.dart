import 'package:sqlite3/common.dart';

import 'content_db.dart';
import 'sqlite_platform.dart';

/// Read-only access to `dictionary.db` (PRD §9.A).
///
/// SQLite is bundled by `package:sqlite3` (build hooks), not taken from the
/// OS, so FTS5 and the trigram tokenizer are always available (PRD §6).
class DictionaryDb {
  DictionaryDb._(this.db);

  final CommonDatabase db;

  /// Minimum SQLite version for the FTS5 trigram tokenizer.
  static const minSqlite = 3034000;

  factory DictionaryDb.open(String path) => DictionaryDb.of(openReadOnly(path));

  factory DictionaryDb.of(CommonDatabase db) {
    if (sqliteVersionNumber < minSqlite) {
      throw StateError('SQLite $sqliteVersionNumber is too old for FTS5 trigram (need ≥ 3.34)');
    }
    // Fail fast if the file is not a pipeline-built dictionary or FTS5 is missing.
    db.select("SELECT rowid FROM words_fts_jp WHERE words_fts_jp MATCH '\"たべる\"' LIMIT 1");
    return DictionaryDb._(db);
  }

  /// Headword, reading and first meaning of one entry (kana example words).
  ({String headword, String kana, String gloss})? brief(int wordId) {
    final rows = db.select(
      'SELECT coalesce(w.primary_kanji, w.primary_kana) AS headword, w.primary_kana AS kana, '
      '       (SELECT s.gloss_en FROM word_senses s '
      '         WHERE s.word_id = w.id ORDER BY s.sense_no LIMIT 1) AS gloss '
      'FROM words w WHERE w.id = ?',
      [wordId],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return (headword: r['headword'] as String, kana: r['kana'] as String, gloss: (r['gloss'] as String?) ?? '');
  }

  /// Everything the word detail page shows (PRD F2), or null if the id is not
  /// in this dataset (e.g. a bookmark of a removed entry).
  WordEntry? entry(int wordId) {
    final words = db.select(
      'SELECT id, primary_kanji, primary_kana, romaji, jlpt_level, is_common, verb_group, adj_type '
      'FROM words WHERE id = ?',
      [wordId],
    );
    if (words.isEmpty) return null;
    final w = words.first;
    final forms = db.select('SELECT kind, text, is_common FROM word_forms WHERE word_id = ? ORDER BY ord', [wordId]);
    final senses = db.select('SELECT sense_no, pos, gloss_en FROM word_senses WHERE word_id = ? ORDER BY sense_no', [
      wordId,
    ]);
    final codes = {for (final s in senses) ...((s['pos'] as String?) ?? '').split(';').where((c) => c.isNotEmpty)};
    final labels = codes.isEmpty
        ? const <String, String>{}
        : {
            for (final r in db.select(
              'SELECT code, label_en FROM pos_tags WHERE code IN (${List.filled(codes.length, '?').join(',')})',
              codes.toList(),
            ))
              r['code'] as String: r['label_en'] as String,
          };
    return WordEntry(
      id: wordId,
      kanji: w['primary_kanji'] as String?,
      kana: w['primary_kana'] as String,
      romaji: w['romaji'] as String,
      jlpt: w['jlpt_level'] as int?,
      isCommon: w['is_common'] == 1,
      verbGroup: w['verb_group'] as String?,
      adjType: w['adj_type'] as String?,
      posCodes: {
        for (final s in senses)
          for (final c in ((s['pos'] as String?) ?? '').split(';'))
            if (c.isNotEmpty) c,
      }.toList(),
      kanjiForms: [
        for (final f in forms)
          if (f['kind'] == 'kanji') f['text'] as String,
      ],
      kanaForms: [
        for (final f in forms)
          if (f['kind'] == 'kana') f['text'] as String,
      ],
      senses: [
        for (final s in senses)
          WordSense(
            number: s['sense_no'] as int,
            pos: [
              for (final c in ((s['pos'] as String?) ?? '').split(';'))
                if (c.isNotEmpty) labels[c] ?? c,
            ],
            gloss: s['gloss_en'] as String,
          ),
      ],
    );
  }

  /// List rows for the given ids (collection); missing ids are left out.
  Map<int, WordBrief> briefs(Iterable<int> ids) {
    final list = ids.toSet().toList();
    if (list.isEmpty) return const {};
    final rows = db.select(
      'SELECT w.id, w.primary_kanji, w.primary_kana, w.romaji, w.jlpt_level, '
      '       (SELECT s.gloss_en FROM word_senses s WHERE s.word_id = w.id ORDER BY s.sense_no LIMIT 1) AS gloss '
      'FROM words w WHERE w.id IN (${List.filled(list.length, '?').join(',')})',
      list,
    );
    return {
      for (final r in rows)
        r['id'] as int: WordBrief(
          id: r['id'] as int,
          kanji: r['primary_kanji'] as String?,
          kana: r['primary_kana'] as String,
          romaji: r['romaji'] as String,
          jlpt: r['jlpt_level'] as int?,
          gloss: (r['gloss'] as String?) ?? '',
        ),
    };
  }

  /// Words of one JLPT level for browsing, most common first.
  List<WordBrief> levelWords(int level, {int limit = 50, int offset = 0}) => [
    for (final r in db.select(
      'SELECT w.id, w.primary_kanji, w.primary_kana, w.romaji, '
      '       (SELECT s.gloss_en FROM word_senses s WHERE s.word_id = w.id ORDER BY s.sense_no LIMIT 1) AS gloss '
      'FROM words w WHERE w.jlpt_level = ? '
      'ORDER BY w.is_common DESC, coalesce(w.freq_rank, 1000000), w.id LIMIT ? OFFSET ?',
      [level, limit, offset],
    ))
      WordBrief(
        id: r['id'] as int,
        kanji: r['primary_kanji'] as String?,
        kana: r['primary_kana'] as String,
        romaji: r['romaji'] as String,
        jlpt: level,
        gloss: (r['gloss'] as String?) ?? '',
      ),
  ];

  int levelCount(int level) =>
      db.select('SELECT count(*) AS n FROM words WHERE jlpt_level = ?', [level]).first['n'] as int;

  /// A common JLPT word that changes once a day ("Kata hari ini").
  WordBrief? wordOfTheDay(String date) {
    final pool = db.select('SELECT count(*) AS n FROM words WHERE jlpt_level >= 3 AND is_common = 1').first['n'] as int;
    if (pool == 0) return null;
    // String.hashCode is not stable across runs; this one is.
    final offset = date.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff) % pool;
    final r = db.select(
      'SELECT w.id, w.primary_kanji, w.primary_kana, w.romaji, w.jlpt_level, '
      '       (SELECT s.gloss_en FROM word_senses s WHERE s.word_id = w.id ORDER BY s.sense_no LIMIT 1) AS gloss '
      'FROM words w WHERE w.jlpt_level >= 3 AND w.is_common = 1 ORDER BY w.id LIMIT 1 OFFSET ?',
      [offset],
    ).first;
    return WordBrief(
      id: r['id'] as int,
      kanji: r['primary_kanji'] as String?,
      kana: r['primary_kana'] as String,
      romaji: r['romaji'] as String,
      jlpt: r['jlpt_level'] as int?,
      gloss: (r['gloss'] as String?) ?? '',
    );
  }

  /// JLPT words for kana and kanji lessons, easiest and most frequent first,
  /// one row per (kana, kanji) spelling. Callers keep only the words they can
  /// spell with what was learned so far.
  List<DictWord> jlptWords({int maxLength = 6}) {
    final rows = db.select(
      'SELECT w.id, w.primary_kana AS kana, w.primary_kanji AS kanji, w.romaji, w.jlpt_level, '
      '       (SELECT s.gloss_en FROM word_senses s '
      '         WHERE s.word_id = w.id ORDER BY s.sense_no LIMIT 1) AS gloss '
      'FROM words w '
      'WHERE w.jlpt_level IS NOT NULL AND w.primary_kana IS NOT NULL AND length(w.primary_kana) <= ? '
      'ORDER BY w.jlpt_level DESC, coalesce(w.freq_rank, 1000000), w.id',
      [maxLength],
    );
    final seen = <String>{};
    return [
      for (final r in rows)
        if (seen.add('${r['kana']}|${r['kanji']}'))
          DictWord(
            id: r['id'] as int,
            kana: r['kana'] as String,
            kanji: r['kanji'] as String?,
            romaji: (r['romaji'] as String?) ?? '',
            jlpt: r['jlpt_level'] as int,
            gloss: _shortGloss((r['gloss'] as String?) ?? ''),
          ),
    ];
  }

  /// JLPT verbs and adjectives of [levels] (conjugation drill), most
  /// frequent first, each with the part-of-speech codes of all its senses.
  /// Words usually written in kana come without their rare kanji.
  List<({DictWord word, List<String> pos})> conjugableWords(List<int> levels) {
    if (levels.isEmpty) return const [];
    final rows = db.select(
      'SELECT w.id, w.primary_kana AS kana, w.romaji, w.jlpt_level, '
      // Usually written in kana (呉れる → くれる): an uncommon kanji spelling of a common kana word.
      "       CASE WHEN (SELECT f.is_common FROM word_forms f WHERE f.word_id = w.id AND f.kind = 'kanji' "
      '                  AND f.text = w.primary_kanji LIMIT 1) = 0 '
      "             AND (SELECT f.is_common FROM word_forms f WHERE f.word_id = w.id AND f.kind = 'kana' "
      '                  AND f.text = w.primary_kana LIMIT 1) = 1 THEN NULL ELSE w.primary_kanji END AS kanji, '
      '       (SELECT s.gloss_en FROM word_senses s WHERE s.word_id = w.id ORDER BY s.sense_no LIMIT 1) AS gloss, '
      "       (SELECT group_concat(s.pos, ';') FROM word_senses s WHERE s.word_id = w.id) AS pos "
      'FROM words w '
      'WHERE w.jlpt_level IN (${List.filled(levels.length, '?').join(',')}) '
      "  AND EXISTS (SELECT 1 FROM word_senses s WHERE s.word_id = w.id AND (s.pos LIKE '%v%' OR s.pos LIKE '%adj%')) "
      'ORDER BY w.jlpt_level DESC, coalesce(w.freq_rank, 1000000), w.id',
      levels,
    );
    return [
      for (final r in rows)
        (
          word: DictWord(
            id: r['id'] as int,
            kana: r['kana'] as String,
            kanji: r['kanji'] as String?,
            romaji: (r['romaji'] as String?) ?? '',
            jlpt: r['jlpt_level'] as int,
            gloss: _shortGloss((r['gloss'] as String?) ?? ''),
          ),
          pos: ((r['pos'] as String?) ?? '').split(';').where((c) => c.isNotEmpty).toSet().toList(),
        ),
    ];
  }

  /// "good; excellent; fine; nice" → "good, excellent"
  static String _shortGloss(String gloss) => gloss.split('; ').take(2).join(', ');

  String? meta(String key) {
    final rows = db.select('SELECT value FROM meta WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  void close() => db.close();
}

/// One dictionary entry for the detail page.
class WordEntry {
  const WordEntry({
    required this.id,
    required this.kanji,
    required this.kana,
    required this.romaji,
    required this.jlpt,
    required this.isCommon,
    required this.verbGroup,
    required this.adjType,
    this.posCodes = const [],
    required this.kanjiForms,
    required this.kanaForms,
    required this.senses,
  });

  final int id;
  final String? kanji;
  final String kana;
  final String romaji;
  final int? jlpt;
  final bool isCommon;

  /// godan | ichidan | irregular
  final String? verbGroup;

  /// i | na | no | taru
  final String? adjType;

  /// JMdict part-of-speech codes of all senses (`v5k`, `adj-i`, …), for
  /// conjugation.
  final List<String> posCodes;

  /// All spellings, primary first.
  final List<String> kanjiForms;
  final List<String> kanaForms;
  final List<WordSense> senses;

  String get headword => kanji ?? kana;
}

class WordSense {
  const WordSense({required this.number, required this.pos, required this.gloss});

  /// 1-based sense order (shown, since it is a real order).
  final int number;

  /// Part-of-speech labels (JMdict, English).
  final List<String> pos;

  /// "; "-separated English glosses.
  final String gloss;
}

/// Headword, reading and first meaning, for lists.
class WordBrief {
  const WordBrief({
    required this.id,
    required this.kanji,
    required this.kana,
    required this.romaji,
    required this.jlpt,
    required this.gloss,
  });

  final int id;
  final String? kanji;
  final String kana;
  final String romaji;
  final int? jlpt;
  final String gloss;

  String get headword => kanji ?? kana;
}

/// A dictionary word as used in lessons.
class DictWord {
  const DictWord({
    required this.id,
    required this.kana,
    this.kanji,
    required this.romaji,
    required this.jlpt,
    required this.gloss,
  });

  final int id;
  final String kana;
  final String? kanji;

  /// Hepburn without macrons ("ookii").
  final String romaji;

  /// 5 = N5 … 1 = N1
  final int jlpt;

  /// First meaning, at most two glosses.
  final String gloss;

  /// A word of the Korean course dressed as a dictionary word: [kana] is
  /// the Hangul, [romaji] the romanization, [jlpt] 0.
  bool get isKorean => id >= koWordIdBase;

  @override
  String toString() => 'DictWord($kana)';
}
