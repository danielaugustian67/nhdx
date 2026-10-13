import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/content_db.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/xp_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../learn/study_language.dart';
import '../kana_providers.dart';
import '../widgets/answer_option.dart';
import 'game_result_view.dart';
import 'kana_quiz.dart';

/// Kana quiz (ui-design §5.7): 10 questions, alternating kana→romaji and
/// romaji→kana, weak kana first. Correct answers advance automatically;
/// after a wrong answer the correct one is shown until "Lanjut".
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.pool, this.distractors, this.count = 10, this.passMark});

  /// Kana the questions are about.
  final List<Kana> pool;

  /// Extra kana for wrong options (defaults to [pool]).
  final List<Kana>? distractors;
  final int count;

  /// See [GameResultView.passMark].
  final double? passMark;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _index = 0;
  int? _picked;
  int _combo = 0;
  int _xp = 0;
  int _correct = 0;
  final _wrong = <Kana>{};
  Timer? _advance;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final weakIds = ref.read(kanaProgressProvider).weakIds;
    _questions = KanaQuizGenerator(
      widget.pool,
      distractors: widget.distractors,
    ).session(count: widget.count, focus: widget.pool.where((k) => weakIds.contains(k.id)).toSet());
    _index = 0;
    _picked = null;
    _combo = _xp = _correct = 0;
    _wrong.clear();
  }

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _pick(int i) {
    if (_picked != null) return;
    final q = _questions[_index];
    final correct = i == q.answerIndex;
    final xp = XpRules.forAnswer(correct: correct, comboBefore: _combo);
    ref.read(kanaProgressProvider.notifier).record(q.kana, correct: correct, xp: xp);
    setState(() {
      _picked = i;
      _xp += xp;
      if (correct) {
        _correct++;
        _combo++;
      } else {
        _combo = 0;
        _wrong.add(q.kana);
      }
    });
    if (correct) {
      HapticFeedback.lightImpact();
      _advance = Timer(const Duration(milliseconds: 700), _next);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _next() {
    _advance?.cancel();
    setState(() {
      _index++;
      _picked = null;
    });
    if (_index == _questions.length) {
      ref.read(kanaProgressProvider.notifier).recordGame('quiz', score: _xp, accuracy: _correct / _questions.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;

    if (_index >= _questions.length) {
      return Scaffold(
        body: GameResultView(
          korean: widget.pool.any(isKoreanItem),
          xp: _xp,
          accuracy: _correct / _questions.length,
          weak: _wrong.toList(),
          passMark: widget.passMark,
          onPlayAgain: () => setState(_start),
        ),
      );
    }

    final q = _questions[_index];
    final kanaPrompt = q.direction == QuizDirection.kanaToRomaji;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.questionProgress(_index + 1, _questions.length)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.screen),
            child: XpChip(_xp),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (_index + (_picked == null ? 0 : 1)) / _questions.length,
                minHeight: 6,
              ),
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
              const SizedBox(height: AppSpace.l),
              Text(
                kanaPrompt ? l10n.askRomaji : l10n.askKana,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    q.prompt,
                    locale: kanaPrompt ? const Locale('ja') : null,
                    style: kanaPrompt
                        ? TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 120, height: 1.1, color: c.ink)
                        : AppText.displayCard.copyWith(
                            fontFamily: AppFonts.latin,
                            color: c.ink,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                ),
              ),
              if (_combo >= 3)
                Text(
                  l10n.comboCount(_combo),
                  textAlign: TextAlign.center,
                  style: AppText.title2.copyWith(color: c.accent),
                ),
              const SizedBox(height: AppSpace.m),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpace.m,
                crossAxisSpacing: AppSpace.m,
                childAspectRatio: 1.6,
                children: [
                  for (var i = 0; i < q.options.length; i++)
                    AnswerOption(
                      label: q.options[i],
                      isKana: !kanaPrompt,
                      state: _picked == null
                          ? OptionState.idle
                          : i == q.answerIndex
                          ? OptionState.correct
                          : i == _picked
                          ? OptionState.wrong
                          : OptionState.dimmed,
                      onTap: _picked == null ? () => _pick(i) : null,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.l),
              SizedBox(
                height: AppSizes.buttonHeight + 28,
                child: _picked == null
                    ? null
                    : _picked == q.answerIndex
                    ? Center(
                        child: Text(l10n.correct, style: AppText.title2.copyWith(color: c.success)),
                      )
                    : Column(
                        children: [
                          Text(l10n.answerWas(q.answer), style: AppText.body.copyWith(color: c.ink)),
                          const SizedBox(height: AppSpace.xs),
                          FilledButton(onPressed: _next, child: Text(l10n.next)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
