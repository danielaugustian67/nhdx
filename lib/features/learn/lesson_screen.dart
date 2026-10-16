import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../../core/svg/svg_path.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/xp_chip.dart';
import '../../l10n/app_localizations.dart';
import '../kana/games/game_result_view.dart';
import '../kana/games/kana_quiz.dart';
import '../kana/kana_providers.dart';
import '../kana/widgets/answer_option.dart';
import '../kana/widgets/ink_painter.dart';
import '../kana/widgets/stroke_animation.dart';
import '../kana/writing/stroke_scorer.dart';
import 'lesson.dart';
import 'study_language.dart';

/// One lesson of mixed exercises (ui-design §5.2): multiple choice, writing,
/// spelling a dictionary word with kana tiles, reading one in romaji. Every
/// answer gets a feedback bar with "Lanjut"; the result screen pops `true`
/// when [passMark] is reached.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.exercises, this.passMark, this.onBackToPractice});

  /// Called again for "Coba lagi" so a retry gets fresh questions.
  final List<Exercise> Function() exercises;
  final double? passMark;

  /// Offered when the pass mark is missed: back to the intro's practice,
  /// with the items answered wrong.
  final ValueChanged<Set<Glyph>>? onBackToPractice;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

/// How an answered exercise went, for the feedback bar.
class LessonOutcome {
  const LessonOutcome({required this.correct, required this.title, this.detail, this.word});
  final bool correct;
  final String title;
  final String? detail;
  final DictWord? word;
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late List<Exercise> _items;
  int _index = 0;
  LessonOutcome? _outcome;
  int _xp = 0;
  int _correct = 0;
  final _weak = <Glyph>{};

  static const _writeXp = 15;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _items = widget.exercises();
    _index = _xp = _correct = 0;
    _outcome = null;
    _weak.clear();
  }

  void _answer(bool correct, {required String title, String? detail, DictWord? word}) {
    final ex = _items[_index];
    final xp = !correct ? 0 : (ex is WriteExercise ? _writeXp : XpRules.perCorrect);
    final progress = ref.read(kanaProgressProvider.notifier);
    for (final (i, g) in ex.items.indexed) {
      progress.record(g, correct: correct, xp: i == 0 ? xp : 0);
    }
    if (ex.items.isEmpty) progress.addXp(xp);
    correct ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
    setState(() {
      _xp += xp;
      if (correct) {
        _correct++;
      } else {
        _weak.addAll(ex.items);
      }
      _outcome = LessonOutcome(correct: correct, title: title, detail: detail, word: word);
    });
  }

  void _next() {
    setState(() {
      _index++;
      _outcome = null;
    });
    if (_index == _items.length) {
      ref.read(kanaProgressProvider.notifier).recordGame('lesson', score: _xp, accuracy: _correct / _items.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_index >= _items.length) {
      return Scaffold(
        body: GameResultView(
          korean: _items.any((e) => e.items.any(isKoreanItem)),
          xp: _xp,
          accuracy: _items.isEmpty ? 0 : _correct / _items.length,
          weak: _weak.toList(),
          passMark: widget.passMark,
          onPlayAgain: () => setState(_start),
          onBackToPractice: widget.onBackToPractice == null
              ? null
              : () => widget.onBackToPractice!(_weak.toSet()),
        ),
      );
    }

    final answered = _outcome != null;
    final view = ExerciseView(exercise: _items[_index], answered: answered, onAnswer: _answer);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: (_index + (answered ? 1 : 0)) / _items.length, minHeight: 12),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: XpChip(_xp),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.m, AppSpace.screen, AppSpace.screen),
                child: KeyedSubtree(key: ValueKey(_index), child: view),
              ),
            ),
            if (_outcome case final o?) _FeedbackBar(outcome: o, onNext: _next),
          ],
        ),
      ),
    );
  }
}

typedef OnAnswer = void Function(bool correct, {required String title, String? detail, DictWord? word});

