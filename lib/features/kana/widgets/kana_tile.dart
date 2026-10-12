import 'package:flutter/material.dart';

import '../../../core/database/content_db.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';

/// Kana table tile: Klee One character + romaji; weak kana get a small seal
/// dot (with a semantic label, so color is not the only signal).
class KanaTile extends StatelessWidget {
  const KanaTile({super.key, required this.kana, this.weak = false, this.onTap});

  final Kana kana;
  final bool weak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '${kana.literal} ${kana.romaji}${weak ? ', perlu latihan' : ''}',
      excludeSemantics: true,
      child: Material(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kana.literal,
                      locale: const Locale('ja'),
                      style: TextStyle(
                        fontFamily: AppFonts.jpStroke,
                        fontSize: kana.isYoon ? 24 : 28,
                        height: 1.2,
                        color: c.ink,
                      ),
                    ),
                    Text(kana.romaji, style: AppText.label.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              if (weak)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: c.seal, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
