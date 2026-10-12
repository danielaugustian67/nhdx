import 'package:flutter/material.dart';

import '../../../core/svg/svg_path.dart';
import '../../../core/theme/app_colors.dart';
import '../writing/stroke_scorer.dart' show box;

/// Animated stroke order from KanjiVG paths (ui-design §5.7, §5.8): finished
/// strokes in ink, the current one drawn progressively, upcoming ones faint,
/// numbered at their start (numbers are shown because they are a real order).
class StrokeAnimation extends StatefulWidget {
  const StrokeAnimation({
    super.key,
    required this.paths,
    this.size = 200,
    this.perStroke = const Duration(milliseconds: 650),
  });

  final List<String> paths;
  final double size;
  final Duration perStroke;

  @override
  State<StrokeAnimation> createState() => StrokeAnimationState();
}

class StrokeAnimationState extends State<StrokeAnimation> with SingleTickerProviderStateMixin {
  late final List<Path> _paths = widget.paths.map(parseSvgPath).toList();
  late final _controller = AnimationController(vsync: this, duration: widget.perStroke * _paths.length);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status == AnimationStatus.dismissed) {
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  void replay() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: StrokePainter(
            paths: _paths,
            progress: _controller.value * _paths.length,
            ink: c.ink,
            faint: c.line,
            accent: c.primaryText,
            showNumbers: true,
          ),
        ),
      ),
    );
  }
}

/// Paints KanjiVG strokes in a square. [progress] counts finished strokes
/// (e.g. 1.5 = first stroke done, second half drawn).
class StrokePainter extends CustomPainter {
  StrokePainter({
    required this.paths,
    required this.progress,
    required this.ink,
    required this.faint,
    required this.accent,
    this.showNumbers = false,
    this.showGrid = true,
  });

  final List<Path> paths;
  final double progress;
  final Color ink;
  final Color faint;
  final Color accent;
  final bool showNumbers;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / box;
    if (showGrid) {
      final grid = Paint()
        ..color = faint
        ..strokeWidth = 1;
      _dashed(canvas, Offset(size.width / 2, 0), Offset(size.width / 2, size.height), grid);
      _dashed(canvas, Offset(0, size.height / 2), Offset(size.width, size.height / 2), grid);
    }
    canvas.save();
    canvas.scale(scale);
    final width = 3.2;
    Paint pen(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width;

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (i + 1 <= progress) {
        canvas.drawPath(path, pen(ink));
      } else if (i < progress) {
        canvas.drawPath(path, pen(faint));
        final metric = path.computeMetrics().first;
        canvas.drawPath(metric.extractPath(0, metric.length * (progress - i)), pen(accent));
      } else {
        canvas.drawPath(path, pen(faint));
      }
    }
    canvas.restore();

    if (showNumbers) {
      for (var i = 0; i < paths.length; i++) {
        final start = paths[i].computeMetrics().first.getTangentForOffset(0)!.position * scale;
        final tp = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: TextStyle(
              fontSize: size.width * 0.065,
              color: i < progress ? accent : faint,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, start - Offset(tp.width + 2, tp.height / 2));
      }
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0, gap = 5.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += dash + gap) {
      canvas.drawLine(a + dir * d, a + dir * (d + dash).clamp(0, total), paint);
    }
  }

  @override
  bool shouldRepaint(StrokePainter old) => old.progress != progress || old.paths != paths || old.ink != ink;
}
