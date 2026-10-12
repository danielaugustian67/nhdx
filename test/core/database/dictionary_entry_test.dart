import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/dictionary_db.dart';

/// Runs against the pipeline output (`python data_pipeline/build_all.py`).
void main() {
  const dbPath = 'data_pipeline/output/dictionary.db';
  final available = File(dbPath).existsSync();
  final skip = available ? false : 'dictionary.db not built';

  late DictionaryDb dict;
  setUpAll(() {
    if (available) dict = DictionaryDb.open(dbPath);
  });
  tearDownAll(() {
    if (available) dict.close();
  });

  test('entry has forms, numbered senses and readable parts of speech', () {
    final e = dict.entry(1358280)!; // 食べる
    expect(e.headword, '食べる');
    expect(e.kana, 'たべる');
    expect(e.jlpt, 5);
    expect(e.verbGroup, 'ichidan');
    expect(e.kanjiForms.first, '食べる');
    expect(e.kanaForms, contains('たべる'));
    expect(e.senses.first.number, 1);
    expect(e.senses.first.gloss, 'to eat');
    expect(e.senses.first.pos.first, contains('Ichidan verb'));
  }, skip: skip);

  test('unknown ids give null (orphaned bookmarks)', () {
    expect(dict.entry(-1), isNull);
  }, skip: skip);

  test('level browse is most common first and counts match', () {
    final n5 = dict.levelWords(5, limit: 20);
    expect(n5, hasLength(20));
    expect(n5.every((w) => w.jlpt == 5), isTrue);
    expect(dict.levelCount(5), greaterThan(500));
  }, skip: skip);

  test('word of the day is stable for a date and changes between dates', () {
    final a = dict.wordOfTheDay('2026-10-10')!;
    expect(dict.wordOfTheDay('2026-10-10')!.id, a.id);
    final others = {
      for (final d in ['2026-10-11', '2026-10-12', '2026-10-13']) dict.wordOfTheDay(d)!.id,
    };
    expect(others.difference({a.id}), isNotEmpty);
    expect(a.jlpt, greaterThanOrEqualTo(3));
  }, skip: skip);
}
