import 'package:flutter/material.dart';

import '../../../core/text/hangul.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/level_badge.dart';
import '../search_service.dart';

/// Search result row (ui-design §4.5): no card, no shadow; separated by a
/// 1 dp line in the list. Exact matches get a 3 dp primary bar on the left.
/// [trailing] holds the bookmark button.
class WordRow extends StatelessWidget {
  const WordRow({super.key, required this.hit, this.onTap, this.trailing});

  final SearchHit hit;
  final VoidCallback? onTap;
  final Widget? trailing;

  static const _ja = Locale('ja');
  static const _ko = Locale('ko');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = AppText.bodySmall.copyWith(color: colors.inkMuted);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.wordRowMinHeight),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: AppSizes.exactMatchBar, color: hit.isExact ? colors.primary : Colors.transparent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen - AppSizes.exactMatchBar,
                    AppSpace.m,
                    AppSpace.screen,
                    AppSpace.m,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hit.headword,
                              locale: hasHangul(hit.headword) ? _ko : _ja,
                              style: AppText.rowHeadword.copyWith(color: colors.ink),
                            ),
                          ),
                          if (hit.jlptLevel != null) LevelBadge(hit.jlptLevel!),
                        ],
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            if (hit.kanji != null) ...[
                              TextSpan(
                                text: hit.kana,
                                locale: _ja,
                                style: AppText.bodySmallJp.copyWith(color: colors.inkMuted),
                              ),
                              const WidgetSpan(child: SizedBox(width: AppSpace.m)),
                            ],
                            TextSpan(text: hit.romaji),
                          ],
                        ),
                        style: muted,
                      ),
                      if (hit.gloss.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          hit.gloss,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(color: colors.ink),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing case final t?)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.xs),
                  child: Center(child: t),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
