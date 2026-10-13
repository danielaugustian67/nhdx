import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/content_db.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/game_card.dart';
import '../../../core/widgets/xp_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../learn/study_language.dart';
import '../kana_providers.dart';
import '../widgets/answer_option.dart';
import 'game_result_view.dart';
import 'kana_quiz.dart';

/// Speed Drill (ui-design §5.7): 60 seconds of kana → romaji, combo
/// multiplies XP.
class SpeedDrillScreen extends ConsumerStatefulWidget {
  const SpeedDrillScreen({super.key, required this.pool, this.duration = const Duration(seconds: 60), this.passMark});

  final List<Kana> pool;
  final Duration duration;

  /// See [GameResultView.passMark].
  final double? passMark;

  @override
  ConsumerState<SpeedDrillScreen> createState() => _SpeedDrillScreenState();
}

enum _Phase { intro, playing, done }

class _SpeedDrillScreenState extends ConsumerState<SpeedDrillScreen> {
  final _random = Random();
  late final _generator = KanaQuizGenerator(widget.pool, random: _random);
  _Phase _phase = _Phase.intro;
  late QuizQuestion _question;
  int? _picked;
  int _combo = 0, _bestCombo = 0, _xp = 0, _answered = 0, _correct = 0;
  final _wrong = <Kana>{};
  final _stopwatch = Stopwatch();
  Timer? _tick, _advance;

  int get _secondsLeft => max(0, widget.duration.inSeconds - _stopwatch.elapsed.inSeconds);

  @override
  void dispose() {
    _tick?.cancel();
    _advance?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.playing;
      _combo = _bestCombo = _xp = _answered = _correct = 0;
      _wrong.clear();
      _nextQuestion();
    });
    _stopwatch
      ..reset()
      ..start();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_stopwatch.elapsed >= widget.duration) {
        _finish();
      } else {
        setState(() {});
      }
    });
  }

  void _finish() {
    _tick?.cancel();
    _advance?.cancel();
    _stopwatch.stop(); // XP was recorded per answer
    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.done);
    ref
        .read(kanaProgressProvider.notifier)
        .recordGame('speed', score: _xp, accuracy: _answered == 0 ? 0 : _correct / _answered);
  }

  void _nextQuestion() {
    final previous = _answered > 0 ? _question.kana : null;
    Kana next;
    do {
      next = widget.pool[_random.nextInt(widget.pool.length)];
    } while (next == previous && widget.pool.length > 1);
    _question = _generator.question(next, QuizDirection.kanaToRomaji);
    _picked = null;
  }

  void _pick(int i) {
    if (_picked != null || _phase != _Phase.playing) return;
    final correct = i == _question.answerIndex;
    final xp = XpRules.forAnswer(correct: correct, comboBefore: _combo);
    ref.read(kanaProgressProvider.notifier).record(_question.kana, correct: correct, xp: xp);
    setState(() {
      _picked = i;
      _answered++;
      _xp += xp;
      if (correct) {
        _correct++;
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
      } else {
        _combo = 0;
        _wrong.add(_question.kana);
      }
    });
    correct ? HapticFeedback.lightImpact() : HapticFeedback.selectionClick();
    _advance = Timer(Duration(milliseconds: correct ? 220 : 650), () {
      if (_phase == _Phase.playing) setState(_nextQuestion);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;

    if (_phase == _Phase.done) {
      return Scaffold(
        body: GameResultView(
          korean: widget.pool.any(isKoreanItem),
          xp: _xp,
          accuracy: _answered == 0 ? 0 : _correct / _answered,
          detail: '${l10n.questionProgress(_correct, _answered)}      ${l10n.comboCount(_bestCombo)}',
          weak: _wrong.toList(),
          passMark: widget.passMark,
          onPlayAgain: _start,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.gameSpeed),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.screen),
            child: XpChip(_xp),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: _phase == _Phase.intro ? _intro(l10n, c) : _playing(l10n, c),
        ),
      ),
    );
  }

  Widget _intro(AppLocalizations l10n, AppColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(),
      GameCard(
        gradient: c.heroGradient,
        glow: true,
        radius: AppRadius.hero,
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            Icon(Icons.bolt_rounded, size: 56, color: c.gold),
            const SizedBox(height: AppSpace.m),
            Text(
              '60',
              style: AppText.displayCard.copyWith(
                fontFamily: AppFonts.latin,
                color: c.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.m),
            Text(
              l10n.speedStart,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.onPrimary),
            ),
          ],
        ),
      ),
      const Spacer(),
      FilledButton(onPressed: _start, child: Text(l10n.start)),
    ],
  );

  Widget _playing(AppLocalizations l10n, AppColors c) {
    final fraction = _secondsLeft / widget.duration.inSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.timer_rounded, color: _secondsLeft <= 10 ? c.seal : c.accent),
            const SizedBox(width: AppSpace.s),
            Text(
              l10n.secondsLeft(_secondsLeft),
              style: AppText.title2.copyWith(color: _secondsLeft <= 10 ? c.seal : c.ink),
            ),
            const Spacer(),
            AnimatedScale(
              scale: _combo > 0 && _picked != null && _picked == _question.answerIndex ? 1.25 : 1,
              duration: const Duration(milliseconds: 200),
              child: Text(l10n.comboCount(_combo), style: AppText.title2.copyWith(color: c.accent)),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: fraction, minHeight: 6, color: _secondsLeft <= 10 ? c.seal : c.accent),
        ),
        Expanded(
          child: Center(
            child: Text(
              _question.prompt,
              locale: const Locale('ja'),
              style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 120, height: 1.1, color: c.ink),
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.m,
          crossAxisSpacing: AppSpace.m,
          childAspectRatio: 1.6,
          children: [
            for (var i = 0; i < _question.options.length; i++)
              AnswerOption(
                label: _question.options[i],
                isKana: false,
                state: _picked == null
                    ? OptionState.idle
                    : i == _question.answerIndex
                    ? OptionState.correct
                    : i == _picked
                    ? OptionState.wrong
                    : OptionState.dimmed,
                onTap: () => _pick(i),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.l),
      ],
    );
  }
}
