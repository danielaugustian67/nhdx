import 'package:sqlite3/sqlite3.dart';

import '../../core/database/dictionary_db.dart';
import '../../core/text/normalize.dart';
import '../../core/text/romaji_to_kana.dart';

/// Search mode chips in the search field (ui-design §4.5).
enum SearchMode {
  /// Latin input is converted to hiragana and also searched as a meaning.
  hiragana,

  /// Same as [hiragana]; only the field preview shows katakana.
  katakana,

  /// "Cari sebagai teks latin": meanings only, no romaji conversion.
  latin,
}

class SearchHit {
  const SearchHit({
    required this.wordId,
    required this.kanji,
    required this.kana,
    required this.romaji,
    required this.gloss,
    required this.jlptLevel,
    required this.isCommon,
    required this.isExact,
  });

  final int wordId;
  final String? kanji;
  final String kana;
  final String romaji;

  /// First sense (English).
  final String gloss;
  final int? jlptLevel;
  final bool isCommon;

  /// Exact kanji/kana/romaji match (marked with a primary bar in the list).
  final bool isExact;

  String get headword => kanji ?? kana;

  /// A browse/collection row shown with the search row widget.
  factory SearchHit.fromBrief(WordBrief w) => SearchHit(
    wordId: w.id,
    kanji: w.kanji,
    kana: w.kana,
    romaji: w.romaji,
    gloss: w.gloss,
    jlptLevel: w.jlpt,
    isCommon: false,
    isExact: false,
  );
}

/// Two-tier dictionary search (PRD F1.2). Mirrors
/// `data_pipeline/scripts/search_reference.py`, plus the romaji → kana path
/// that only exists in the app.
///
/// Tiers (lower ranks first):
///   0 exact form / exact romaji · 1 form prefix · 2 Japanese substring
///   3 exact meaning · 4 romaji prefix (and kana prefix from romaji)
///   5 meaning word · 6 meaning prefix
/// Tie-breakers: earliest matching sense → common → easier JLPT →
/// shorter headword → freq_rank.
class SearchService {
  SearchService(this._db);

  final Database _db;

  static const maxCandidates = 300;
  static const minMeaningLength = 2;
  static const minMeaningPrefixLength = 3;
  static final _ftsToken = RegExp(r'[^\p{L}\p{N}_]+', unicode: true);
  static final _parens = RegExp(r'\(.*?\)');
  static final _latinLetter = RegExp('[a-z]');

  List<SearchHit> search(String query, {SearchMode mode = SearchMode.hiragana, int limit = 50}) {
    final tiers = <int, int>{};
    final senseRank = <int, int>{};

    void add(ResultSet rows, int tier) {
      for (final row in rows) {
        final id = row.columnAt(0) as int;
        final current = tiers[id];
        if (current == null || tier < current) tiers[id] = tier;
      }
    }

    if (hasJapanese(query)) {
      _searchJapanese(normalizeJp(query), add, prefixTier: 1, substring: true);
    } else {
      final q = normalizeLatin(query);
      if (q.isEmpty) return const [];

      if (mode != SearchMode.latin) {
        final r = romajiSearch(q).replaceAll(' ', '');
        if (r.isNotEmpty) {
          add(_db.select('SELECT id FROM words WHERE romaji_search = ?', [r]), 0);
          if (r.length >= 2) {
            add(
              _db.select('SELECT id FROM words WHERE romaji_search >= ? AND romaji_search < ? LIMIT ?', [
                r,
                '$r\u{10FFFF}',
                maxCandidates,
              ]),
              4,
            );
          }
          // Fully converted romaji ("taberu" → たべる) also hits kana forms,
          // which covers spelling variants romaji_search does not (づ/ず, ou/oo).
          final kana = normalizeJp(RomajiToKana.toHiragana(r));
          if (kana.isNotEmpty && !_latinLetter.hasMatch(kana)) {
            _searchJapanese(kana, add, prefixTier: 4, substring: false);
          }
        }
      }
      _searchMeaning(q, add, tiers, senseRank);
    }

    if (tiers.isEmpty) return const [];
    return _rank(tiers, senseRank, limit);
  }

  void _searchJapanese(
    String q,
    void Function(ResultSet, int) add, {
    required int prefixTier,
    required bool substring,
  }) {
    if (q.isEmpty) return;
    add(_db.select('SELECT word_id FROM word_forms WHERE norm_text = ?', [q]), 0);
    add(
      _db.select('SELECT word_id FROM word_forms WHERE norm_text >= ? AND norm_text < ? LIMIT ?', [
        q,
        '$q\u{10FFFF}',
        maxCandidates,
      ]),
      prefixTier,
    );
    if (substring && q.runes.length >= 3) {
      add(
        _db.select('SELECT rowid FROM words_fts_jp WHERE words_fts_jp MATCH ? LIMIT ?', [_phrase(q), maxCandidates]),
        2,
      );
    }
  }

