import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Raised card for hubs, menus and games (ui-design §4.4): surface-high tone,
/// optional hero gradient and a soft violet glow instead of grey shadows.
/// A disabled card is dimmed and not tappable ("Segera hadir").
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.glow = false,
    this.radius = AppRadius.card,
    this.padding = const EdgeInsets.all(AppSpace.l),
    this.color,
    this.borderColor,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool glow;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(radius);
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            color: gradient == null ? (color ?? c.surfaceHigh) : null,
            gradient: gradient,
            border: Border.all(color: borderColor ?? c.line.withValues(alpha: gradient == null ? 1 : 0)),
            boxShadow: glow
                ? [BoxShadow(color: c.primary.withValues(alpha: 0.30), blurRadius: 32, spreadRadius: -4)]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: shape,
              onTap: enabled ? onTap : null,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
