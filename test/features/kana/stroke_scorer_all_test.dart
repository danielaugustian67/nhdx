import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/svg/svg_path.dart';
import 'package:nihondx/features/kana/writing/stroke_scorer.dart';
import 'package:sqlite3/sqlite3.dart';

/// Scores every character with stroke data in content.db (build with
/// `python data_pipeline/build_all.py`): good writing passes, mistakes fail.
void main() {
  const dbPath = 'data_pipeline/output/content.db';
  final skip = File(dbPath).existsSync() ? false : 'content.db not built';
  const canvas = 300.0;

  late Map<String, List<Path>> all;
  setUpAll(() {
    if (skip != false) return;
    final raw = sqlite3.open(dbPath, mode: OpenMode.readOnly);
    final chars = [
      for (final r in raw.select('SELECT DISTINCT codepoint FROM char_strokes')) String.fromCharCode(r['codepoint'] as int),
    ];
    raw.close();
    final db = ContentDb.open(dbPath);
    all = {for (final c in chars) c: db.strokes(c).map(parseSvgPath).toList()};
    db.close();
  });

  List<List<Offset>> perfect(List<Path> ref) => [
    for (final p in ref) [for (final pt in resamplePath(p, 40)) pt * (canvas / box)],
  ];

  /// Hand-drawn feel: every point nudged by up to ~2% of the canvas.
  List<List<Offset>> wobbly(List<Path> ref) => [
    for (final stroke in perfect(ref))
      [for (var k = 0; k < stroke.length; k++) stroke[k] + Offset((k % 3 - 1) * 5.0, (k % 2) * 4.0)],
  ];

  bool passes(List<List<Offset>> drawn, List<Path> ref) =>
      scoreWriting(drawn: drawn, canvasSize: canvas, reference: ref).passed;

  test('every character has strokes that parse', () {
    expect(all.length, greaterThan(2000));
    final empty = [
      for (final MapEntry(key: c, value: ref) in all.entries)
        if (ref.isEmpty || ref.any((p) => p.computeMetrics().every((m) => m.length < 1))) c,
    ];
    expect(empty, isEmpty);
  }, skip: skip);

  test('a perfect copy of every character passes', () {
    final failed = [
      for (final MapEntry(key: c, value: ref) in all.entries)
        if (!passes(perfect(ref), ref)) c,
    ];
    expect(failed, isEmpty, reason: '${failed.length} of ${all.length}');
  }, skip: skip);

  test('slightly wobbly writing of every character passes', () {
    final failed = [
      for (final MapEntry(key: c, value: ref) in all.entries)
        if (!passes(wobbly(ref), ref)) c,
    ];
    expect(failed, isEmpty, reason: '${failed.length} of ${all.length}');
  }, skip: skip);

  test('a missing last stroke, or strokes drawn backwards, fail', () {
    final failed = <String>[];
    for (final MapEntry(key: c, value: ref) in all.entries) {
      final good = perfect(ref);
      if (passes(good.sublist(0, good.length - 1), ref)) failed.add('$c missing stroke');
      final backwards = [for (final s in good) s.reversed.toList()];
      // A dot-like stroke looks the same either way; one long stroke is enough.
      final long = ref.any((p) => p.computeMetrics().fold(0.0, (a, m) => a + m.length) > 30);
      if (long && passes(backwards, ref)) failed.add('$c backwards');
    }
    expect(failed, isEmpty, reason: '${failed.length}: ${failed.take(20)}');
  }, skip: skip);

  test('writing another character with as many strokes fails', () {
    final byCount = <int, List<String>>{};
    for (final MapEntry(key: c, value: ref) in all.entries) {
      (byCount[ref.length] ??= []).add(c);
    }
    var tried = 0;
    final passed = <String>[];
    for (final group in byCount.values) {
      for (var i = 0; i + 1 < group.length; i++) {
        final a = group[i], b = group[i + 1];
        tried++;
        if (passes(perfect(all[b]!), all[a]!)) passed.add('$b as $a');
      }
    }
    // Look-alikes (へ/ヘ, 口/ロ, 二/ニ, ...) may pass; anything else is a bug.
    expect(passed.length, lessThan(tried * 0.02), reason: '${passed.length} of $tried: ${passed.take(40)}');
  }, skip: skip);
}
