import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/game_card.dart';
import '../../l10n/app_localizations.dart';
import '../search/quick_search.dart';
import 'games/memory_match_screen.dart';
import 'games/quiz_screen.dart';
import 'games/speed_drill_screen.dart';
import 'games/writing_screen.dart';
import 'kana_layout.dart';
import 'kana_providers.dart';
import 'widgets/kana_detail_sheet.dart';
import 'widgets/kana_tile.dart';

enum KanaGame { quiz, match, speed, write }

/// Kana module (ui-design §5.7): script switch, four games, gojūon table.
class KanaScreen extends ConsumerWidget {
  const KanaScreen({super.key});

  static Future<void> openGame(BuildContext context, KanaGame game, List<Kana> pool, {Kana? start}) {
    final page = switch (game) {
      KanaGame.quiz => QuizScreen(pool: pool),
      KanaGame.match => MemoryMatchScreen(pool: pool),
      KanaGame.speed => SpeedDrillScreen(pool: pool),
      KanaGame.write => WritingScreen(pool: pool, start: start),
    };
    // Games cover the bottom navigation, like lessons on Hari ini.
    return Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => page, fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final selection = ref.watch(kanaSelectionProvider);
    final kana = ref.watch(selectedKanaProvider).value ?? const <Kana>[];
    final weak = ref.watch(kanaProgressProvider.select((p) => p.weakIds));
    final writable = kana.where((k) => !k.isYoon).toList();
    final notifier = ref.read(kanaSelectionProvider.notifier);

    final games = [
      (KanaGame.quiz, Icons.quiz_rounded, l10n.gameQuiz, l10n.gameQuizBody, c.primaryText, kana.length >= 4),
      (KanaGame.match, Icons.grid_view_rounded, l10n.gameMatch, l10n.gameMatchBody, c.accent, kana.length >= 6),
      (KanaGame.speed, Icons.bolt_rounded, l10n.gameSpeed, l10n.gameSpeedBody, c.gold, kana.length >= 4),
      (KanaGame.write, Icons.draw_rounded, l10n.gameWrite, l10n.gameWriteBody, c.success, writable.isNotEmpty),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moduleKana), actions: const [QuickSearchButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.xxl),
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'hiragana', label: Text('あ  ${l10n.hiragana}')),
              ButtonSegment(value: 'katakana', label: Text('ア  ${l10n.katakana}')),
            ],
            selected: {selection.script},
            showSelectedIcon: false,
            onSelectionChanged: (s) => notifier.setScript(s.first),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(l10n.games, style: AppText.title2.copyWith(color: c.ink)),
          const SizedBox(height: AppSpace.m),
          // Two per row; a row grows with its text (small phones, large text).
          for (var row = 0; row < games.length; row += 2) ...[
            if (row > 0) const SizedBox(height: AppSpace.m),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, (game, icon, title, body, color, enabled)) in games.skip(row).take(2).indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpace.m),
                    Expanded(
                      child: GameCard(
                        enabled: enabled,
                        semanticLabel: '$title. $body',
                        onTap: () => openGame(context, game, game == KanaGame.write ? writable : kana),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 88),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpace.s),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(AppRadius.control),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(height: AppSpace.s),
                              const Spacer(),
                              Text(
                                title,
                                style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.label.copyWith(color: c.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          Wrap(
            spacing: AppSpace.s,
            children: [
              for (final (group, label) in [
                (KanaGroup.basic, l10n.kindBasic),
                (KanaGroup.dakuten, l10n.kindDakuten),
                (KanaGroup.yoon, l10n.kindYoon),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: selection.group == group,
                  onSelected: (_) => notifier.setGroup(group),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          for (final row in gojuonRows(kana))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s),
              child: Row(
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: row.length == 3 ? 1.5 : 0.95,
                        child: row[i] == null
                            ? const SizedBox()
                            : KanaTile(
                                kana: row[i]!,
                                weak: weak.contains(row[i]!.id),
                                onTap: () => KanaDetailSheet.show(
                                  context,
                                  row[i]!,
                                  onPracticeWriting: row[i]!.isYoon
                                      ? null
                                      : () => openGame(context, KanaGame.write, writable, start: row[i]),
                                ),
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
