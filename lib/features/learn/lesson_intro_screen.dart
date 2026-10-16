import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/speech.dart';
import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../../core/text/kana_romaji.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/speak_button.dart';
import '../../l10n/app_localizations.dart';
import '../kana/kana_providers.dart';
import '../kana/widgets/stroke_animation.dart';
import 'lesson.dart';
import 'lesson_screen.dart';
import 'speech_text.dart';
import 'vocab_path.dart';

/// "Kenali …" lesson (ui-design §5.2). Each new kana, kanji or word gets a
/// card (stroke order, reading, audio), then ungraded practice: write it,
/// then read it ([LessonBuilder.practice]). Back / Next move freely and any
/// practice can be retried. After the last item comes the graded quiz, a
/// [LessonScreen] in [mode]; it pops `true` when passed.
class LessonIntroScreen extends ConsumerStatefulWidget {
  const LessonIntroScreen({
    super.key,
    required this.items,
    required this.lesson,
    this.mode = LessonMode.quiz,
    this.passMark,
    this.progressKey,
    this.replay = false,
  });

  final List<Glyph> items;
  final LessonBuilder lesson;
  final LessonMode mode;

  /// Minimum lesson accuracy to pass.
  final double? passMark;

  /// Path node id: where the practice was left is kept on this device.
  final String? progressKey;

  /// A finished node: start from the first card, with a shortcut to the quiz.
  final bool replay;

  @override
  ConsumerState<LessonIntroScreen> createState() => _LessonIntroScreenState();
}

/// Device setting holding the practice step reached in node [nodeId].
String introProgressKey(String nodeId) => 'device.introStep.$nodeId';

/// Forgets where node [nodeId]'s practice was left (after passing its quiz).
Future<void> clearIntroProgress(WidgetRef ref, String nodeId) async {
  try {
    await (await ref.read(userDbProvider.future)).setSetting(introProgressKey(nodeId), null);
  } catch (e) {
    debugPrint('LessonIntro: progress not cleared ($e)');
  }
}

enum _StepKind { card, write, read }

/// One page of the intro: [item]'s card or one of its practice exercises.
class _Step {
  const _Step(this.item, this.kind, [this.exercise]);
  final int item;
  final _StepKind kind;
  final Exercise? exercise;
}

class _LessonIntroScreenState extends ConsumerState<LessonIntroScreen> {
  late final List<_Step> _steps = [
    for (final (i, item) in widget.items.indexed) ...[
      _Step(i, _StepKind.card),
      for (final ex in widget.lesson.practice(item))
        _Step(i, ex is WriteExercise ? _StepKind.write : _StepKind.read, ex),
    ],
  ];
  int _step = 0;
  bool _quiz = false;

  /// Bumped to rebuild a practice exercise from scratch ("Ulangi").
  int _attempt = 0;
  LessonOutcome? _outcome;

  /// Items answered wrong in a failed quiz, marked on their cards.
  Set<int> _weak = {};

  /// Set once the user moves, so a late restore does not jump.
  bool _moved = false;

  @override
  void initState() {
    super.initState();
    autoSpeak(ref, speechText(widget.items.first));
    if (widget.progressKey != null && !widget.replay) _restore();
  }

  Future<void> _restore() async {
    try {
      final db = await ref.read(userDbProvider.future);
      final saved = int.tryParse(await db.setting(introProgressKey(widget.progressKey!)) ?? '');
      if (!mounted || _moved || saved == null || saved <= 0 || saved >= _steps.length) return;
      setState(() => _step = saved);
    } catch (e) {
      debugPrint('LessonIntro: progress not restored ($e)');
    }
  }

  void _save() {
    final key = widget.progressKey;
    if (key == null) return;
    ref.read(userDbProvider.future).then((db) => db.setSetting(introProgressKey(key), '$_step')).catchError((Object e) {
      debugPrint('LessonIntro: progress not saved ($e)');
    });
  }

  void _go(int step) {
    _moved = true;
    setState(() {
      _step = step;
      _outcome = null;
      _attempt++;
    });
    _save();
    final s = _steps[step];
    if (s.kind == _StepKind.card) autoSpeak(ref, speechText(widget.items[s.item]));
  }

  void _startQuiz() {
    _moved = true;
    setState(() => _quiz = true);
  }

  void _backToPractice(Set<Glyph> weak) {
    final ids = {for (final g in weak) g.id};
    final first = widget.items.indexWhere((g) => ids.contains(g.id));
    setState(() {
      _quiz = false;
      _weak = ids;
    });
    _go(first < 0 ? 0 : _steps.indexWhere((s) => s.item == first));
  }

  void _practiced(bool correct, {required String title, String? detail, DictWord? word}) {
    correct ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
    setState(() => _outcome = LessonOutcome(correct: correct, title: title, detail: detail, word: word));
    // Hear the reading just typed.
    final s = _steps[_step];
    if (s.kind == _StepKind.read) autoSpeak(ref, speechText(widget.items[s.item]));
  }

