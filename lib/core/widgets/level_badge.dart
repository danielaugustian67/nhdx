import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// JLPT badge: 4 dp square, indigo tone per level, always shows "N5" text
/// (color is never the only signal, ui-design §4.1).
class LevelBadge extends StatelessWidget {
  const LevelBadge(this.level, {super.key});

  /// 5 (N5) … 1 (N1).
  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: colors.jlptBg(level), borderRadius: BorderRadius.circular(AppRadius.badge)),
      child: Text('N$level', style: AppText.label.copyWith(color: colors.jlptFg(level))),
    );
  }
}
