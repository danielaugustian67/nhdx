import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A card that turns over to show [back]: a 3D flip, or a cross-fade when the
/// system asks for reduced motion. Tapping the front calls [onFlip].
class FlipCard extends StatelessWidget {
  const FlipCard({super.key, required this.flipped, required this.front, required this.back, this.onFlip});

  final bool flipped;
  final Widget front;
  final Widget back;
  final VoidCallback? onFlip;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: flipped ? null : onFlip,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: flipped ? 1 : 0),
        duration: reduceMotion ? AppDurations.crossFade : AppDurations.cardFlip,
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          if (reduceMotion) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(opacity: 1 - t, child: front),
                Opacity(opacity: t, child: back),
              ],
            );
          }
          // Front turns away during the first half, back turns in.
          final angle = t * math.pi;
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(showBack ? angle - math.pi : angle),
            child: showBack ? back : front,
          );
        },
      ),
    );
  }
}
