import 'package:flutter/material.dart';

import '../../../core/database/content_db.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/game_card.dart';
import '../../../core/widgets/hanko_stamp.dart';
import '../../../l10n/app_localizations.dart';
import '../../learn/study_language.dart';

/// End-of-game screen shared by all kana games (ui-design §5.7): glowing
/// stamp, XP, accuracy, kana to practice, "Main lagi" / "Selesai".
class GameResultView extends StatelessWidget {
  const GameResultView({
    super.key,
    required this.xp,
    required this.accuracy,
    this.detail,
    this.weak = const [],
    this.passMark,
    this.korean = false,
    required this.onPlayAgain,
  });

  final int xp;

  /// 0–1
  final double accuracy;

  /// Minimum [accuracy] (0–1) for a learning-path lesson to count as passed.
  /// Null for free play, where any finished session is done.
  final double? passMark;

  /// Extra line, e.g. "14 langkah" or "Combo ×12".
  final String? detail;
  final List<Glyph> weak;

  /// A Hangul game or Korean lesson: the stamp is in Korean.
  final bool korean;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final mark = passMark;
    final passed = mark == null || accuracy >= mark - 1e-9;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            const Spacer(),
            // 済 "done" when passed, 習 "practice" when the lesson must be retried.
            HankoStamp(character: resultStamp(korean ? StudyLanguage.ko : StudyLanguage.ja, passed: passed)),
            const SizedBox(height: AppSpace.xl),
            Text(passed ? l10n.sessionDone : l10n.almostThere, style: AppText.title1.copyWith(color: c.ink)),
            const SizedBox(height: AppSpace.l),
            // Wraps on narrow screens / large text instead of overflowing.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpace.m,
              runSpacing: AppSpace.s,
              children: [
                _Stat(value: l10n.xpGained(xp), color: c.gold),
                _Stat(value: l10n.accuracyPercent((accuracy * 100).round()), color: passed ? c.success : c.seal),
              ],
            ),
            if (!passed) ...[
              const SizedBox(height: AppSpace.m),
              Text(
                l10n.passMarkNeeded((mark * 100).round()),
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.ink),
              ),
            ],
            if (detail != null) ...[
              const SizedBox(height: AppSpace.m),
              Text(detail!, style: AppText.body.copyWith(color: c.inkMuted)),
            ],
            if (weak.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xl),
              Text(l10n.needsPractice, style: AppText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AppSpace.s),
              Wrap(
                spacing: AppSpace.s,
                runSpacing: AppSpace.s,
                alignment: WrapAlignment.center,
                children: [
                  for (final k in weak.take(8))
                    GameCard(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.m, vertical: AppSpace.s),
                      borderColor: c.seal.withValues(alpha: 0.6),
                      radius: AppRadius.control,
                      child: Text(
                        k.literal,
                        locale: const Locale('ja'),
                        style: AppText.title2.copyWith(fontFamily: AppFonts.jpStroke, color: c.ink),
                      ),
                    ),
                ],
              ),
            ],
            const Spacer(),
            // `true` tells the learning path the node was completed; quitting
            // with ✕ (or below the pass mark) pops without a result.
            if (passed) ...[
              ChunkyButton(label: l10n.done, onPressed: () => Navigator.of(context).pop(true)),
              const SizedBox(height: AppSpace.m),
              OutlinedButton(onPressed: onPlayAgain, child: Text(l10n.playAgain)),
            ] else ...[
              ChunkyButton(label: l10n.tryAgain, onPressed: onPlayAgain),
              const SizedBox(height: AppSpace.m),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.quit)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.color});
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.s),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.control),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(value, style: AppText.title2.copyWith(color: color)),
  );
}
