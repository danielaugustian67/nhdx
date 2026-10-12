import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// Daily goal ring (ui-design §4.6): thin 6 dp `primary` ring, "14/20" in the
/// middle with a small unit below. It never turns red while unfinished.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.done, required this.goal, required this.unit, this.size = 104});

  final int done;
  final int goal;
  final String unit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fraction = goal <= 0 ? 1.0 : (done / goal).clamp(0.0, 1.0);
    return Semantics(
      label: '$done / $goal $unit',
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: MediaQuery.of(context).disableAnimations ? Duration.zero : AppDurations.page,
          curve: Curves.easeOut,
          builder: (context, value, child) => CustomPaint(
            painter: _RingPainter(value: value, track: c.line, color: c.primary),
            child: child,
          ),
          child: ExcludeSemantics(
            // Shrinks with very large text rather than spilling out of the ring.
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.progressRingStroke + AppSpace.s),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$done'),
                          TextSpan(
                            text: '/$goal',
                            style: AppText.bodySmall.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ),
                      style: AppText.title2.copyWith(color: c.ink),
                    ),
                    Text(unit, style: AppText.label.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.track, required this.color});

  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSizes.progressRingStroke;
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ring, 0, 2 * math.pi, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(ring, -math.pi / 2, 2 * math.pi * value, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.track != track || old.color != color;
}
