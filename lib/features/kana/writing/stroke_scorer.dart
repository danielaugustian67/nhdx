import 'dart:math' as math;
import 'dart:ui';

/// Handwriting scorer (PRD F6 "Algoritma penilaian tulisan"), a pure function
/// reused for kanji in v1.1 with stricter [Tolerance].
///
/// 1. Everything is in the KanjiVG 109×109 box; drawn strokes are scaled
///    from the canvas size into it.
/// 2. Each stroke is resampled to [samples] equally spaced points.
/// 3. Stroke count must match the reference.
/// 4. Order & direction: drawn stroke n is compared with reference n; its
///    start/end must be near the reference start/end, not swapped.
/// 5. Shape: mean point distance after normalizing each stroke's position
///    and scale must stay under a threshold.

enum StrokeIssue { ok, wrongOrder, reversed, misplaced, wrongShape }

class StrokeFeedback {
  const StrokeFeedback(this.index, this.issue);

  /// 0-based stroke index.
  final int index;
  final StrokeIssue issue;
}

class WritingScore {
  const WritingScore({required this.expectedStrokes, required this.drawnStrokes, required this.strokes});

  final int expectedStrokes;
  final int drawnStrokes;
  final List<StrokeFeedback> strokes;

  bool get countMatches => expectedStrokes == drawnStrokes;
  bool get passed => countMatches && strokes.every((s) => s.issue == StrokeIssue.ok);

  /// First stroke with a problem, for the single feedback line in the UI.
  StrokeFeedback? get firstProblem {
    for (final s in strokes) {
      if (s.issue != StrokeIssue.ok) return s;
    }
    return null;
  }

  /// 0–1 share of correct strokes (0 when the count is wrong).
  double get accuracy =>
      !countMatches || strokes.isEmpty ? 0 : strokes.where((s) => s.issue == StrokeIssue.ok).length / strokes.length;
}

class Tolerance {
  const Tolerance({required this.endpoint, required this.shape});

  /// Max distance (109-box units) between drawn and reference start/end.
  final double endpoint;

  /// Max mean distance between normalized stroke shapes (unit box).
  final double shape;

  /// Loose: kana practice for beginners.
  static const kana = Tolerance(endpoint: 30, shape: 0.28);

  /// Stricter: kanji (v1.1).
  static const kanji = Tolerance(endpoint: 20, shape: 0.22);
}

const box = 109.0;
const samples = 32;

/// [drawn] strokes are in canvas coordinates of a square canvas [canvasSize].
WritingScore scoreWriting({
  required List<List<Offset>> drawn,
  required double canvasSize,
  required List<Path> reference,
  Tolerance tolerance = Tolerance.kana,
}) {
  final scale = box / canvasSize;
  final user = [
    for (final stroke in drawn)
      if (stroke.length >= 2) resamplePolyline([for (final p in stroke) p * scale], samples),
  ];
  final ref = [for (final path in reference) resamplePath(path, samples)];

  final feedback = <StrokeFeedback>[];
  final n = math.min(user.length, ref.length);
  for (var i = 0; i < n; i++) {
    feedback.add(StrokeFeedback(i, _judge(i, user, ref, tolerance)));
  }
  return WritingScore(expectedStrokes: ref.length, drawnStrokes: user.length, strokes: feedback);
}

StrokeIssue _judge(int i, List<List<Offset>> user, List<List<Offset>> ref, Tolerance tol) {
  final u = user[i], r = ref[i];
  final forward = (u.first - r.first).distance + (u.last - r.last).distance;
  final backward = (u.first - r.last).distance + (u.last - r.first).distance;
  final placedHere = forward <= 2 * tol.endpoint;

  if (!placedHere) {
    // Matches another reference stroke well → drawn in the wrong order.
    for (var j = 0; j < ref.length; j++) {
      if (j == i) continue;
      final other = (u.first - ref[j].first).distance + (u.last - ref[j].last).distance;
      if (other <= 2 * tol.endpoint) return StrokeIssue.wrongOrder;
    }
    if (backward <= 2 * tol.endpoint) return StrokeIssue.reversed;
    return StrokeIssue.misplaced;
  }
  if (_shapeDistance(u, r) > tol.shape) return StrokeIssue.wrongShape;
  return StrokeIssue.ok;
}

/// Mean point distance after translating each stroke to its centroid and
/// scaling by its own size, so only the shape is compared.
double _shapeDistance(List<Offset> a, List<Offset> b) {
  final na = _normalize(a), nb = _normalize(b);
  var sum = 0.0;
  for (var k = 0; k < na.length; k++) {
    sum += (na[k] - nb[k]).distance;
  }
  return sum / na.length;
}

List<Offset> _normalize(List<Offset> pts) {
  var cx = 0.0, cy = 0.0;
  for (final p in pts) {
    cx += p.dx;
    cy += p.dy;
  }
  cx /= pts.length;
  cy /= pts.length;
  var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
  for (final p in pts) {
    minX = math.min(minX, p.dx);
    maxX = math.max(maxX, p.dx);
    minY = math.min(minY, p.dy);
    maxY = math.max(maxY, p.dy);
  }
  // Floor the size so a nearly straight stroke is not blown up into noise.
  final size = math.max(math.max(maxX - minX, maxY - minY), 12.0);
  return [for (final p in pts) Offset((p.dx - cx) / size, (p.dy - cy) / size)];
}

/// [n] points equally spaced along a polyline.
List<Offset> resamplePolyline(List<Offset> pts, int n) {
  final lengths = <double>[0];
  for (var k = 1; k < pts.length; k++) {
    lengths.add(lengths.last + (pts[k] - pts[k - 1]).distance);
  }
  final total = lengths.last;
  if (total == 0) return List.filled(n, pts.first);
  final out = <Offset>[];
  var seg = 1;
  for (var k = 0; k < n; k++) {
    final target = total * k / (n - 1);
    while (seg < pts.length - 1 && lengths[seg] < target) {
      seg++;
    }
    final segLen = lengths[seg] - lengths[seg - 1];
    final t = segLen == 0 ? 0.0 : (target - lengths[seg - 1]) / segLen;
    out.add(Offset.lerp(pts[seg - 1], pts[seg], t.clamp(0, 1))!);
  }
  return out;
}

/// [n] points equally spaced along a (single-contour) path.
List<Offset> resamplePath(Path path, int n) {
  final metric = path.computeMetrics().first;
  return [for (var k = 0; k < n; k++) metric.getTangentForOffset(metric.length * k / (n - 1))!.position];
}
