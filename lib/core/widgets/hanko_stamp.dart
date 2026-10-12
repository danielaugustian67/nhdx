import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// Glowing hanko stamp (ui-design §7): drops from 1.3× with a small rotation
/// in 180 ms, then rests, with a medium haptic. Reduced motion shows it
/// statically. Placeholder drawing until the illustrator's vector stamps
/// exist.
class HankoStamp extends StatefulWidget {
  const HankoStamp({super.key, this.character = '済', this.size = 112});

  final String character;
  final double size;

  @override
  State<HankoStamp> createState() => _HankoStampState();
}

class _HankoStampState extends State<HankoStamp> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: AppDurations.stamp);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status == AnimationStatus.dismissed) {
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Transform.rotate(
        angle: (1 - curve.value) * -6 * math.pi / 180,
        child: Transform.scale(scale: 1.3 - 0.3 * curve.value, child: child),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.seal, width: widget.size * 0.06),
          boxShadow: [BoxShadow(color: c.seal.withValues(alpha: 0.45), blurRadius: 28)],
          color: c.seal.withValues(alpha: 0.10),
        ),
        child: Text(
          widget.character,
          locale: const Locale('ja'),
          style: AppText.displayWord.copyWith(color: c.seal, fontSize: widget.size * 0.5, height: 1),
        ),
      ),
    );
  }
}
