import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// Thick "pressable" button (ui-design §4.5): a solid face over a darker
/// bottom edge that sinks when pressed. Used for the main call to action in
/// the learning path and games.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.height = AppSizes.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double height;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;
  static const _edge = 5.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = widget.onPressed != null;
    final face = enabled ? (widget.color ?? c.primary) : c.surfaceHigh;
    final edge = Color.lerp(face, Colors.black, 0.35)!;
    final fg = enabled ? (widget.textColor ?? c.onPrimary) : c.inkMuted;
    final offset = _down ? _edge : 0.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          height: widget.height + _edge,
          child: Stack(
            children: [
              Positioned.fill(
                top: _edge,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: edge, borderRadius: BorderRadius.circular(AppRadius.control)),
                ),
              ),
              AnimatedPositioned(
                duration: AppDurations.press,
                left: 0,
                right: 0,
                top: offset,
                height: widget.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: face, borderRadius: BorderRadius.circular(AppRadius.control)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[Icon(widget.icon, color: fg), const SizedBox(width: AppSpace.s)],
                        // A long label with large text shrinks instead of overflowing.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              style: AppText.body.copyWith(color: fg, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
