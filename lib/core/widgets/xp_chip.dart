import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// "⚡ 120 XP" pill in gold (rewards color, ui-design §4.1).
class XpChip extends StatelessWidget {
  const XpChip(this.xp, {super.key});
  final int xp;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.m, vertical: AppSpace.xs + 2),
      decoration: BoxDecoration(
        color: c.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 18, color: c.gold),
          const SizedBox(width: AppSpace.xs),
          Text(
            AppLocalizations.of(context).xpAmount(xp),
            style: AppText.label.copyWith(color: c.gold, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
