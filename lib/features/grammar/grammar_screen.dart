import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/game_card.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/speak_button.dart';
import '../../l10n/app_localizations.dart';
import '../learn/path_providers.dart';
import '../srs/srs_providers.dart';
import 'grammar_practice_screen.dart';
import 'grammar_providers.dart';

/// Grammar points by level (PRD F13), each marked once its practice is
/// passed.
class GrammarScreen extends ConsumerWidget {
  const GrammarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final points = ref.watch(grammarProvider).value;
    final done = ref.watch(pathProgressProvider);
    final levels = {for (final p in points ?? const <GrammarPoint>[]) p.jlpt}.toList()..sort((a, b) => b - a);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.grammar),
        actions: [
          if (points != null && points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: l10n.grammarPracticeMixed,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GrammarPracticeScreen(points: _mixedPool(points, done)),
                  fullscreenDialog: true,
                ),
              ),
            ),
        ],
      ),
      body: points == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
              children: [
                Text(l10n.grammarBody, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                for (final level in levels) ...[
                  const SizedBox(height: AppSpace.l),
                  Row(
                    children: [
                      LevelBadge(level),
                      const SizedBox(width: AppSpace.s),
                      Text(
                        l10n.grammarDoneCount(
                          points.where((p) => p.jlpt == level && done.contains(grammarDoneKey(p.id))).length,
                          points.where((p) => p.jlpt == level).length,
                        ),
                        style: AppText.label.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s),
                  GameCard(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                    child: Column(
                      children: [
                        for (final (i, p) in points.where((p) => p.jlpt == level).indexed) ...[
                          if (i > 0) Divider(height: 1, indent: AppSpace.m, endIndent: AppSpace.m, color: c.line),
                          _PointTile(point: p, done: done.contains(grammarDoneKey(p.id))),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  /// Finished points when there are a few, else everything.
  static List<GrammarPoint> _mixedPool(List<GrammarPoint> points, Set<String> done) {
    final finished = [
      for (final p in points)
        if (done.contains(grammarDoneKey(p.id))) p,
    ];
    return finished.length >= 3 ? finished : points;
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({required this.point, required this.done});
  final GrammarPoint point;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return ListTile(
      title: Text(
        point.pattern,
        locale: const Locale('ja'),
        style: AppText.bodyJp.copyWith(color: c.ink, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(point.meaning.of(l10n.localeName), style: AppText.bodySmall.copyWith(color: c.inkMuted)),
      trailing: done
          ? Icon(Icons.check_circle_rounded, color: c.success, semanticLabel: l10n.grammarDone)
          : Icon(Icons.chevron_right_rounded, color: c.inkMuted),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GrammarPointScreen(point: point))),
    );
  }
}

/// One grammar point: pattern, meaning, formation, explanation, examples
/// with 🔊, then practice and a review card.
class GrammarPointScreen extends ConsumerWidget {
  const GrammarPointScreen({super.key, required this.point});
  final GrammarPoint point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    const ja = Locale('ja');
    final lang = l10n.localeName;
    final done = ref.watch(pathProgressProvider).contains(grammarDoneKey(point.id));
    final inReview = ref.watch(grammarCardIdsProvider).value?.contains(point.id) ?? false;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.l, bottom: AppSpace.s),
      child: Text(title, style: AppText.label.copyWith(color: c.inkMuted)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(point.pattern, locale: ja),
        actions: [
          if (done)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.m),
              child: Icon(Icons.check_circle_rounded, color: c.success, semanticLabel: l10n.grammarDone),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.l),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.pattern,
                          locale: ja,
                          style: AppText.displayCard.copyWith(fontSize: 32, color: c.ink),
                        ),
                      ),
                      LevelBadge(point.jlpt),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(point.meaning.of(lang), style: AppText.title2.copyWith(color: c.primaryText)),
                  section(l10n.grammarFormation),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.m),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Text(
                      point.formation,
                      locale: ja,
                      style: AppText.bodyJp.copyWith(color: c.ink),
                    ),
                  ),
                  section(l10n.grammarExplanation),
                  Text(point.explanation.of(lang), style: AppText.body.copyWith(color: c.ink)),
                  section(l10n.grammarExamples),
                  for (final e in point.examples)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.s),
                      child: GameCard(
                        padding: const EdgeInsets.fromLTRB(AppSpace.m, AppSpace.s, AppSpace.xs, AppSpace.s),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.japanese,
                                    locale: ja,
                                    style: AppText.bodyJp.copyWith(color: c.ink),
                                  ),
                                  if (e.kana != e.japanese)
                                    Text(
                                      e.kana,
                                      locale: ja,
                                      style: AppText.bodySmallJp.copyWith(color: c.inkMuted),
                                    ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(e.translation.of(lang), style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                                ],
                              ),
                            ),
                            SpeakButton(e.kana, size: 24),
                          ],
                        ),
                      ),
                    ),
                  if (!done)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.s),
                      child: Text(l10n.grammarPassToFinish, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.screen),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: inReview
                          ? null
                          : () => addPracticeCards(ref, 'grammar', [(id: point.id, label: point.pattern)]),
                      icon: Icon(inReview ? Icons.check_rounded : Icons.add_rounded),
                      label: Text(inReview ? l10n.grammarInReview : l10n.grammarAddReview),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: ChunkyButton(
                      label: l10n.grammarPractice,
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GrammarPracticeScreen(points: [point]),
                          fullscreenDialog: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
