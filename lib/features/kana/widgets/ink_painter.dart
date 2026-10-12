import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../writing/stroke_scorer.dart';

/// The user's own strokes on a writing canvas; the stroke the scorer flagged
/// ([problem]) is drawn in [problemColor].
class InkPainter extends CustomPainter {
  InkPainter({required this.strokes, required this.color, required this.problem, required this.problemColor});

  final List<List<Offset>> strokes;
  final Color color;
  final int? problem;
  final Color problemColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < strokes.length; i++) {
      final pts = strokes[i];
      final paint = Paint()
        ..color = i == problem ? problemColor : color
        ..strokeWidth = size.width * 0.035
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      if (pts.length == 1) {
        canvas.drawCircle(pts.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(InkPainter old) => true;
}

/// One-line explanation of a writing score (PRD F6: name the stroke).
String writingFeedback(AppLocalizations l10n, WritingScore s) {
  if (s.passed) return l10n.writeGood;
  if (!s.countMatches) return l10n.writeCountWrong(s.drawnStrokes, s.expectedStrokes);
  final p = s.firstProblem!;
  final n = p.index + 1;
  return switch (p.issue) {
    StrokeIssue.reversed => l10n.writeReversed(n),
    StrokeIssue.wrongOrder => l10n.writeWrongOrder(n),
    StrokeIssue.misplaced => l10n.writeMisplaced(n),
    StrokeIssue.wrongShape || StrokeIssue.ok => l10n.writeWrongShape(n),
  };
}
