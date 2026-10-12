import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/dictionary_db.dart';
import 'package:nihondx/features/search/search_service.dart';

/// Runs against the pipeline output; build it first with
/// `python data_pipeline/build_all.py`.
void main() {
  const dbPath = 'data_pipeline/output/dictionary.db';
  final available = File(dbPath).existsSync();
  final skip = available ? false : 'dictionary.db not built';

  late DictionaryDb dict;
  late SearchService search;

  setUpAll(() {
    if (!available) return;
    dict = DictionaryDb.open(dbPath);
    search = SearchService(dict.db);
  });
  tearDownAll(() {
    if (available) dict.close();
  });

  int rankOf(String query, String headword, {SearchMode mode = SearchMode.hiragana}) {
    final hits = search.search(query, mode: mode, limit: 20);
    final i = hits.indexWhere((h) => h.headword == headword);
    return i < 0 ? 999 : i + 1;
  }

  // PRD §12 v1.0 #2: 食べる in the top 3 for every input style.
  for (final q in ['taberu', 'たべる', '食べる', 'eat', 'タベル', 'ﾀﾍﾞﾙ', 'TABERU']) {
    test("'$q' → 食べる in top 3", () => expect(rankOf(q, '食べる'), lessThanOrEqualTo(3)), skip: skip);
  }

  test('1-char queries use the B-tree path', () {
    expect(rankOf('木', '木'), 1);
    expect(rankOf('目', '目'), 1);
  }, skip: skip);

  test("2-char prefix '食べ' finds 食べる", () => expect(rankOf('食べ', '食べる'), lessThanOrEqualTo(20)), skip: skip);

  test("substring 'べもの' finds 食べ物", () => expect(rankOf('べもの', '食べ物'), lessThanOrEqualTo(5)), skip: skip);

  test('づ/ず folding: tsuzuku finds 続く', () {
    expect(rankOf('tsuzuku', '続く'), lessThanOrEqualTo(3));
    expect(rankOf('つずく', '続く'), lessThanOrEqualTo(3));
  }, skip: skip);

  test("romaji with long-vowel variant 'gakkou' finds 学校", () {
    expect(rankOf('gakkou', '学校'), 1);
  }, skip: skip);

  test("'eat' does not rank エアタヒチ above 食べる", () {
    expect(rankOf('eat', '食べる'), lessThan(rankOf('eat', 'エアタヒチ')));
  }, skip: skip);

  test('latin mode skips romaji conversion', () {
    final hits = search.search('kita', mode: SearchMode.latin);
    expect(hits.any((h) => h.headword == '北'), isFalse);
    expect(search.search('kita').first.headword, isNot(isEmpty));
  }, skip: skip);

  test('exact hits are flagged', () {
    final hits = search.search('ねこ');
    expect(hits.first.isExact, isTrue);
    expect(hits.first.headword, '猫');
  }, skip: skip);

  test('p95 latency ≤ 100 ms on dev machine', () {
    const queries = ['taberu', 'eat', 'cat', 'た', 'a', 'go', '食べ', '日本語', 'to be', 'べもの', 'sakura', 'beautiful'];
    for (final q in queries) {
      search.search(q); // warm up
    }
    final times = <int>[];
    for (var i = 0; i < 5; i++) {
      for (final q in queries) {
        final sw = Stopwatch()..start();
        search.search(q);
        times.add(sw.elapsedMicroseconds);
      }
    }
    times.sort();
    final p95 = times[(times.length * 0.95).floor()] / 1000;
    // ignore: avoid_print
    print('search p95: ${p95.toStringAsFixed(1)} ms');
    expect(p95, lessThanOrEqualTo(100));
  }, skip: skip);
}
