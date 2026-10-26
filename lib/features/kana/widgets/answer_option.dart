import 'package:flutter/material.dart';

import '../../../core/text/hangul.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';

enum OptionState { idle, correct, wrong, dimmed }

/// Multiple-choice answer tile. Correct glows green, a wrong pick turns seal
/// and shows an icon (never color alone, ui-design §4.1).
class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.label,
    required this.isKana,
    required this.state,
    this.onTap,
    this.wrap = false,
    this.romaji,
  });

  final String label;
  final bool isKana;

  /// Long Latin text (a dictionary meaning) wraps onto two lines instead of
  /// shrinking to fit one.
  final bool wrap;
  final OptionState state;
  final VoidCallback? onTap;

  /// How a Japanese [label] reads, small under it.
  final String? romaji;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final korean = isKana && hasHangul(label);
    final (border, fill, icon) = switch (state) {
      OptionState.correct => (c.success, c.success.withValues(alpha: 0.16), Icons.check_circle_rounded),
      OptionState.wrong => (c.seal, c.seal.withValues(alpha: 0.14), Icons.cancel_rounded),
      OptionState.dimmed => (c.line, c.surface, null),
      OptionState.idle => (c.line, c.surfaceHigh, null),
    };
    return AnimatedContainer(
      duration: AppDurations.bookmark,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border, width: state == OptionState.idle ? 1 : 2),
        boxShadow: state == OptionState.correct
            ? [BoxShadow(color: c.success.withValues(alpha: 0.35), blurRadius: 18)]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
                  // Long meanings ("electricity") shrink instead of overflowing.
                  child: wrap && !isKana
                      ? Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            color: state == OptionState.dimmed ? c.inkMuted : c.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                locale: isKana ? Locale(korean ? 'ko' : 'ja') : null,
                                // The stroke font has no Hangul; the system Korean font draws it.
                                style: isKana
                                    ? TextStyle(fontFamily: korean ? null : AppFonts.jpStroke, fontSize: 34, color: c.ink)
                                    : AppText.title1.copyWith(color: state == OptionState.dimmed ? c.inkMuted : c.ink),
                              ),
                              if (romaji case final r? when r.isNotEmpty)
                                Text(r, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                            ],
                          ),
                        ),
                ),
              ),
              if (icon != null) Positioned(top: 8, right: 8, child: Icon(icon, size: 20, color: border)),
            ],
          ),
        ),
      ),
    );
  }
}
