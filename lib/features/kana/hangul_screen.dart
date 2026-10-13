import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/game_card.dart';
import '../../l10n/app_localizations.dart';
import '../learn/path_providers.dart';
import 'kana_providers.dart';
import 'kana_screen.dart';
import 'widgets/kana_detail_sheet.dart';
import 'widgets/kana_tile.dart';

/// Hangul as shown by the filter: letters by kind, or syllables.
enum HangulGroup {
  vowels({'vowel'}),
  consonants({'consonant'}),
  syllables({'syllable', 'final'});

  const HangulGroup(this.kinds);
  final Set<String> kinds;
}

/// The Kana tab while learning Korean: a filter, three games (no writing:
/// Hangul has no stroke data) and the chart of the chosen letters.
class HangulScreen extends ConsumerStatefulWidget {
  const HangulScreen({super.key});

  @override
  ConsumerState<HangulScreen> createState() => _HangulScreenState();
}

class _HangulScreenState extends ConsumerState<HangulScreen> {
  var _group = HangulGroup.vowels;

  static const _perRow = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final all = ref.watch(hangulProvider).value?.letters ?? const <Kana>[];
    final shown = [
      for (final k in all)
        if (_group.kinds.contains(k.kind)) k,
    ];
    final weak = ref.watch(kanaProgressProvider.select((p) => p.weakIds));
    final games = [
      (KanaGame.quiz, Icons.quiz_rounded, l10n.gameQuiz, l10n.gameQuizBody, c.primaryText, shown.length >= 4),
      (KanaGame.match, Icons.grid_view_rounded, l10n.gameMatch, l10n.gameMatchBody, c.accent, shown.length >= 6),
      (KanaGame.speed, Icons.bolt_rounded, l10n.gameSpeed, l10n.gameSpeedBody, c.gold, shown.length >= 4),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hangul)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.xxl),
        children: [
          SegmentedButton<HangulGroup>(
            segments: [
              ButtonSegment(value: HangulGroup.vowels, label: Text('ㅏ ${l10n.hangulVowels}')),
              ButtonSegment(value: HangulGroup.consonants, label: Text('ㄱ ${l10n.hangulConsonants}')),
              ButtonSegment(value: HangulGroup.syllables, label: Text('가 ${l10n.hangulSyllables}')),
            ],
            selected: {_group},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _group = s.first),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(l10n.games, style: AppText.title2.copyWith(color: c.ink)),
          const SizedBox(height: AppSpace.m),
          for (final (i, (game, icon, title, body, color, enabled)) in games.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpace.s),
            GameCard(
              enabled: enabled,
              semanticLabel: '$title. $body',
              onTap: () => KanaScreen.openGame(context, game, shown),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpace.s),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                        ),
                        Text(body, style: AppText.label.copyWith(color: c.inkMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          Text(l10n.hangulTable, style: AppText.title2.copyWith(color: c.ink)),
          const SizedBox(height: AppSpace.m),
          for (var start = 0; start < shown.length; start += _perRow)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s),
              child: Row(
                children: [
                  for (var i = start; i < start + _perRow; i++) ...[
                    if (i > start) const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 0.95,
                        child: i >= shown.length
                            ? const SizedBox()
                            : KanaTile(
                                kana: shown[i],
                                weak: weak.contains(shown[i].id),
                                onTap: () => KanaDetailSheet.show(context, shown[i]),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
