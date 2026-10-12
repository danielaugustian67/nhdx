import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/level_badge.dart';
import '../../l10n/app_localizations.dart';
import '../kana/kana_providers.dart';
import '../kana/widgets/stroke_animation.dart';
import 'lesson.dart';
import 'lesson_screen.dart';
import 'vocab_path.dart';

/// "Kenali …" lesson (ui-design §5.2): one card per new kana or kanji with
/// its stroke order, then a [LessonScreen] in [mode]. Pops `true` when passed.
class LessonIntroScreen extends ConsumerStatefulWidget {
  const LessonIntroScreen({
    super.key,
    required this.items,
    required this.lesson,
    this.mode = LessonMode.mixed,
    this.passMark,
  });

  final List<Glyph> items;
  final LessonBuilder lesson;
  final LessonMode mode;

  /// Minimum lesson accuracy to pass.
  final double? passMark;

  @override
  ConsumerState<LessonIntroScreen> createState() => _LessonIntroScreenState();
}

class _LessonIntroScreenState extends ConsumerState<LessonIntroScreen> {
  int _index = 0;
  bool _exercises = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    final vocab = item is VocabWord;
    if (_exercises) {
      return LessonScreen(
        passMark: widget.passMark,
        exercises: () => widget.lesson.build(
          widget.mode,
          // A word lesson has ~10 words; each comes up about once.
          count: vocab ? 12 : (widget.items.length * 2).clamp(6, 10),
          weakIds: ref.read(kanaProgressProvider).weakIds,
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final content = vocab ? null : ref.watch(contentProvider).value;
    final last = _index == widget.items.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(vocab ? l10n.newWords : l10n.newCharacters),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: (_index + 1) / (widget.items.length + 1), minHeight: 8),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpace.l),
                      if (item case VocabWord(:final word) when word.kanji != null)
                        Text(
                          word.kana,
                          locale: const Locale('ja'),
                          style: AppText.bodyJp.copyWith(fontSize: 22, color: c.inkMuted),
                        ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.literal,
                          locale: const Locale('ja'),
                          style: TextStyle(
                            fontFamily: AppFonts.jpStroke,
                            fontSize: vocab ? 72 : 112,
                            height: 1.1,
                            color: c.ink,
                          ),
                        ),
                      ),
                      switch (item) {
                        VocabWord v => _WordInfo(word: v.word),
                        Kanji k => _KanjiInfo(kanji: k),
                        Kana k => Text(k.romaji, style: AppText.title1.copyWith(color: c.primaryText, fontSize: 32)),
                        _ => const SizedBox.shrink(),
                      },
                      const SizedBox(height: AppSpace.xl),
                      if (content != null)
                        Container(
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: c.line),
                          ),
                          padding: const EdgeInsets.all(AppSpace.m),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final ch in item.literal.characters)
                                StrokeAnimation(
                                  key: ValueKey('${item.id}-$ch'),
                                  paths: content.strokes(ch),
                                  size: item.literal.length == 1 ? 170 : 130,
                                  // Kanji have up to ~16 strokes; keep the replay short.
                                  perStroke: Duration(milliseconds: item is Kanji ? 420 : 650),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.m),
              ChunkyButton(
                label: last ? l10n.startQuiz : l10n.next,
                onPressed: () => setState(() => last ? _exercises = true : _index++),
              ),
              const SizedBox(height: AppSpace.s),
            ],
          ),
        ),
      ),
    );
  }
}

/// Romaji, JLPT level and meaning under a word card.
class _WordInfo extends StatelessWidget {
  const _WordInfo({required this.word});
  final DictWord word;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        const SizedBox(height: AppSpace.s),
        Wrap(
          spacing: AppSpace.m,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(word.romaji, style: AppText.body.copyWith(color: c.inkMuted)),
            LevelBadge(word.jlpt),
          ],
        ),
        const SizedBox(height: AppSpace.l),
        Text(
          word.gloss,
          textAlign: TextAlign.center,
          style: AppText.title1.copyWith(color: c.primaryText),
        ),
      ],
    );
  }
}

/// Meaning, on'yomi and kun'yomi under a kanji card.
class _KanjiInfo extends StatelessWidget {
  const _KanjiInfo({required this.kanji});
  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    Widget reading(String label, List<String> values) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: AppText.label.copyWith(color: c.inkMuted)),
          ),
          Flexible(
            child: Text(
              // ひと.つ → ひと(つ): okurigana in brackets.
              values.take(4).map((v) => v.contains('.') ? '${v.replaceFirst('.', '(')})' : v).join('、'),
              locale: const Locale('ja'),
              style: AppText.body.copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        Text(
          kanji.meanings.take(3).join(', '),
          textAlign: TextAlign.center,
          style: AppText.title1.copyWith(color: c.primaryText),
        ),
        const SizedBox(height: AppSpace.s),
        if (kanji.onyomi.isNotEmpty) reading(l10n.onyomi, kanji.onyomi),
        if (kanji.kunyomi.isNotEmpty) reading(l10n.kunyomi, kanji.kunyomi),
      ],
    );
  }
}
