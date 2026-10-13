import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/speech.dart';
import '../../core/database/content_db.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/game_card.dart';
import '../../l10n/app_localizations.dart';
import '../kana/widgets/answer_option.dart';
import '../learn/path_providers.dart';
import '../practice/practice_widgets.dart';
import '../srs/srs_providers.dart';
import 'grammar_practice.dart';
import 'grammar_providers.dart';

/// Grammar practice (PRD F13): fill-in-the-blank and sentence building over
/// [points]. With one point, passing (80%) marks it done.
class GrammarPracticeScreen extends ConsumerStatefulWidget {
  const GrammarPracticeScreen({super.key, required this.points});
  final List<GrammarPoint> points;

  @override
  ConsumerState<GrammarPracticeScreen> createState() => _GrammarPracticeScreenState();
}

class _GrammarPracticeScreenState extends ConsumerState<GrammarPracticeScreen> {
  late List<GrammarExercise> _exercises = buildGrammarExercises(widget.points);
  int _index = 0;
  int _combo = 0;

  /// Answer of the current exercise: gap option index or the built tiles.
  int? _picked;
  List<int> _placed = [];
  bool? _correct;
  final _wrong = <GrammarExercise>[];
  bool _added = false;

  GrammarExercise get _current => _exercises[_index];

  void _answer(bool correct) {
    recordPracticeAnswer(
      ref,
      type: _current.point.cardType,
      itemId: _current.point.id,
      correct: correct,
      combo: _combo,
    );
    HapticFeedback.selectionClick();
    setState(() {
      _correct = correct;
      _combo = correct ? _combo + 1 : 0;
      if (!correct) _wrong.add(_current);
    });
    autoSpeak(ref, _current.sentenceKana);
    if (_index == _exercises.length - 1) _finish();
  }

  void _finish() {
    final right = _exercises.length - _wrong.length;
    if (widget.points.length == 1 && right / _exercises.length >= 0.8) {
      ref
          .read(pathProgressProvider.notifier)
          .complete(grammarDoneKey(widget.points.single.id), score: right / _exercises.length);
    }
  }

  void _next() => setState(() {
    _index++;
    _picked = null;
    _placed = [];
    _correct = null;
  });

  void _again() => setState(() {
    _exercises = buildGrammarExercises(widget.points);
    _index = 0;
    _combo = 0;
    _wrong.clear();
    _added = false;
    _picked = null;
    _placed = [];
    _correct = null;
  });

  void _addMistakes() {
    addPracticeCards(
      ref,
      widget.points.first.cardType,
      {for (final e in _wrong) e.point.id: (id: e.point.id, label: e.point.pattern)}.values,
    );
    setState(() => _added = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = _exercises.length;
    final done = total == 0 || _index >= total;
    ref.watch(speechAutoplayProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(done ? l10n.grammarPractice : '${_index + 1} / $total'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: total == 0 ? 1 : _index / total, minHeight: 6),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: done
            ? PracticeSummary(
                correct: total - _wrong.length,
                total: total,
                mistakes: [for (final e in _wrong) PracticeMistake(e.point.pattern, e.sentence)],
                added: _added,
                onAddMistakes: _addMistakes,
                onAgain: _again,
                korean: widget.points.first.korean,
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpace.screen),
                children: [
                  ...switch (_current) {
                    final GapExercise e => _gap(context, e),
                    final BuildExercise e => _build(context, e),
                  },
                  if (_correct case final correct?) ...[
                    const SizedBox(height: AppSpace.m),
                    AnswerFeedback(
                      correct: correct,
                      answer: _current.sentence,
                      speak: _current.sentenceKana,
                      explanation: '${_current.point.pattern} — ${_current.point.meaning.of(l10n.localeName)}',
                      onNext: _next,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _prompt(BuildContext context, String label, Widget sentence, String translation) {
    final c = context.colors;
    return GameCard(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpace.l),
      child: Column(
        children: [
          Text(label, style: AppText.label.copyWith(color: c.inkMuted)),
          const SizedBox(height: AppSpace.m),
          sentence,
          const SizedBox(height: AppSpace.s),
          Text(
            translation,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }

  List<Widget> _gap(BuildContext context, GapExercise e) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final picked = _picked;
    final [before, after] = e.quiz.question.split(GrammarQuiz.gap);
    return [
      _prompt(
        context,
        l10n.grammarFillGap,
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: before),
              TextSpan(
                text: picked == null ? '＿＿' : e.options[picked],
                style: TextStyle(
                  color: picked == null ? c.primaryText : (picked == e.answer ? c.success : c.seal),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: after),
            ],
          ),
          textAlign: TextAlign.center,
          locale: e.point.locale,
          style: AppText.bodyJp.copyWith(fontSize: 24, color: c.ink),
        ),
        e.quiz.translation.of(l10n.localeName),
      ),
      const SizedBox(height: AppSpace.l),
      for (final (i, option) in e.options.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s),
          child: SizedBox(
            height: 60,
            child: AnswerOption(
              label: option,
              isKana: true,
              state: switch (picked) {
                null => OptionState.idle,
                _ when i == e.answer => OptionState.correct,
                final p when p == i => OptionState.wrong,
                _ => OptionState.dimmed,
              },
              onTap: picked == null
                  ? () {
                      setState(() => _picked = i);
                      _answer(i == e.answer);
                    }
                  : null,
            ),
          ),
        ),
    ];
  }

  List<Widget> _build(BuildContext context, BuildExercise e) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final answered = _correct != null;
    final complete = _placed.length == e.tiles.length;

    Widget tile(int i, {required bool placed}) => ActionChip(
      label: Text(e.tiles[i], locale: e.point.locale, style: AppText.bodyJp.copyWith(fontSize: 18)),
      onPressed: answered ? null : () => setState(() => placed ? _placed.remove(i) : _placed.add(i)),
    );

    return [
      _prompt(
        context,
        l10n.grammarBuild,
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.s),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: switch (_correct) {
                  null => c.line,
                  true => c.success,
                  false => c.seal,
                },
                width: 2,
              ),
            ),
          ),
          child: Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            alignment: WrapAlignment.center,
            children: [for (final i in _placed) tile(i, placed: true)],
          ),
        ),
        e.example.translation.of(l10n.localeName),
      ),
      const SizedBox(height: AppSpace.l),
      Wrap(
        spacing: AppSpace.s,
        runSpacing: AppSpace.s,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < e.tiles.length; i++)
            if (!_placed.contains(i)) tile(i, placed: false),
        ],
      ),
      if (!answered) ...[
        const SizedBox(height: AppSpace.l),
        Row(
          children: [
            TextButton.icon(
              onPressed: _placed.isEmpty ? null : () => setState(() => _placed = []),
              icon: const Icon(Icons.backspace_outlined),
              label: Text(l10n.grammarClear),
            ),
            const SizedBox(width: AppSpace.s),
            Expanded(
              child: ChunkyButton(
                label: l10n.grammarCheck,
                icon: Icons.check_rounded,
                onPressed: complete ? () => _answer(e.accepts([for (final i in _placed) e.tiles[i]])) : null,
              ),
            ),
          ],
        ),
      ],
    ];
  }
}
