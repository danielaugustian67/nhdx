import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/database/korean_dict_db.dart';
import 'package:nihondx/features/search/korean_search_service.dart';

/// Runs against the pipeline output (`python data_pipeline/build_all.py`).
void main() {
  const dbPath = 'data_pipeline/output/korean.db';
  final available = File(dbPath).existsSync();
  final skip = available ? false : 'korean.db not built';

  late KoreanDictDb dict;
  late KoreanSearchService search;
  setUpAll(() {
    if (available) {
      dict = KoreanDictDb.open(dbPath);
      search = KoreanSearchService(dict);
    }
  });
  tearDownAll(() {
    if (available) dict.close();
  });

  List<String> hangul(String query, {String language = 'en'}) => [
    for (final h in search.search(query, language: language)) h.kana,
  ];

  test('a course word keeps its course id, Indonesian meaning and Wiktionary senses', () {
    final hit = search.search('사과', language: 'id').first;
    expect(hit.kana, '사과');
    expect(hit.wordId, greaterThanOrEqualTo(koWordIdBase));
    expect(hit.gloss, 'apel');
    expect(hit.isExact, isTrue);
    final e = dict.entry(hit.wordId)!;
    expect(e.inCourse, isTrue);
    expect(e.meaning('id'), 'apel');
    expect(e.meaning('en'), 'apple');
    // 사과 is also "apology" (謝過).
    expect(e.senses.expand((s) => s.glosses).join(' '), contains('apolog'));
  }, skip: skip);

  test('every word id is a Korean id below 2^31', () {
    final row = dict.db.select('SELECT min(id) AS lo, max(id) AS hi, count(*) AS n FROM words').first;
    expect(row['lo'] as int, greaterThanOrEqualTo(koWordIdBase));
    expect(row['hi'] as int, lessThan(1 << 31));
    expect(row['n'] as int, greaterThan(20000));
  }, skip: skip);

  test('Hangul: exact first, then words starting with it', () {
    final hits = hangul('먹다');
    expect(hits.first, '먹다');
    expect(hangul('먹').take(10), everyElement(startsWith('먹')));
  }, skip: skip);

  test('romanization finds the word, with or without spaces', () {
    expect(hangul('meokda'), contains('먹다'));
    expect(hangul('meok da'), contains('먹다'));
    expect(hangul('sagwa').first, '사과');
  }, skip: skip);

  test('English and Indonesian meanings find the word', () {
    expect(hangul('to eat').take(5), contains('먹다'));
    expect(hangul('eat').first, '먹다');
    expect(hangul('apple').take(3), contains('사과'));
    expect(hangul('apel', language: 'id').take(3), contains('사과'));
  }, skip: skip);

  test('a word that means the query first ranks above one that means it further down', () {
    // 하다 "to do" lists "to eat" sixth, 닫다 "to close" lists "to run".
    final eat = search.search('eat').map((h) => h.kana).toList();
    expect(eat.take(3), containsAll(['먹다', '식사하다']));
    expect(eat.indexOf('하다'), greaterThan(eat.indexOf('식사하다')));
    final run = search.search('run').map((h) => h.kana).toList();
    expect(run.indexOf('닫다'), greaterThan(run.indexOf('달리다')));
    expect(search.search('house').take(3).map((h) => h.kana), isNot(contains('보다')));
  }, skip: skip);

  test('brief rows and the word of the day come from the course', () {
    final word = dict.wordOfTheDay('2026-10-13', language: 'id')!;
    expect(word, isNotNull);
    expect(dict.wordOfTheDay('2026-10-13', language: 'id')!.id, word.id);
    final brief = dict.briefs([word.id, -1], language: 'id');
    expect(brief.keys, [word.id]);
    expect(brief[word.id]!.kanji, isNull);
    expect(brief[word.id]!.jlpt, isNull);
    final topic = dict.entry(word.id)!.topic!;
    expect(dict.topicWords(topic).map((w) => w.id), contains(word.id));
  }, skip: skip);

  test('words outside the course get an Indonesian meaning from translations', () {
    final spinach = dict.entry(search.search('시금치').first.wordId)!;
    expect(spinach.inCourse, isFalse);
    expect(spinach.meaning('id'), 'bayam');
    // Only the main meanings pivot: 맥's "pulse" has no translation listing
    // it, and its homonym "tapir" must not stand in.
    final maek = dict.entry(search.search('맥').first.wordId)!;
    expect(maek.glossId, isNull);
    // Indonesian search finds it.
    expect(search.search('bayam', language: 'id').map((h) => h.kana), contains('시금치'));
  }, skip: skip);

  test('vulgar and offensive meanings are left out', () {
    final meokda = dict.entry(search.search('먹다').first.wordId)!;
    expect(meokda.senses.first.glosses.first, contains('to eat'));
    final crude = dict.db.select(
      "SELECT count(*) AS n FROM words WHERE senses LIKE '%fuck%' OR senses LIKE '%cunt%' OR senses LIKE '%whore%'",
    );
    expect(crude.first['n'], 0);
  }, skip: skip);

  test('unknown ids give null', () {
    expect(dict.entry(-1), isNull);
  }, skip: skip);
}
