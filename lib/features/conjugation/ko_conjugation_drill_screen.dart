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
import '../../l10n/app_localizations.dart';
import '../kana/widgets/answer_option.dart';
import '../practice/practice_widgets.dart';
import '../srs/srs_providers.dart';
import 'conjugation_drill_screen.dart' show conjRoundSize;
import 'ko_conjugation_practice.dart';

const _ko = Locale('ko');

/// Korean conjugation practice: the course's verbs and adjectives in the
/// chosen forms, picking from four answers. Mistakes can go to the daily
/// review as `ko_conjugation` cards.
class KoConjugationDrillScreen extends ConsumerStatefulWidget {
  const KoConjugationDrillScreen({super.key});

  @override
  ConsumerState<KoConjugationDrillScreen> createState() => _KoConjugationDrillScreenState();
}

class _KoConjugationDrillScreenState extends ConsumerState<KoConjugationDrillScreen> {
  List<KoConjQuestion>? _questions;
  var _verbs = true;
  var _adjectives = true;
  var _forms = {...koStarterForms};

  void _start(List<KoConjWord> pool) {
    final questions = buildKoConjQuestions(pool, _forms, count: conjRoundSize, random: Random());
    if (questions.isNotEmpty) setState(() => _questions = questions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final words = ref.watch(koConjWordsProvider).value;
    final pool = [
      for (final w in words ?? const <KoConjWord>[])
        if (w.adjective ? _adjectives : _verbs) w,
    ];
    if (_questions case final questions?) {
      return _Session(key: ObjectKey(questions), questions: questions, onAgain: () => _start(pool));
    }
    final c = context.colors;
    final usable = pool.any((w) => _forms.any(w.conj.forms.contains));

    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.l, bottom: AppSpace.s),
      child: Text(text, style: AppText.label.copyWith(color: c.inkMuted)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.conjPractice)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.l),
                children: [
                  Text(l10n.koConjPracticeBody, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                  title(l10n.conjWordTypes),
                  Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.s,
                    children: [
                      // One type always stays on.
                      FilterChip(
                        label: Text(l10n.conjVerbs),
                        selected: _verbs,
                        onSelected: (v) => setState(() => _verbs = v || !_adjectives),
                      ),
                      FilterChip(
                        label: Text(l10n.conjAdjectives),
                        selected: _adjectives,
                        onSelected: (v) => setState(() => _adjectives = v || !_verbs),
                      ),
                    ],
                  ),
                  title(l10n.conjForms),
                  Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.s,
                    children: [
                      for (final f in koDrillForms)
                        FilterChip(
                          label: Text(koFormLabel(l10n, f), locale: _ko),
                          selected: _forms.contains(f),
                          onSelected: (v) {
                            final forms = {..._forms};
                            v ? forms.add(f) : forms.remove(f);
                            if (forms.isNotEmpty) setState(() => _forms = forms);
                          },
                        ),
                    ],
                  ),
                  if (words != null && !usable)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.l),
                      child: Text(l10n.koConjNoWords, style: AppText.body.copyWith(color: c.seal)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.screen),
              child: ChunkyButton(
                label: l10n.conjStart(conjRoundSize),
                icon: Icons.play_arrow_rounded,
                onPressed: words == null || !usable ? null : () => _start(pool),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Session extends ConsumerStatefulWidget {
  const _Session({super.key, required this.questions, required this.onAgain});
  final List<KoConjQuestion> questions;
  final VoidCallback onAgain;

  @override
  ConsumerState<_Session> createState() => _SessionState();
}

class _SessionState extends ConsumerState<_Session> {
  int _index = 0;
  int? _picked;
  int _combo = 0;
  final _wrong = <KoConjQuestion>[];
  bool _added = false;

  List<KoConjQuestion> get _questions => widget.questions;

  void _pick(int i) {
    if (_picked != null) return;
    final q = _questions[_index];
    final correct = i == q.answer;
    recordPracticeAnswer(ref, type: 'ko_conjugation', itemId: q.cardItemId, correct: correct, combo: _combo);
    HapticFeedback.selectionClick();
    setState(() {
      _picked = i;
      _combo = correct ? _combo + 1 : 0;
      if (!correct) _wrong.add(q);
    });
    autoSpeak(ref, q.right);
  }

  void _next() => setState(() {
    _index++;
    _picked = null;
  });

  void _addMistakes() {
    addPracticeCards(ref, 'ko_conjugation', [
      for (final q in _wrong) (id: q.cardItemId, label: '${q.word.word.hangul} → ${q.right}'),
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
                    PracticeMistake('${q.word.word.hangul} → ${q.right}', koFormLabel(l10n, q.form)),
                ],
                added: _added,
                onAddMistakes: _addMistakes,
                onAgain: widget.onAgain,
                korean: true,
              )
            : _question(context, _questions[_index]),
      ),
    );
  }

  Widget _question(BuildContext context, KoConjQuestion q) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final w = q.word.word;
    final picked = _picked;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.screen),
      children: [
        GameCard(
          radius: AppRadius.card,
          padding: const EdgeInsets.all(AppSpace.l),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  w.hangul,
                  locale: _ko,
                  style: AppText.displayWord.copyWith(color: c.ink),
                ),
              ),
              Text(w.romaja, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
              const SizedBox(height: AppSpace.xs),
              Text(
                w.meaning.of(l10n.localeName),
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AppSpace.l),
              Text(l10n.conjAsk, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
              const SizedBox(height: AppSpace.xs),
              Text(
                koFormLabel(l10n, q.form),
                textAlign: TextAlign.center,
                locale: _ko,
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
                label: option,
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
          AnswerFeedback(correct: picked == q.answer, answer: q.right, speak: q.right, onNext: _next),
        ],
      ],
    );
  }
}
