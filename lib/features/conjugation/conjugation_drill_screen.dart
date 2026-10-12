import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/speech.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/game_card.dart';
import '../../core/widgets/level_badge.dart';
import '../../l10n/app_localizations.dart';
import '../kana/widgets/answer_option.dart';
import '../practice/practice_widgets.dart';
import '../srs/srs_providers.dart';
import 'conjugation_practice.dart';

/// Questions per round.
const conjRoundSize = 10;

/// Conjugation practice (PRD F14): choose word types, levels and forms, then
/// put words in the asked form, picking from four answers. Mistakes can go
/// to the daily review as `conjugation` cards.
class ConjugationDrillScreen extends ConsumerStatefulWidget {
  const ConjugationDrillScreen({super.key}) : word = null;

  /// Every form of one word (from its detail page), without the setup.
  const ConjugationDrillScreen.word(ConjWord this.word, {super.key});

  final ConjWord? word;

  @override
  ConsumerState<ConjugationDrillScreen> createState() => _ConjugationDrillScreenState();
}

class _ConjugationDrillScreenState extends ConsumerState<ConjugationDrillScreen> {
  List<ConjQuestion>? _questions;

  void _start(List<ConjQuestion> questions) => setState(() => _questions = questions);

  List<ConjQuestion> _wordQuestions(ConjWord w) =>
      buildConjQuestions([w], {for (final f in drillForms) f}, count: conjRoundSize);

  @override
  void initState() {
    super.initState();
    if (widget.word case final w?) _questions = _wordQuestions(w);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final questions = _questions;
    if (questions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.conjPractice)),
        body: _Setup(onStart: _start),
      );
    }
    return _Session(
      key: ObjectKey(questions),
      questions: questions,
      onAgain: () => _start(
        widget.word != null
            ? _wordQuestions(widget.word!)
            : buildConjQuestions([for (final q in questions) q.word], {for (final q in questions) q.form}),
      ),
    );
  }
}

