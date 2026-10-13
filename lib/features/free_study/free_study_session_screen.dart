import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/speech.dart';
import '../../core/database/content_db.dart';
import '../../core/database/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/flip_card.dart';
import '../../core/widgets/game_card.dart';
import '../../core/widgets/hanko_stamp.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/speak_button.dart';
import '../../l10n/app_localizations.dart';
import '../kana/widgets/stroke_animation.dart';
import '../learn/path_providers.dart';
import '../learn/speech_text.dart';
import '../learn/study_language.dart';
import '../learn/vocab_path.dart';
import '../srs/srs_providers.dart';
import 'free_study_providers.dart';

/// Hafalan Bebas cards: tap to turn over, swipe right (or "Hafal") when it is
/// memorised, left (or "Belum") when not. No score, XP or pass mark; ↶ takes
/// back the last answer. The end offers the "Belum" cards again or adds them
/// to the daily review.
class FreeStudySessionScreen extends ConsumerStatefulWidget {
  const FreeStudySessionScreen({super.key, required this.items, this.meaningFirst = false});

  final List<Glyph> items;

  /// Ask with the reading or meaning and recall the Japanese.
  final bool meaningFirst;

  @override
  ConsumerState<FreeStudySessionScreen> createState() => _FreeStudySessionScreenState();
}

class _FreeStudySessionScreenState extends ConsumerState<FreeStudySessionScreen> {
  late List<Glyph> _items = widget.items;
  int _index = 0;
  bool _flipped = false;

  /// Answers of this round, for ↶ and the summary.
  final _answers = <({Glyph item, bool known, StudyMark? before})>[];
  bool _added = false;

  void _answer(bool known) {
    final item = _items[_index];
    final key = studyKey(item);
    final marks = ref.read(studyMarksProvider.notifier);
    _answers.add((item: item, known: known, before: ref.read(studyMarksProvider)[key]));
    marks.set(key, known ? StudyMark.known : StudyMark.notYet);
    HapticFeedback.selectionClick();
    setState(() {
      _index++;
      _flipped = false;
    });
  }

  void _flip() {
    setState(() => _flipped = true);
    autoSpeak(ref, speechText(_items[_index]));
  }

  void _undo() {
    final last = _answers.removeLast();
    ref.read(studyMarksProvider.notifier).set(studyKey(last.item), last.before);
    setState(() {
      _index--;
      _flipped = false;
    });
  }

  List<Glyph> get _notYet => [
    for (final a in _answers)
      if (!a.known) a.item,
  ];

  void _repeat() => setState(() {
    _items = _notYet;
    _index = 0;
    _flipped = false;
    _answers.clear();
    _added = false;
  });

