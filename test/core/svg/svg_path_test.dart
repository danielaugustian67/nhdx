import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/svg/svg_path.dart';

Offset _end(Path p) {
  final m = p.computeMetrics().last;
  return m.getTangentForOffset(m.length)!.position;
}

void main() {
  test('absolute line', () {
    final p = parseSvgPath('M10,10L20,30');
    expect(_end(p), const Offset(20, 30));
  });

  test('relative cubic with compact numbers', () {
    final p = parseSvgPath('M10 20c0-5 5-10 10-10');
    expect(_end(p).dx, closeTo(20, 1e-6));
    expect(_end(p).dy, closeTo(10, 1e-6));
  });

  test('implicit repeats and smooth curves', () {
    final p = parseSvgPath('M0,0c1,1,2,2,3,3,1,1,2,2,3,3s2,2,3,3');
    expect(_end(p).dx, closeTo(9, 1e-6));
    expect(_end(p).dy, closeTo(9, 1e-6));
  });

  test('implicit lineto after moveto, H and V', () {
    final p = parseSvgPath('M1 1 5 1H9V4');
    expect(_end(p), const Offset(9, 4));
  });

  test('decimal shorthand ".5.5" and exponents', () {
    final p = parseSvgPath('M0 0L.5.5l1e1 0');
    expect(_end(p).dx, closeTo(10.5, 1e-6));
    expect(_end(p).dy, closeTo(0.5, 1e-6));
  });

  test('KanjiVG style path', () {
    // Stroke 1 of あ from KanjiVG
    final p = parseSvgPath('M31.01,28.4c1.12,0.6,3.45,0.62,4.57,0.52c8.04-0.67,23.21-2.84,33.98-3.65');
    final b = p.getBounds();
    expect(b.left, closeTo(31.01, 0.01));
    expect(b.right, greaterThan(69));
  });

  test('rejects arcs and garbage', () {
    expect(() => parseSvgPath('M0 0A5 5 0 0 1 10 10'), throwsFormatException);
    expect(() => parseSvgPath('10 10'), throwsFormatException);
  });
}