/// The question UI of one exercise; also used for the intro's practice.
class ExerciseView extends StatelessWidget {
  const ExerciseView({super.key, required this.exercise, required this.answered, required this.onAnswer});
  final Exercise exercise;
  final bool answered;
  final OnAnswer onAnswer;

  @override
  Widget build(BuildContext context) => switch (exercise) {
    ChoiceExercise ex => _ChoiceView(exercise: ex, answered: answered, onAnswer: onAnswer),
    WriteExercise ex => _WriteView(exercise: ex, answered: answered, onAnswer: onAnswer),
    BuildExercise ex => _BuildView(exercise: ex, answered: answered, onAnswer: onAnswer),
    ReadExercise ex => _ReadView(exercise: ex, answered: answered, onAnswer: onAnswer),
    GlyphReadExercise ex => _GlyphReadView(exercise: ex, answered: answered, onAnswer: onAnswer),
    MatchExercise ex => _MatchView(exercise: ex, answered: answered, onAnswer: onAnswer),
  };
}

/// Duolingo-style bottom panel: verdict, the correct answer, the dictionary
/// word behind the question, and "Lanjut".
class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({required this.outcome, required this.onNext});
  final LessonOutcome outcome;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final tone = outcome.correct ? c.success : c.seal;
    final word = outcome.word;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.l, AppSpace.screen, AppSpace.m),
      decoration: BoxDecoration(
        color: Color.alphaBlend(tone.withValues(alpha: 0.14), c.surface),
        border: Border(top: BorderSide(color: tone.withValues(alpha: 0.5), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(outcome.correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: tone),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: Text(
                  outcome.title,
                  locale: const Locale('ja'),
                  style: AppText.title2.copyWith(color: tone, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (outcome.detail case final d?) ...[
            const SizedBox(height: AppSpace.xs),
            Text(d, style: AppText.body.copyWith(color: c.ink)),
          ],
          if (word != null) ...[
            const SizedBox(height: AppSpace.s),
            Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 18, color: c.inkMuted),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: Text(
                    [word.kana, ?word.kanji, word.gloss].join('  ·  '),
                    locale: const Locale('ja'),
                    style: AppText.bodySmall.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.m),
          ChunkyButton(label: l10n.next, color: tone, textColor: c.bg, onPressed: onNext),
        ],
      ),
    );
  }
}

class _ChoiceView extends StatefulWidget {
  const _ChoiceView({required this.exercise, required this.answered, required this.onAnswer});
  final ChoiceExercise exercise;
  final bool answered;
  final OnAnswer onAnswer;

  @override
  State<_ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<_ChoiceView> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final q = widget.exercise;
    final jpPrompt = q.kind.promptIsJapanese;
    final ask = switch (q.kind) {
      ChoiceKind.kanaReading => l10n.askRomaji,
      ChoiceKind.pickKana => l10n.askKana,
      ChoiceKind.kanjiMeaning => l10n.askMeaning,
      ChoiceKind.pickKanji => l10n.askKanji,
      ChoiceKind.wordMeaning => l10n.askMeaning,
      ChoiceKind.pickWord => l10n.askWord,
    };
    OptionState stateOf(int i) => _picked == null
        ? OptionState.idle
        : i == q.answerIndex
        ? OptionState.correct
        : i == _picked
        ? OptionState.wrong
        : OptionState.dimmed;
    VoidCallback? tap(int i) => _picked != null
        ? null
        : () {
            setState(() => _picked = i);
            final correct = i == q.answerIndex;
            widget.onAnswer(correct, title: correct ? l10n.correct : l10n.answerWas(q.answer));
          };

