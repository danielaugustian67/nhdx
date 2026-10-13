import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/providers.dart';
import '../../core/study_day.dart';
import '../../core/text/hangul.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/game_card.dart';
import '../../core/widgets/hanko_stamp.dart';
import '../../core/widgets/speak_button.dart';
import '../../l10n/app_localizations.dart';
import '../kana/games/kana_quiz.dart';
import '../kana/kana_providers.dart';
import '../learn/study_language.dart';

/// Stores one answer of a grammar or conjugation exercise: the attempt, and
/// XP (with combo) for today's goal. Returns the XP given.
int recordPracticeAnswer(
  WidgetRef ref, {
  required String type,
  required String itemId,
  required bool correct,
  required int combo,
}) {
  final xp = XpRules.forAnswer(correct: correct, comboBefore: combo);
  if (xp > 0) ref.read(kanaProgressProvider.notifier).addXp(xp);
  final date = todayStudyDate();
  writeUserDb(
    ref.read(userDbProvider.future),
    (db) => db.addAttempt(type: type, itemId: itemId, correct: correct, studyDate: date),
  );
  return xp;
}

/// Shown under the question once it is answered: right or the answer, a 🔊
/// for it and "Lanjut".
class AnswerFeedback extends StatelessWidget {
  const AnswerFeedback({
    super.key,
    required this.correct,
    required this.answer,
    this.speak,
    this.explanation,
    required this.onNext,
  });

  final bool correct;

  /// The right answer, shown when the pick was wrong.
  final String answer;

  /// Read aloud by the 🔊 (kana).
  final String? speak;

  /// Why, for grammar.
  final String? explanation;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final color = correct ? c.success : c.seal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpace.m, AppSpace.s, AppSpace.xs, AppSpace.s),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      correct ? l10n.correct : l10n.conjAnswerWas(answer),
                      locale: Locale(hasHangul(answer) ? 'ko' : 'ja'),
                      style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                    ),
                    if (explanation case final e? when e.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.xs),
                        child: Text(e, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                      ),
                  ],
                ),
              ),
              if (speak case final s?) SpeakButton(s, size: 24),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.m),
        ChunkyButton(label: l10n.next, icon: Icons.arrow_forward_rounded, onPressed: onNext),
      ],
    );
  }
}

/// One line of the "to go over again" list.
class PracticeMistake {
  const PracticeMistake(this.title, this.detail);
  final String title;
  final String detail;
}

/// End of a grammar or conjugation exercise: stamp, score, the mistakes, and
/// buttons to add them to the review, go again or finish.
class PracticeSummary extends StatelessWidget {
  const PracticeSummary({
    super.key,
    required this.correct,
    required this.total,
    required this.mistakes,
    required this.added,
    required this.onAddMistakes,
    required this.onAgain,
    this.korean = false,
  });

  final int correct;
  final int total;
  final List<PracticeMistake> mistakes;
  final bool added;
  final VoidCallback onAddMistakes;
  final VoidCallback onAgain;

  /// Korean practice: a Korean stamp and font.
  final bool korean;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final passed = total > 0 && correct / total >= 0.8;
    final locale = Locale(korean ? 'ko' : 'ja');
    return ListView(
      padding: const EdgeInsets.all(AppSpace.screen),
      children: [
        const SizedBox(height: AppSpace.l),
        Center(
          child: HankoStamp(character: resultStamp(korean ? StudyLanguage.ko : null, passed: passed)),
        ),
        const SizedBox(height: AppSpace.l),
        Text(
          l10n.conjScore(correct, total),
          textAlign: TextAlign.center,
          style: AppText.title1.copyWith(color: c.ink),
        ),
        if (mistakes.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xl),
          Text(l10n.conjMistakes, style: AppText.label.copyWith(color: c.inkMuted)),
          const SizedBox(height: AppSpace.s),
          GameCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Column(
              children: [
                for (final m in mistakes)
                  ListTile(
                    title: Text(
                      m.title,
                      locale: locale,
                      style: AppText.bodyJp.copyWith(color: c.ink),
                    ),
                    subtitle: Text(
                      m.detail,
                      locale: locale,
                      style: AppText.bodySmall.copyWith(color: c.inkMuted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.m),
          added
              ? OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.freeStudyAdded),
                )
              : OutlinedButton.icon(
                  onPressed: onAddMistakes,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.conjAddMistakes),
                ),
        ],
        const SizedBox(height: AppSpace.xl),
        ChunkyButton(label: l10n.tryAgain, icon: Icons.replay_rounded, onPressed: onAgain),
        const SizedBox(height: AppSpace.s),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.done)),
      ],
    );
  }
}
