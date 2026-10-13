import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// JLPT badge: 4 dp square, indigo tone per level, always shows "N5" text
/// (color is never the only signal, ui-design §4.1). [LevelBadge.topik]
/// labels a Korean course level instead.
class LevelBadge extends StatelessWidget {
  const LevelBadge(this.level, {super.key}) : _topik = false;

  /// Korean course level 1 (beginner) shows "TOPIK I" in the N5 tone,
  /// level 2 "TOPIK II" in the N3 tone.
  const LevelBadge.topik(this.level, {super.key}) : _topik = true;

  /// 5 (N5) … 1 (N1), or the Korean course level.
  final int level;
  final bool _topik;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = _topik ? (level <= 1 ? 5 : 3) : level;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: colors.jlptBg(tone), borderRadius: BorderRadius.circular(AppRadius.badge)),
      child: Text(
        _topik ? 'TOPIK ${level <= 1 ? 'I' : 'II'}' : 'N$level',
        style: AppText.label.copyWith(color: colors.jlptFg(tone)),
      ),
    );
  }
}
