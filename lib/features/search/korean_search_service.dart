import 'package:sqlite3/sqlite3.dart';

import '../../core/database/korean_dict_db.dart';
import '../../core/text/hangul.dart';
import 'search_service.dart';

/// Korean dictionary search over korean.db, the Korean twin of
/// [SearchService].
///
/// Tiers (lower ranks first):
///   0 exact Hangul / exact romanization · 1 Hangul prefix
///   2 Hangul inside the word · 2 exact main meaning (the short meaning shown
///   in results) · 3 exact meaning further down · 4 romanization prefix
///   5 meaning word · 6 meaning prefix
/// Tie-breakers: course words → earliest matching meaning (not for main
/// meanings, which are all first) → the word's rank (the better kept
/// Wiktionary entries first).
class KoreanSearchService {
  KoreanSearchService(this._dict);

  final KoreanDictDb _dict;

  static const maxCandidates = 300;
  static final _brackets = RegExp(r'\([^)]*\)|\[[^\]]*\]');
  static final _space = RegExp(r'\s+');
  static final _notLatin = RegExp('[^a-z]');
  static final _token = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final _parts = RegExp('[;,/]');

  Database get _db => _dict.db;

  /// Meaning as stored in `glosses.text`: lower case, no brackets.
  static String normGloss(String text) =>
      text.toLowerCase().replaceAll(_brackets, '').replaceAll(_space, ' ').replaceAll(RegExp(r'^[ .;,]+|[ .;,]+$'), '');

  /// A meaning and, for "to eat", "eat".
  static Set<String> _keys(String meaning) => {
    meaning,
    if (meaning.startsWith('to ') && meaning.length > 4) meaning.substring(3),
  };

  /// Exact keys of a word's short meanings, English and Indonesian.
  static Iterable<String> _main(Row r) sync* {
    for (final gloss in [r['gloss'] as String, ?(r['gloss_id'] as String?)]) {
      for (final part in gloss.split(_parts)) {
        yield* _keys(normGloss(part));
      }
    }
  }

  List<SearchHit> search(String query, {String language = 'en', int limit = 50}) {
    final tiers = <int, int>{};
    final senseRank = <int, int>{};

    void add(ResultSet rows, int tier) {
      for (final row in rows) {
        final id = row['id'] as int;
        final current = tiers[id];
        if (current == null || tier < current) tiers[id] = tier;
        if (row.containsKey('sense_no')) {
          final sense = row['sense_no'] as int;
          if (sense < (senseRank[id] ?? 1 << 30)) senseRank[id] = sense;
        }
      }
    }

    final text = query.trim();
    if (text.isEmpty) return const [];
    // Exact meaning keys of a Latin query; empty for Hangul.
    var keys = const <String>{};
    if (hasHangul(text)) {
      add(_db.select('SELECT id FROM words WHERE hangul = ?', [text]), 0);
      add(
        _db.select('SELECT id FROM words WHERE hangul >= ? AND hangul < ? LIMIT ?', [
          text,
          '$text\u{10FFFF}',
          maxCandidates,
        ]),
        1,
      );
      add(_db.select("SELECT id FROM words WHERE instr(hangul, ?) > 1 LIMIT ?", [text, maxCandidates]), 2);
    } else {
      final romaja = text.toLowerCase().replaceAll(_notLatin, '');
      if (romaja.isNotEmpty) {
        add(_db.select('SELECT id FROM words WHERE romaja_search = ? OR romaja_alt = ?', [romaja, romaja]), 0);
        if (romaja.length >= 2) {
          add(
            _db.select('SELECT id FROM words WHERE romaja_search >= ? AND romaja_search < ? LIMIT ?', [
              romaja,
              '$romaja{',
              maxCandidates,
            ]),
            4,
          );
        }
      }
      final meaning = normGloss(text);
      if (meaning.length >= 2) {
        keys = _keys(meaning);
        for (final key in keys) {
          add(
            _db.select('SELECT word_id AS id, sense_no FROM glosses WHERE text = ? LIMIT ?', [key, maxCandidates]),
            2,
          );
        }
        final tokens = meaning.split(_token).where((t) => t.isNotEmpty).toList();
        if (tokens.isNotEmpty) {
          final phrase = tokens.map((t) => '"$t"').join(' ');
          add(
            _db.select('SELECT rowid AS id FROM words_fts WHERE words_fts MATCH ? LIMIT ?', [phrase, maxCandidates]),
            5,
          );
          if (tokens.last.length >= 3) {
            add(
              _db.select('SELECT rowid AS id FROM words_fts WHERE words_fts MATCH ? LIMIT ?', [
                '$phrase*',
                maxCandidates,
              ]),
              6,
            );
          }
        }
      }
    }
    if (tiers.isEmpty) return const [];

    final ids = tiers.keys.toList();
    final rows = {
      for (final r in _db.select(
        'SELECT id, hangul, romaja, gloss, gloss_id, topic, rank FROM words '
        'WHERE id IN (${List.filled(ids.length, '?').join(',')})',
        ids,
      ))
        r['id'] as int: r,
    };
    // An exact meaning only further down (하다 "to eat" as its sixth
    // meaning) ranks below words that mean it first.
    if (keys.isNotEmpty) {
      for (final id in ids) {
        final r = rows[id];
        if (tiers[id] == 2 && r != null && !_main(r).any(keys.contains)) tiers[id] = 3;
      }
    }
    ids.sort((a, b) {
      final byTier = tiers[a]!.compareTo(tiers[b]!);
      if (byTier != 0) return byTier;
      // A course word's English meaning comes after its Indonesian one, so
      // its sense number would put it behind rarer synonyms.
      final byCourse = (rows[a]?['topic'] == null ? 1 : 0).compareTo(rows[b]?['topic'] == null ? 1 : 0);
      if (byCourse != 0) return byCourse;
      if (tiers[a] != 2) {
        final bySense = (senseRank[a] ?? 1 << 30).compareTo(senseRank[b] ?? 1 << 30);
        if (bySense != 0) return bySense;
      }
      return (rows[a]?['rank'] as int? ?? 1 << 30).compareTo(rows[b]?['rank'] as int? ?? 1 << 30);
    });
    return [
      for (final id in ids.take(limit))
        if (rows[id] case final r?)
          SearchHit(
            wordId: id,
            kanji: null,
            kana: r['hangul'] as String,
            romaji: r['romaja'] as String,
            gloss: language == 'id' ? (r['gloss_id'] as String? ?? r['gloss'] as String) : r['gloss'] as String,
            jlptLevel: null,
            isCommon: r['topic'] != null,
            isExact: tiers[id] == 0,
          ),
    ];
  }
}