  @override
  Widget build(BuildContext context) {
    if (_quiz) {
      final vocab = widget.items.first is VocabWord;
      return LessonScreen(
        passMark: widget.passMark,
        exercises: () => widget.lesson.build(
          widget.mode,
          // A word lesson has ~10 words; each comes up about once.
          count: vocab ? 12 : (widget.items.length * 2).clamp(6, 10),
          weakIds: ref.read(kanaProgressProvider).weakIds,
        ),
        onBackToPractice: _backToPractice,
      );
    }

    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final step = _steps[_step];
    final last = _step == _steps.length - 1;
    final stepName = switch (step.kind) {
      _StepKind.card => l10n.stepLearn,
      _StepKind.write => l10n.stepWrite,
      _StepKind.read => l10n.stepRead,
    };
    // Loaded up front so the first card is read aloud straight away.
    ref.watch(speechAutoplayProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.introStep(step.item + 1, widget.items.length, stepName)),
        actions: [
          if (widget.replay)
            TextButton(
              onPressed: _startQuiz,
              child: Text(
                l10n.goToQuiz,
                style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: AppSpace.xs),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: (_step + 1) / (_steps.length + 1), minHeight: 8),
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
                child: step.exercise == null
                    ? _card(context, widget.items[step.item])
                    : KeyedSubtree(
                        key: ValueKey('$_step-$_attempt'),
                        child: ExerciseView(exercise: step.exercise!, answered: _outcome != null, onAnswer: _practiced),
                      ),
              ),
              if (_outcome case final o?) _PracticeFeedback(outcome: o, onRetry: () => _go(_step)),
              const SizedBox(height: AppSpace.m),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: _step == 0 ? null : () => _go(_step - 1), child: Text(l10n.back)),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    flex: 2,
                    child: ChunkyButton(
                      label: last ? l10n.startQuiz : l10n.next,
                      onPressed: last ? _startQuiz : () => _go(_step + 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Glyph item) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final vocab = item is VocabWord;
    // Stroke order for kana and kanji; Hangul has no stroke data.
    final content = vocab || (item is Kana && item.isHangul) ? null : ref.watch(contentProvider).value;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_weak.contains(item.id))
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s),
              child: Chip(
                avatar: Icon(Icons.refresh_rounded, size: 18, color: c.seal),
                label: Text(l10n.needsReview, style: AppText.label.copyWith(color: c.seal)),
                side: BorderSide(color: c.seal.withValues(alpha: 0.6)),
              ),
            ),
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
              style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: vocab ? 72 : 112, height: 1.1, color: c.ink),
            ),
          ),
          switch (item) {
            VocabWord v => _WordInfo(word: v.word),
            Kanji k => _KanjiInfo(kanji: k),
            Kana k => Text(k.romaji, style: AppText.title1.copyWith(color: c.primaryText, fontSize: 32)),
            _ => const SizedBox.shrink(),
          },
          SpeakButton(speechText(item), size: 32),
          const SizedBox(height: AppSpace.m),
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
    );
  }
}

/// Verdict of a practice exercise, with "Ulangi" to try it again.
class _PracticeFeedback extends StatelessWidget {
  const _PracticeFeedback({required this.outcome, required this.onRetry});
  final LessonOutcome outcome;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final tone = outcome.correct ? c.success : c.seal;
    return Container(
      margin: const EdgeInsets.only(top: AppSpace.m),
      padding: const EdgeInsets.fromLTRB(AppSpace.m, AppSpace.s, AppSpace.xs, AppSpace.s),
      decoration: BoxDecoration(
        color: Color.alphaBlend(tone.withValues(alpha: 0.14), c.surface),
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(outcome.correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: tone),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outcome.title,
                  locale: const Locale('ja'),
                  style: AppText.title2.copyWith(color: tone, fontWeight: FontWeight.w700),
                ),
                if (outcome.detail case final d?) Text(d, style: AppText.bodySmall.copyWith(color: c.ink)),
              ],
            ),
          ),
          TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(l10n.practiceAgain)),
        ],
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
            if (word.jlpt > 0) LevelBadge(word.jlpt),
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

/// ひと.つ → ひと(つ): okurigana in brackets.
String _okurigana(String reading) => reading.contains('.') ? '${reading.replaceFirst('.', '(')})' : reading;

/// Meaning, on'yomi and kun'yomi (with romaji) under a kanji card.
class _KanjiInfo extends StatelessWidget {
  const _KanjiInfo({required this.kanji});
  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    Widget reading(String label, List<String> values) {
      final shown = values.take(4).toList();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Text(label, style: AppText.label.copyWith(color: c.inkMuted)),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shown.map(_okurigana).join('、'),
                    locale: const Locale('ja'),
                    style: AppText.body.copyWith(color: c.ink),
                  ),
                  Text(
                    shown.map((v) => readingToRomaji(_okurigana(v))).join(', '),
                    style: AppText.bodySmall.copyWith(color: c.primaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