class _Setup extends ConsumerWidget {
  const _Setup({required this.onStart});
  final ValueChanged<List<ConjQuestion>> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final choice = ref.watch(conjChoiceProvider);
    final notifier = ref.read(conjChoiceProvider.notifier);
    final words = ref.watch(conjWordsProvider(choice.levelsKey)).value;
    final pool = [
      for (final w in words ?? const <ConjWord>[])
        if (choice.accepts(w)) w,
    ];
    final usable = pool.any((w) => choice.forms.any(w.conj.forms.contains));

    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.l, bottom: AppSpace.s),
      child: Text(text, style: AppText.label.copyWith(color: c.inkMuted)),
    );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.l),
              children: [
                Text(l10n.conjPracticeBody, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                title(l10n.conjWordTypes),
                Wrap(
                  spacing: AppSpace.s,
                  runSpacing: AppSpace.s,
                  children: [
                    FilterChip(
                      label: Text(l10n.conjVerbs),
                      selected: choice.verbs,
                      onSelected: (v) => notifier.update(choice.copyWith(verbs: v)),
                    ),
                    FilterChip(
                      label: Text(l10n.conjAdjectives),
                      selected: choice.adjectives,
                      onSelected: (v) => notifier.update(choice.copyWith(adjectives: v)),
                    ),
                  ],
                ),
                title(l10n.conjLevels),
                Wrap(
                  spacing: AppSpace.s,
                  runSpacing: AppSpace.s,
                  children: [
                    for (var level = 5; level >= 1; level--)
                      FilterChip(
                        label: Text('N$level'),
                        selected: choice.levels.contains(level),
                        onSelected: (v) {
                          final levels = {...choice.levels};
                          v ? levels.add(level) : levels.remove(level);
                          if (levels.isNotEmpty) notifier.update(choice.copyWith(levels: levels));
                        },
                      ),
                  ],
                ),
                title(l10n.conjForms),
                Wrap(
                  spacing: AppSpace.s,
                  runSpacing: AppSpace.s,
                  children: [
                    for (final f in drillForms)
                      FilterChip(
                        label: Text(conjFormLabel(l10n, f)),
                        selected: choice.forms.contains(f),
                        onSelected: (v) {
                          final forms = {...choice.forms};
                          v ? forms.add(f) : forms.remove(f);
                          if (forms.isNotEmpty) notifier.update(choice.copyWith(forms: forms));
                        },
                      ),
                  ],
                ),
                if (words != null && !usable)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.l),
                    child: Text(l10n.conjNoWords, style: AppText.body.copyWith(color: c.seal)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.screen),
            child: ChunkyButton(
              label: l10n.conjStart(conjRoundSize),
              icon: Icons.play_arrow_rounded,
              onPressed: words == null || !usable
                  ? null
                  : () {
                      final questions = buildConjQuestions(pool, choice.forms, count: conjRoundSize, random: Random());
                      if (questions.isNotEmpty) onStart(questions);
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _Session extends ConsumerStatefulWidget {
  const _Session({super.key, required this.questions, required this.onAgain});
  final List<ConjQuestion> questions;
  final VoidCallback onAgain;

  @override
  ConsumerState<_Session> createState() => _SessionState();
}

class _SessionState extends ConsumerState<_Session> {
  int _index = 0;
  int? _picked;
  int _combo = 0;
  final _wrong = <ConjQuestion>[];
  bool _added = false;

  List<ConjQuestion> get _questions => widget.questions;

  void _pick(int i) {
    if (_picked != null) return;
    final q = _questions[_index];
    final correct = i == q.answer;
    recordPracticeAnswer(ref, type: 'conjugation', itemId: q.cardItemId, correct: correct, combo: _combo);
    HapticFeedback.selectionClick();
    setState(() {
      _picked = i;
      _combo = correct ? _combo + 1 : 0;
      if (!correct) _wrong.add(q);
    });
    autoSpeak(ref, q.right.kana);
  }

  void _next() => setState(() {
    _index++;
    _picked = null;
  });

  void _addMistakes() {
    addPracticeCards(ref, 'conjugation', [
      for (final q in _wrong) (id: q.cardItemId, label: '${q.word.conj.written} → ${q.right.written}'),
    ]);
    setState(() => _added = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = _index >= _questions.length;
    // Loaded up front so the first answer is read aloud.
    ref.watch(speechAutoplayProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: done ? Text(l10n.conjPractice) : Text('${_index + 1} / ${_questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: _index / _questions.length, minHeight: 6),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: done
            ? PracticeSummary(
                correct: _questions.length - _wrong.length,
                total: _questions.length,
                mistakes: [
                  for (final q in _wrong)
                    PracticeMistake(
                      '${q.word.conj.written} → ${q.right.written}',
                      [conjFormLabel(l10n, q.form), if (q.right.written != q.right.kana) q.right.kana].join(' · '),
                    ),
                ],
                added: _added,
                onAddMistakes: _addMistakes,
                onAgain: widget.onAgain,
              )
            : _question(context, _questions[_index]),
      ),
    );
  }

  Widget _question(BuildContext context, ConjQuestion q) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final w = q.word;
    final hint = conjFormHint(q.form, w.conj.cls);
    final picked = _picked;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.screen),
      children: [
        GameCard(
          radius: AppRadius.card,
          padding: const EdgeInsets.all(AppSpace.l),
          child: Column(
            children: [
              if (w.conj.written != w.conj.kana)
                Text(
                  w.conj.kana,
                  locale: const Locale('ja'),
                  style: AppText.bodyJp.copyWith(fontSize: 18, color: c.inkMuted),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  w.conj.written,
                  locale: const Locale('ja'),
                  style: AppText.displayCard.copyWith(fontSize: 48, color: c.ink),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Wrap(
                spacing: AppSpace.s,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    w.word.gloss,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: c.inkMuted),
                  ),
                  if (w.word.jlpt > 0) LevelBadge(w.word.jlpt),
                ],
              ),
              const SizedBox(height: AppSpace.l),
              Text(l10n.conjAsk, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
              const SizedBox(height: AppSpace.xs),
              Text(
                [conjFormLabel(l10n, q.form), if (hint.isNotEmpty) hint].join('  '),
                textAlign: TextAlign.center,
                locale: const Locale('ja'),
                style: AppText.title2.copyWith(color: c.primaryText),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.l),
        for (final (i, option) in q.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s),
            child: SizedBox(
              height: 64,
              child: AnswerOption(
                label: option.written,
                isKana: true,
                state: switch (picked) {
                  null => OptionState.idle,
                  _ when i == q.answer => OptionState.correct,
                  final p when p == i => OptionState.wrong,
                  _ => OptionState.dimmed,
                },
                onTap: picked == null ? () => _pick(i) : null,
              ),
            ),
          ),
        if (picked != null) ...[
          const SizedBox(height: AppSpace.s),
          AnswerFeedback(correct: picked == q.answer, answer: q.right.toString(), speak: q.right.kana, onNext: _next),
        ],
      ],
    );
  }
}