    // Dictionary meanings are often long: one wide option per row, wrapped,
    // and a wrapped meaning as the prompt.
    if (q.kind.hasGloss) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ask, style: AppText.title2.copyWith(color: c.ink)),
          Expanded(
            child: Center(
              child: jpPrompt
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        q.prompt,
                        locale: const Locale('ja'),
                        style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 80, height: 1.1, color: c.ink),
                      ),
                    )
                  : Text(
                      q.prompt,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title1.copyWith(color: c.ink, fontSize: 26),
                    ),
            ),
          ),
          for (var i = 0; i < q.options.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.s),
            SizedBox(
              height: jpPrompt ? 60 : 64,
              child: AnswerOption(
                label: q.options[i],
                isKana: !jpPrompt,
                wrap: jpPrompt,
                state: stateOf(i),
                onTap: tap(i),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ask, style: AppText.title2.copyWith(color: c.ink)),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                q.prompt,
                locale: jpPrompt ? const Locale('ja') : null,
                style: jpPrompt
                    ? TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 110, height: 1.1, color: c.ink)
                    : AppText.displayCard.copyWith(
                        fontFamily: AppFonts.latin,
                        color: c.ink,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.m,
          crossAxisSpacing: AppSpace.m,
          childAspectRatio: widget.answered ? 2.2 : 1.6,
          children: [
            for (var i = 0; i < q.options.length; i++)
              AnswerOption(label: q.options[i], isKana: !jpPrompt, state: stateOf(i), onTap: tap(i)),
          ],
        ),
      ],
    );
  }
}

class _WriteView extends ConsumerStatefulWidget {
  const _WriteView({required this.exercise, required this.answered, required this.onAnswer});
  final WriteExercise exercise;
  final bool answered;
  final OnAnswer onAnswer;

  @override
  ConsumerState<_WriteView> createState() => _WriteViewState();
}

class _WriteViewState extends ConsumerState<_WriteView> {
  final _strokes = <List<Offset>>[];
  WritingScore? _score;
  double _canvas = 300;

  /// Character being written: yōon are written one kana at a time (き, ゃ).
  int _part = 0;