  void _searchMeaning(String q, void Function(ResultSet, int) add, Map<int, int> tiers, Map<int, int> senseRank) {
    final tokens = q.split(_ftsToken).where((t) => t.isNotEmpty).toList();
    // A 1-letter meaning ("a") matches nearly every entry and BM25 ranking of
    // that set is the slowest query; it is never a useful meaning search.
    if (tokens.isEmpty || q.length < minMeaningLength) return;

    // Meanings are English only (Indonesian meanings were dropped, Oct 2026),
    // so the gloss_id columns of the index stay empty and are not queried.
    final phrase = _phrase(tokens.join(' '));
    final wordIds = _db.select(
      'SELECT rowid FROM words_fts_gloss WHERE words_fts_gloss MATCH ? ORDER BY rank LIMIT ?',
      ['gloss_en : $phrase', maxCandidates],
    );
    add(wordIds, 5);

    if (tokens.last.length >= minMeaningPrefixLength) {
      final prefix = [...tokens.take(tokens.length - 1).map(_phrase), '${_phrase(tokens.last)}*'].join(' ');
      add(
        _db.select('SELECT rowid FROM words_fts_gloss WHERE words_fts_gloss MATCH ? ORDER BY rank LIMIT ?', [
          'gloss_en : ($prefix)',
          maxCandidates,
        ]),
        6,
      );
    }

    if (wordIds.isEmpty) return;
    final ids = [for (final row in wordIds) row.columnAt(0) as int];
    final marks = List.filled(ids.length, '?').join(',');
    final senses = _db.select('SELECT word_id, sense_no, gloss_en FROM word_senses WHERE word_id IN ($marks)', ids);
    for (final s in senses) {
      if (_glossItems(s['gloss_en'] as String).contains(q)) {
        final id = s['word_id'] as int;
        final senseNo = s['sense_no'] as int;
        if (tiers[id]! > 3) tiers[id] = 3;
        final best = senseRank[id];
        if (best == null || senseNo < best) senseRank[id] = senseNo;
      }
    }
  }

  List<SearchHit> _rank(Map<int, int> tiers, Map<int, int> senseRank, int limit) {
    final ids = tiers.keys.toList();
    final marks = List.filled(ids.length, '?').join(',');
    final rows = _db.select(
      'SELECT w.id, w.primary_kanji, w.primary_kana, w.romaji, w.is_common, w.jlpt_level, w.freq_rank, '
      '       (SELECT s.gloss_en FROM word_senses s '
      '         WHERE s.word_id = w.id ORDER BY s.sense_no LIMIT 1) AS gloss '
      'FROM words w WHERE w.id IN ($marks)',
      ids,
    );

    int key(Row r) => r['id'] as int;
    final sorted = rows.toList()
      ..sort((a, b) {
        final ka = key(a), kb = key(b);
        final headA = (a['primary_kanji'] ?? a['primary_kana']) as String;
        final headB = (b['primary_kanji'] ?? b['primary_kana']) as String;
        final keysA = [
          tiers[ka]!,
          senseRank[ka] ?? 0,
          -(a['is_common'] as int),
          -((a['jlpt_level'] as int?) ?? 0),
          headA.runes.length,
          (a['freq_rank'] as int?) ?? 1000000,
        ];
        final keysB = [
          tiers[kb]!,
          senseRank[kb] ?? 0,
          -(b['is_common'] as int),
          -((b['jlpt_level'] as int?) ?? 0),
          headB.runes.length,
          (b['freq_rank'] as int?) ?? 1000000,
        ];
        for (var i = 0; i < keysA.length; i++) {
          final c = keysA[i].compareTo(keysB[i]);
          if (c != 0) return c;
        }
        return 0;
      });

    return [
      for (final r in sorted.take(limit))
        SearchHit(
          wordId: r['id'] as int,
          kanji: r['primary_kanji'] as String?,
          kana: r['primary_kana'] as String,
          romaji: r['romaji'] as String,
          gloss: (r['gloss'] as String?) ?? '',
          jlptLevel: r['jlpt_level'] as int?,
          isCommon: r['is_common'] == 1,
          isExact: tiers[r['id'] as int] == 0,
        ),
    ];
  }

  static String _phrase(String text) => '"${text.replaceAll('"', '""')}"';

  static Set<String> _glossItems(String gloss) {
    final items = <String>{};
    for (final raw in gloss.split(';')) {
      final item = normalizeLatin(raw).replaceAll(_parens, '').trim();
      if (item.isEmpty) continue;
      items.add(item);
      if (item.startsWith('to ')) items.add(item.substring(3));
    }
    return items;
  }
}
