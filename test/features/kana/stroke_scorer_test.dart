import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/core/svg/svg_path.dart';
import 'package:nihondx/features/kana/writing/stroke_scorer.dart';

/// Uses the real KanjiVG strokes from content.db (build with
/// `python data_pipeline/build_all.py`).
void main() {
  const dbPath = 'data_pipeline/output/content.db';
  final skip = File(dbPath).existsSync() ? false : 'content.db not built';
  const canvas = 300.0;

  late List<Path> a; // あ: 3 strokes
  late List<Path> nu; // ぬ: 2 strokes

  setUpAll(() {
    if (skip != false) return;
    final db = ContentDb.open(dbPath);
    a = db.strokes('あ').map(parseSvgPath).toList();
    nu = db.strokes('ぬ').map(parseSvgPath).toList();
    db.close();
  });

  /// Reference strokes as if drawn perfectly on a 300 px canvas.
  List<List<Offset>> perfect(List<Path> ref, {Offset shift = Offset.zero}) => [
    for (final p in ref) [for (final pt in resamplePath(p, 40)) (pt + shift) * (canvas / box)],
  ];

  test('stroke counts from KanjiVG', () {
    expect(a, hasLength(3));
    expect(nu, hasLength(2));
  }, skip: skip);

  test('a perfect copy passes', () {
    final s = scoreWriting(drawn: perfect(a), canvasSize: canvas, reference: a);
    expect(s.passed, isTrue);
    expect(s.accuracy, 1);
  }, skip: skip);

  test('slightly wobbly writing still passes (loose kana tolerance)', () {
    final wobbly = [
      for (final stroke in perfect(a))
        [for (var k = 0; k < stroke.length; k++) stroke[k] + Offset((k % 3 - 1) * 6.0, (k % 2) * 5.0)],
    ];
    expect(scoreWriting(drawn: wobbly, canvasSize: canvas, reference: a).passed, isTrue);
  }, skip: skip);

  test('missing stroke fails on count', () {
    final s = scoreWriting(drawn: perfect(a).take(2).toList(), canvasSize: canvas, reference: a);
    expect(s.countMatches, isFalse);
    expect(s.passed, isFalse);
  }, skip: skip);

  test('reversed stroke is reported as reversed', () {
    final strokes = perfect(a);
    strokes[0] = strokes[0].reversed.toList();
    final s = scoreWriting(drawn: strokes, canvasSize: canvas, reference: a);
    expect(s.firstProblem?.index, 0);
    expect(s.firstProblem?.issue, StrokeIssue.reversed);
  }, skip: skip);

  test('swapped strokes are reported as wrong order', () {
    final strokes = perfect(a);
    final first = strokes[0];
    strokes[0] = strokes[1];
    strokes[1] = first;
    final s = scoreWriting(drawn: strokes, canvasSize: canvas, reference: a);
    expect(s.firstProblem?.issue, StrokeIssue.wrongOrder);
  }, skip: skip);

  test('character drawn far off the guide is misplaced', () {
    final s = scoreWriting(
      drawn: perfect(a, shift: const Offset(45, 45)),
      canvasSize: canvas,
      reference: a,
    );
    expect(s.firstProblem?.issue, StrokeIssue.misplaced);
  }, skip: skip);

  test('a straight line instead of the loop of あ is the wrong shape', () {
    final strokes = perfect(a);
    final loop = strokes[2];
    strokes[2] = [for (var k = 0; k < 40; k++) Offset.lerp(loop.first, loop.last, k / 39)!];
    final s = scoreWriting(drawn: strokes, canvasSize: canvas, reference: a);
    expect(s.firstProblem?.index, 2);
    expect(s.firstProblem?.issue, StrokeIssue.wrongShape);
  }, skip: skip);

  test('another character (ぬ) does not pass as あ', () {
    final s = scoreWriting(drawn: perfect(nu), canvasSize: canvas, reference: a);
    expect(s.passed, isFalse);
  }, skip: skip);
}