  void _addToReview() {
    addLearnedCards(ref, _notYet);
    setState(() => _added = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final done = _index >= _items.length;
    // Loaded up front so the first card is read aloud straight away.
    ref.watch(speechAutoplayProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: done ? null : Text('${_index + 1} / ${_items.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: l10n.undo,
            onPressed: _answers.isEmpty ? null : _undo,
          ),
          const SizedBox(width: AppSpace.xs),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: _items.isEmpty ? 1 : _index / _items.length, minHeight: 6),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: done
              ? _Summary(
                  known: _answers.length - _notYet.length,
                  notYet: _notYet.length,
                  added: _added,
                  onRepeat: _repeat,
                  onAddToReview: _addToReview,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Dismissible(
                        key: ValueKey('card-$_index-${_items.length}'),
                        onDismissed: (direction) => _answer(direction == DismissDirection.startToEnd),
                        background: _SwipeHint(label: l10n.freeStudyKnown, color: c.success, start: true),
                        secondaryBackground: _SwipeHint(label: l10n.freeStudyNotYet, color: c.seal, start: false),
                        child: FlipCard(
                          flipped: _flipped,
                          onFlip: _flip,
                          front: _Face(item: _items[_index], back: false, meaningFirst: widget.meaningFirst),
                          back: _Face(item: _items[_index], back: true, meaningFirst: widget.meaningFirst),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.m),
                    Text(
                      l10n.freeStudySwipeHint,
                      textAlign: TextAlign.center,
                      style: AppText.bodySmall.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: AppSpace.m),
                    Row(
                      spacing: AppSpace.m,
                      children: [
                        Expanded(
                          child: ChunkyButton(
                            label: l10n.freeStudyNotYet,
                            icon: Icons.replay_rounded,
                            color: c.surfaceHigh,
                            textColor: c.ink,
                            onPressed: () => _answer(false),
                          ),
                        ),
                        Expanded(
                          child: ChunkyButton(
                            label: l10n.freeStudyKnown,
                            icon: Icons.check_rounded,
                            onPressed: () => _answer(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Shown under the card while it is swiped: "Hafal" on the left edge when
/// swiping right, "Belum" on the right edge when swiping left.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.label, required this.color, required this.start});
  final String label;
  final Color color;
  final bool start;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: color, width: 2),
    ),
    alignment: start ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
    child: Text(
      label,
      style: AppText.title2.copyWith(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

/// One side of a card. Front: the Japanese (or, with [meaningFirst], the
/// reading or meaning to recall it from). Back: everything about the item.
class _Face extends ConsumerWidget {
  const _Face({required this.item, required this.back, required this.meaningFirst});
  final Glyph item;
  final bool back;
  final bool meaningFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    const ja = Locale('ja');
    final literal = item.literal;
    final size = literal.length <= 2 ? 96.0 : (literal.length <= 4 ? 64.0 : 44.0);

    Widget card(List<Widget> children) => GameCard(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );

    if (!back && meaningFirst) {
      final (prompt, ask) = switch (item) {
        Kana k => (l10n.freeStudyRecallReading, k.romaji),
        Kanji k => (l10n.freeStudyRecallKanji, k.meanings.take(3).join(', ')),
        VocabWord w => (w.word.isKorean ? l10n.recallKorean : l10n.recallJapanese, w.word.gloss),
        _ => (l10n.recallJapanese, literal),
      };
      return card([
        Text(prompt, style: AppText.label.copyWith(color: c.inkMuted)),
        const SizedBox(height: AppSpace.m),
        Text(
          ask,
          textAlign: TextAlign.center,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: AppText.title1.copyWith(color: c.ink),
        ),
        const SizedBox(height: AppSpace.l),
        Text(l10n.tapToFlip, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
      ]);
    }

    final big = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        literal,
        locale: ja,
        style: AppText.displayCard.copyWith(fontSize: size, color: c.ink),
      ),
    );
    if (!back) {
      return card([
        big,
        const SizedBox(height: AppSpace.l),
        Text(l10n.tapToFlip, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
      ]);
    }

    final content = ref.watch(contentProvider).value;
    final dict = ref.watch(dictionaryProvider).value;
    // Hangul has no stroke data.
    Widget strokes() => content == null || literal.length > 2 || content.strokes(literal.characters.first).isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: AppSpace.l),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final ch in literal.characters)
                  StrokeAnimation(key: ValueKey('$literal-$ch'), paths: content.strokes(ch), size: 110),
              ],
            ),
          );
    // Tapping an example word reads it.
    Widget example(String headword, String? reading, String meaning) => InkWell(
      borderRadius: BorderRadius.circular(AppRadius.badge),
      onTap: () => ref.read(speechProvider).speak(reading ?? headword),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs, horizontal: AppSpace.s),
        child: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                  child: Icon(Icons.volume_up_rounded, size: 16, color: c.primaryText),
                ),
              ),
              TextSpan(
                text: headword,
                locale: ja,
                style: AppText.bodyJp.copyWith(color: c.ink),
              ),
              if (reading != null)
                TextSpan(
                  text: ' ($reading)',
                  locale: ja,
                  style: AppText.bodySmallJp.copyWith(color: c.inkMuted),
                ),
              TextSpan(
                text: '  $meaning',
                style: AppText.bodySmall.copyWith(color: c.inkMuted),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return card(switch (item) {
      Kana k => [
        big,
        Text(k.romaji, style: AppText.title1.copyWith(color: c.primaryText, fontSize: 32)),
        SpeakButton(speechText(k)),
        strokes(),
        if (k.exampleWordId case final id? when dict != null)
          if (dict.entry(id) case final e?) ...[
            const SizedBox(height: AppSpace.l),
            Text(l10n.exampleWord, style: AppText.label.copyWith(color: c.inkMuted)),
            example(e.headword, e.kanji == null ? null : e.kana, e.senses.firstOrNull?.gloss.split('; ').first ?? ''),
          ],
      ],
      Kanji k => [
        big,
        Text(
          k.meanings.take(3).join(', '),
          textAlign: TextAlign.center,
          style: AppText.title2.copyWith(color: c.primaryText),
        ),
        const SizedBox(height: AppSpace.s),
        Text(
          kanjiReadings(k),
          locale: ja,
          textAlign: TextAlign.center,
          style: AppText.bodyJp.copyWith(color: c.ink),
        ),
        SpeakButton(speechText(k)),
        strokes(),
        ..._kanjiExamples(ref, k, l10n, c, example),
      ],
      VocabWord w => [
        if (w.word.kanji != null)
          Text(
            w.word.kana,
            locale: ja,
            style: AppText.bodyJp.copyWith(fontSize: 22, color: c.inkMuted),
          ),
        big,
        const SizedBox(height: AppSpace.s),
        Wrap(
          spacing: AppSpace.m,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(w.word.romaji, style: AppText.body.copyWith(color: c.inkMuted)),
            if (w.word.jlpt > 0) LevelBadge(w.word.jlpt),
            SpeakButton(speechText(w), size: 24),
          ],
        ),
        const SizedBox(height: AppSpace.l),
        Text(
          w.word.gloss,
          textAlign: TextAlign.center,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: AppText.title2.copyWith(color: c.ink),
        ),
      ],
      _ => [big],
    });
  }

  /// Up to two JLPT words written with the kanji, shortest first.
  List<Widget> _kanjiExamples(
    WidgetRef ref,
    Kanji k,
    AppLocalizations l10n,
    AppColors c,
    Widget Function(String, String?, String) example,
  ) {
    final words = ref.watch(lessonWordsProvider).value ?? const [];
    final hits = [
      for (final w in words)
        if (w.kanji != null && w.kanji!.contains(k.literal) && w.kanji != k.literal) w,
    ]..sort((a, b) => a.kanji!.length.compareTo(b.kanji!.length));
    if (hits.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpace.l),
      Text(l10n.exampleWord, style: AppText.label.copyWith(color: c.inkMuted)),
      for (final w in hits.take(2)) example(w.kanji!, w.kana, w.gloss.split('; ').first),
    ];
  }
}

/// End of a round: what was memorised, the "Belum" cards again, or into the
/// daily review.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.known,
    required this.notYet,
    required this.added,
    required this.onRepeat,
    required this.onAddToReview,
  });

  final int known;
  final int notYet;
  final bool added;
  final VoidCallback onRepeat;
  final VoidCallback onAddToReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        // 済 all memorised · 習 some still to practise.
        Center(
          child: Consumer(
            builder: (context, ref, _) =>
                HankoStamp(character: resultStamp(ref.watch(studyLanguageProvider).value, passed: notYet == 0)),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Text(
          notYet == 0 ? l10n.freeStudyAllKnown : l10n.sessionDone,
          textAlign: TextAlign.center,
          style: AppText.title1.copyWith(color: c.ink),
        ),
        const SizedBox(height: AppSpace.m),
        Text(
          l10n.freeStudySummary(known, notYet),
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: c.inkMuted),
        ),
        const Spacer(),
        if (notYet > 0) ...[
          ChunkyButton(label: l10n.freeStudyRepeat(notYet), icon: Icons.replay_rounded, onPressed: onRepeat),
          const SizedBox(height: AppSpace.m),
          ChunkyButton(
            label: added ? l10n.freeStudyAdded : l10n.freeStudyAddToReview,
            icon: added ? Icons.check_rounded : Icons.style_rounded,
            color: c.surfaceHigh,
            textColor: c.ink,
            onPressed: added ? null : onAddToReview,
          ),
          const SizedBox(height: AppSpace.m),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.done,
            style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
