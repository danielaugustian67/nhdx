import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/svg/svg_path.dart';
import 'package:nihondx/features/kana/writing/stroke_scorer.dart';
import 'package:nihondx/features/learn/lesson.dart';

/// Hand-drawn Hangul strokes (data_pipeline/scripts/hangul_strokes.py) in
/// content.db: every course letter has them, inside the box, and the stroke
/// scorer accepts them written perfectly.
void main() {
  const dbPath = 'data_pipeline/output/content.db';
  final skip = File(dbPath).existsSync() ? false : 'content.db not built';
  const canvas = 300.0;

  late ContentDb db;
  late List<Kana> hangul;

  setUpAll(() {
    if (skip != false) return;
    db = ContentDb.open(dbPath);
    hangul = db.hangul();
  });

  tearDownAll(() {
    if (skip == false) db.close();
  });

  test('every course letter and syllable has strokes inside the box', () {
    expect(hangul, isNotEmpty);
    for (final k in hangul) {
      final paths = db.strokes(k.literal).map(parseSvgPath).toList();
      expect(paths, isNotEmpty, reason: k.literal);
      for (final p in paths) {
        final b = p.getBounds();
        expect(b.left >= 0 && b.top >= 0 && b.right <= box && b.bottom <= box, isTrue, reason: '${k.literal} $b');
        expect(p.computeMetrics().first.length, greaterThan(5), reason: k.literal);
      }
    }
  }, skip: skip);

  test('stroke counts follow the jamo', () {
    int count(String ch) => db.strokes(ch).length;
    expect(count('ㄱ'), 1);
    expect(count('ㅁ'), 3);
    expect(count('ㄲ'), 2);
    expect(count('ㅏ'), 2);
    expect(count('가'), count('ㄱ') + count('ㅏ'));
    expect(count('각'), count('ㄱ') + count('ㅏ') + count('ㄱ'));
    expect(count('와'), count('ㅇ') + count('ㅘ'));
  }, skip: skip);

  test('a perfect copy of every letter passes the scorer', () {
    for (final k in hangul) {
      final ref = db.strokes(k.literal).map(parseSvgPath).toList();
      final drawn = [
        for (final p in ref) [for (final pt in resamplePath(p, 40)) pt * (canvas / box)],
      ];
      final s = scoreWriting(drawn: drawn, canvasSize: canvas, reference: ref);
      expect(s.passed, isTrue, reason: k.literal);
    }
  }, skip: skip);

  test('Hangul is written in practice only when content.db has its strokes', () {
    final ga = hangul.firstWhere((k) => k.literal == '가');
    expect(KanaLessonBuilder(focus: [ga], pool: [ga]).writable, isEmpty);
    expect(KanaLessonBuilder(focus: [ga], pool: [ga], hasStrokes: (_) => false).writable, isEmpty);
    final b = KanaLessonBuilder(focus: [ga], pool: [ga], hasStrokes: (k) => db.strokes(k.literal).isNotEmpty);
    expect(b.practice(ga).map((e) => e.runtimeType), [WriteExercise, GlyphReadExercise]);
  }, skip: skip);
}