  void _check(List<Path> reference, int parts) {
    final l10n = AppLocalizations.of(context);
    final score = scoreWriting(drawn: _strokes, canvasSize: _canvas, reference: reference);
    if (score.passed && _part < parts - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        _part++;
        _strokes.clear();
      });
      return;
    }
    setState(() => _score = score);
    widget.onAnswer(
      score.passed,
      title: score.passed ? l10n.correct : l10n.notQuite,
      detail: score.passed ? null : writingFeedback(l10n, score),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final target = widget.exercise.target;
    final parts = target.literal.characters.toList();
    final part = parts[min(_part, parts.length - 1)];
    final db = ref.watch(contentProvider).value;
    final reference = db == null ? const <Path>[] : db.strokes(part).map(parseSvgPath).toList();
    final score = _score;
    final locked = widget.answered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.exWrite, style: AppText.title2.copyWith(color: c.ink)),
        const SizedBox(height: AppSpace.s),
        Row(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  for (final (i, ch) in parts.indexed)
                    TextSpan(
                      text: ch,
                      // The kana being written stands out in a yōon.
                      style: TextStyle(color: parts.length > 1 && i != _part ? c.inkMuted : c.ink),
                    ),
                ],
              ),
              locale: const Locale('ja'),
              style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 36, color: c.ink),
            ),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Text(
                widget.exercise.hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title2.copyWith(color: c.primaryText),
              ),
            ),
            Text(l10n.strokeCount(reference.length), style: AppText.label.copyWith(color: c.inkMuted)),
          ],
        ),
        const SizedBox(height: AppSpace.m),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              _canvas = min(box.maxWidth, box.maxHeight);
              return Center(
                child: Container(
                  width: _canvas,
                  height: _canvas,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: score == null ? c.line : (score.passed ? c.success : c.seal),
                      width: score == null ? 1 : 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: GestureDetector(
                      onPanStart: locked ? null : (d) => setState(() => _strokes.add([d.localPosition])),
                      onPanUpdate: locked ? null : (d) => setState(() => _strokes.last.add(d.localPosition)),
                      child: CustomPaint(
                        size: Size.square(_canvas),
                        painter: StrokePainter(
                          paths: reference,
                          progress: 0,
                          ink: c.ink,
                          faint: c.line,
                          accent: c.primaryText,
                          showNumbers: true,
                        ),
                        foregroundPainter: InkPainter(
                          strokes: _strokes,
                          color: score?.passed == true ? c.success : c.ink,
                          problem: score?.firstProblem?.index,
                          problemColor: c.seal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (!locked) ...[
          const SizedBox(height: AppSpace.m),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _strokes.isEmpty ? null : () => setState(_strokes.clear),
                  child: Text(l10n.clear),
                ),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                flex: 2,
                child: ChunkyButton(
                  label: l10n.check,
                  onPressed: _strokes.isEmpty || reference.isEmpty ? null : () => _check(reference, parts.length),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BuildView extends StatefulWidget {
  const _BuildView({required this.exercise, required this.answered, required this.onAnswer});
  final BuildExercise exercise;
  final bool answered;
  final OnAnswer onAnswer;

  @override
  State<_BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<_BuildView> {
  /// Indices into the tile bank, in the order tapped.
  final _picked = <int>[];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    final locked = widget.answered;
    final script = switch (ex.script) {
      'katakana' => l10n.katakana,
      'kanji' => l10n.trackKanji,
      'hangul' => l10n.hangul,
      _ => l10n.hiragana,
    };
    // Kana course: romaji prompt. Kanji course: the kana reading.
    final jpPrompt = ex.script == 'kanji';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.exBuild(script), style: AppText.title2.copyWith(color: c.ink)),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            ex.prompt,
            textAlign: TextAlign.center,
            locale: jpPrompt ? const Locale('ja') : null,
            style: jpPrompt
                ? TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 56, height: 1.2, color: c.ink)
                : AppText.displayCard.copyWith(fontFamily: AppFonts.latin, color: c.ink, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          ex.word.gloss,
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AppSpace.xl),
        // Answer line: tap a placed tile to send it back.
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line, width: 2)),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (final i in _picked)
                _KanaTile(label: ex.tiles[i].literal, onTap: locked ? null : () => setState(() => _picked.remove(i))),
            ],
          ),
        ),
        const Spacer(),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.s,
          runSpacing: AppSpace.s,
          children: [
            for (var i = 0; i < ex.tiles.length; i++)
              _picked.contains(i)
                  ? const _KanaTile(label: '')
                  : _KanaTile(label: ex.tiles[i].literal, onTap: locked ? null : () => setState(() => _picked.add(i))),
          ],
        ),
        if (!locked) ...[
          const SizedBox(height: AppSpace.xl),
          ChunkyButton(
            label: l10n.check,
            onPressed: _picked.isEmpty
                ? null
                : () {
                    final correct = ex.check([for (final i in _picked) ex.tiles[i]]);
                    widget.onAnswer(correct, title: correct ? l10n.correct : l10n.answerWas(ex.target), word: ex.word);
                  },
          ),
        ],
      ],
    );
  }
}

/// A kana tile with a thick bottom edge; an empty label leaves the slot of a
/// tile that was moved to the answer line.
class _KanaTile extends StatelessWidget {
  const _KanaTile({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final empty = label.isEmpty;
    return Semantics(
      button: !empty,
      label: label,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          width: label.length > 1 ? 76 : 56,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: empty ? c.surface : c.surfaceHigh,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border(
              top: BorderSide(color: c.line),
              left: BorderSide(color: c.line),
              right: BorderSide(color: c.line),
              bottom: BorderSide(color: c.line, width: empty ? 1 : 4),
            ),
          ),
          child: Text(
            label,
            locale: const Locale('ja'),
            style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 28, color: c.ink),
          ),
        ),
      ),
    );
  }
}

class _ReadView extends StatefulWidget {
  const _ReadView({required this.exercise, required this.answered, required this.onAnswer});
  final ReadExercise exercise;
  final bool answered;
  final OnAnswer onAnswer;

  @override
  State<_ReadView> createState() => _ReadViewState();
}

