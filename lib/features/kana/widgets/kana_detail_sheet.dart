import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/speech.dart';
import '../../../core/database/content_db.dart';
import '../../../core/database/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/game_card.dart';
import '../../../core/widgets/speak_button.dart';
import '../../../l10n/app_localizations.dart';
import 'stroke_animation.dart';

/// Bottom sheet for one kana (ui-design §5.7): stroke-order animation,
/// romaji, stroke count, example word from the dictionary, "Latihan menulis".
class KanaDetailSheet extends ConsumerStatefulWidget {
  const KanaDetailSheet({super.key, required this.kana, required this.onPracticeWriting});

  final Kana kana;
  final VoidCallback? onPracticeWriting;

  static Future<void> show(BuildContext context, Kana kana, {VoidCallback? onPracticeWriting}) => showModalBottomSheet(
    context: context,
    // Above the tab bar, not inside the tab.
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => KanaDetailSheet(kana: kana, onPracticeWriting: onPracticeWriting),
  );

  @override
  ConsumerState<KanaDetailSheet> createState() => _KanaDetailSheetState();
}

class _KanaDetailSheetState extends ConsumerState<KanaDetailSheet> {
  final _animations = <GlobalKey<StrokeAnimationState>>[];

  @override
  void initState() {
    super.initState();
    autoSpeak(ref, widget.kana.literal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final content = ref.watch(contentProvider).value;
    final dictionary = ref.watch(dictionaryProvider).value;
    final chars = widget.kana.literal.characters.toList();
    final strokes = [for (final ch in chars) content?.strokes(ch) ?? const <String>[]];
    final total = strokes.fold<int>(0, (n, s) => n + s.length);
    final example = widget.kana.exampleWordId == null ? null : dictionary?.brief(widget.kana.exampleWordId!);
    while (_animations.length < chars.length) {
      _animations.add(GlobalKey());
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.kana.romaji, style: AppText.title1.copyWith(color: c.ink)),
                const SizedBox(width: AppSpace.m),
                Text(l10n.strokeCount(total), style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                const Spacer(),
                SpeakButton(widget.kana.literal),
                TextButton.icon(
                  onPressed: () => [for (final k in _animations) k.currentState?.replay()],
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.replay),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            GameCard(
              color: c.bg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < chars.length; i++)
                    if (strokes[i].isNotEmpty)
                      StrokeAnimation(key: _animations[i], paths: strokes[i], size: chars.length == 1 ? 220 : 150),
                ],
              ),
            ),
            if (example != null) ...[
              const SizedBox(height: AppSpace.l),
              Text(l10n.exampleWord, style: AppText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AppSpace.s),
              GameCard(
                child: Row(
                  children: [
                    Text(
                      example.headword,
                      locale: const Locale('ja'),
                      style: AppText.rowHeadword.copyWith(color: c.ink),
                    ),
                    const SizedBox(width: AppSpace.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (example.headword != example.kana)
                            Text(
                              example.kana,
                              locale: const Locale('ja'),
                              style: AppText.bodySmallJp.copyWith(color: c.inkMuted),
                            ),
                          Text(
                            example.gloss,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySmall.copyWith(color: c.ink),
                          ),
                        ],
                      ),
                    ),
                    SpeakButton(example.kana, size: 24),
                  ],
                ),
              ),
            ],
            if (widget.onPracticeWriting != null) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onPracticeWriting!();
                },
                icon: const Icon(Icons.edit_rounded),
                label: Text(l10n.practiceWriting),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