class _ReadViewState extends State<_ReadView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_controller.text.trim().isEmpty || widget.answered) return;
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    final correct = ex.check(_controller.text);
    FocusScope.of(context).unfocus(); // let the feedback bar show
    widget.onAnswer(correct, title: correct ? l10n.correct : l10n.answerWas(ex.word.romaji), word: ex.word);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          switch ((ex.fromMeaning, ex.word.isKorean)) {
            (true, false) => l10n.exRecall,
            (true, true) => l10n.exRecallKorean,
            (false, false) => l10n.exRead,
            (false, true) => l10n.exReadKorean,
          },
          style: AppText.title2.copyWith(color: c.ink),
        ),
        const Spacer(),
        if (ex.fromMeaning)
          Text(
            ex.shown,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppText.title1.copyWith(color: c.ink, fontSize: 26),
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ex.shown,
              textAlign: TextAlign.center,
              locale: const Locale('ja'),
              style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 64, height: 1.2, color: c.ink),
            ),
          ),
        if (ex.hint case final hint?)
          Text(
            hint,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: c.inkMuted),
          ),
        const Spacer(),
        TextField(
          controller: _controller,
          enabled: !widget.answered,
          autofocus: true,
          // Plain Latin keyboard: no IME conversion, suggestions or autocorrect.
          keyboardType: TextInputType.visiblePassword,
          autocorrect: false,
          enableSuggestions: false,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          style: AppText.title1.copyWith(color: c.ink),
          decoration: InputDecoration(hintText: ex.word.isKorean ? l10n.romajaHint : l10n.romajiHint),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _check(),
        ),
        if (!widget.answered) ...[
          const SizedBox(height: AppSpace.l),
          ChunkyButton(label: l10n.check, onPressed: _controller.text.trim().isEmpty ? null : _check),
        ],
      ],
    );
  }
}

/// One character shown big → type its reading.
class _GlyphReadView extends StatefulWidget {
  const _GlyphReadView({required this.exercise, required this.answered, required this.onAnswer});
  final GlyphReadExercise exercise;
  final bool answered;
  final OnAnswer onAnswer;

  @override
  State<_GlyphReadView> createState() => _GlyphReadViewState();
}

class _GlyphReadViewState extends State<_GlyphReadView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_controller.text.trim().isEmpty || widget.answered) return;
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    final correct = ex.check(_controller.text);
    FocusScope.of(context).unfocus();
    widget.onAnswer(correct, title: correct ? l10n.correct : l10n.answerWas(ex.answer));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ex.korean
              ? l10n.exReadCharKorean
              : ex.glyph is Kanji
              ? l10n.exReadKanji
              : l10n.exReadChar,
          style: AppText.title2.copyWith(color: c.ink),
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            ex.glyph.literal,
            textAlign: TextAlign.center,
            locale: ex.korean ? const Locale('ko') : const Locale('ja'),
            style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 110, height: 1.1, color: c.ink),
          ),
        ),
        if (ex.hint case final hint?)
          Text(
            hint,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: c.inkMuted),
          ),
        const Spacer(),
        TextField(
          controller: _controller,
          enabled: !widget.answered,
          autofocus: true,
          keyboardType: TextInputType.visiblePassword,
          autocorrect: false,
          enableSuggestions: false,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          style: AppText.title1.copyWith(color: c.ink),
          decoration: InputDecoration(hintText: ex.korean ? l10n.romajaHint : l10n.romajiHint),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _check(),
        ),
        if (!widget.answered) ...[
          const SizedBox(height: AppSpace.l),
          ChunkyButton(label: l10n.check, onPressed: _controller.text.trim().isEmpty ? null : _check),
        ],
      ],
    );
  }
}

/// Tap a word, then its meaning (either order). A right pair turns green and
/// stays; a wrong one flashes seal and counts as a mistake. The exercise is
/// answered when every pair is matched.
class _MatchView extends StatefulWidget {
  const _MatchView({required this.exercise, required this.answered, required this.onAnswer});
  final MatchExercise exercise;
  final bool answered;
  final OnAnswer onAnswer;

  @override
  State<_MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<_MatchView> {
  /// Selected word (index into words) and meaning (row in meaningOrder).
  int? _word, _meaning;
  final _matched = <int>{};
  ({int word, int meaning})? _wrong;
  int _mistakes = 0;
  Timer? _flash;

  @override
  void dispose() {
    _flash?.cancel();
    super.dispose();
  }

  void _select({int? word, int? meaning}) {
    if (widget.answered) return;
    setState(() {
      _word = word ?? _word;
      _meaning = meaning ?? _meaning;
    });
    final w = _word, m = _meaning;
    if (w == null || m == null) return;
    final ex = widget.exercise;
    if (ex.meaningOrder[m] == w) {
      HapticFeedback.selectionClick();
      setState(() {
        _matched.add(w);
        _word = _meaning = null;
      });
      if (_matched.length == ex.words.length) {
        final l10n = AppLocalizations.of(context);
        final ok = _mistakes <= MatchExercise.allowedMistakes;
        widget.onAnswer(ok, title: ok ? l10n.correct : l10n.matchMistakes(_mistakes));
      }
    } else {
      HapticFeedback.lightImpact();
      _flash?.cancel();
      setState(() {
        _mistakes++;
        _wrong = (word: w, meaning: m);
        _word = _meaning = null;
      });
      _flash = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    _MatchState stateOf({required bool matched, required bool selected, required bool wrong}) => matched
        ? _MatchState.matched
        : wrong
        ? _MatchState.wrong
        : selected
        ? _MatchState.selected
        : _MatchState.idle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.exMatch, style: AppText.title2.copyWith(color: c.ink)),
        const SizedBox(height: AppSpace.l),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < ex.words.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpace.s),
                      _MatchTile(
                        label: ex.words[i].literal,
                        japanese: true,
                        state: stateOf(matched: _matched.contains(i), selected: _word == i, wrong: _wrong?.word == i),
                        onTap: _matched.contains(i) ? null : () => _select(word: i),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  children: [
                    for (var r = 0; r < ex.meaningOrder.length; r++) ...[
                      if (r > 0) const SizedBox(height: AppSpace.s),
                      _MatchTile(
                        label: ex.words[ex.meaningOrder[r]].word.gloss,
                        japanese: false,
                        state: stateOf(
                          matched: _matched.contains(ex.meaningOrder[r]),
                          selected: _meaning == r,
                          wrong: _wrong?.meaning == r,
                        ),
                        onTap: _matched.contains(ex.meaningOrder[r]) ? null : () => _select(meaning: r),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MatchState { idle, selected, matched, wrong }

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.label, required this.japanese, required this.state, required this.onTap});
  final String label;
  final bool japanese;
  final _MatchState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (border, fill, width) = switch (state) {
      _MatchState.idle => (c.line, c.surfaceHigh, 1.0),
      _MatchState.selected => (c.primaryText, c.primary.withValues(alpha: 0.18), 2.0),
      _MatchState.matched => (c.success, c.success.withValues(alpha: 0.12), 2.0),
      _MatchState.wrong => (c.seal, c.seal.withValues(alpha: 0.14), 2.0),
    };
    final ink = state == _MatchState.matched ? c.inkMuted : c.ink;
    return Semantics(
      button: onTap != null,
      selected: state == _MatchState.selected,
      label: label,
      child: AnimatedContainer(
        duration: AppDurations.press,
        height: 64,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: border, width: width),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
              child: Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: japanese
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                locale: const Locale('ja'),
                                style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 26, color: ink),
                              ),
                            )
                          : Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodySmall.copyWith(color: ink, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  // Icons as well as color (ui-design §4.1).
                  if (state == _MatchState.matched) Icon(Icons.check_rounded, size: 18, color: c.success),
                  if (state == _MatchState.wrong) Icon(Icons.close_rounded, size: 18, color: c.seal),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
