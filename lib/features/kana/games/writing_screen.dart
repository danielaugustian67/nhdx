import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/content_db.dart';
import '../../../core/database/providers.dart';
import '../../../core/svg/svg_path.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/xp_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../kana_providers.dart';
import '../widgets/ink_painter.dart';
import '../widgets/stroke_animation.dart';
import '../writing/stroke_scorer.dart';
import 'game_result_view.dart';

/// Writing practice (ui-design §5.7, PRD F6): write over a fading guide,
/// scored stroke by stroke. A session is [count] kana, [start] first.
class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({super.key, required this.pool, this.start, this.count = 5, this.passMark});

  final List<Kana> pool;
  final Kana? start;
  final int count;

  /// See [GameResultView.passMark]; accuracy here is "right on the first try".
  final double? passMark;

  @override
  ConsumerState<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends ConsumerState<WritingScreen> {
  late List<Kana> _queue;
  int _index = 0;
  final _strokes = <List<Offset>>[];
  WritingScore? _score;
  bool _guide = true;
  bool _failedOnce = false;
  int _firstTry = 0;
  int _xp = 0;
  final _weak = <Kana>{};
  double _canvas = 300;

  static const xpPerKana = 15;

  @override
  void initState() {
    super.initState();
    _newSession();
  }

  void _newSession() {
    final rest = widget.pool.where((k) => k != widget.start).toList()..shuffle(Random());
    _queue = [?widget.start, ...rest].take(min(widget.count, widget.pool.length)).toList();
    _index = _firstTry = _xp = 0;
    _weak.clear();
    _reset();
  }

  void _reset() {
    _strokes.clear();
    _score = null;
  }

  Kana get _kana => _queue[_index];

  List<Path> _reference(ContentDb? db) => db == null ? const [] : db.strokes(_kana.literal).map(parseSvgPath).toList();

  void _check(List<Path> reference) {
    final score = scoreWriting(drawn: _strokes, canvasSize: _canvas, reference: reference);
    final progress = ref.read(kanaProgressProvider.notifier);
    setState(() => _score = score);
    if (score.passed) {
      HapticFeedback.lightImpact();
      final xp = _failedOnce ? xpPerKana ~/ 2 : xpPerKana;
      _xp += xp;
      if (!_failedOnce) _firstTry++;
      progress.record(_kana, correct: true, xp: xp);
    } else {
      HapticFeedback.selectionClick();
      if (!_failedOnce) progress.record(_kana, correct: false);
      _failedOnce = true;
      _weak.add(_kana);
    }
  }

  void _next() => setState(() {
    _index++;
    if (_index == _queue.length) {
      ref.read(kanaProgressProvider.notifier).recordGame('write', score: _xp, accuracy: _firstTry / _queue.length);
    }
    _failedOnce = false;
    _reset();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;

    if (_index >= _queue.length) {
      return Scaffold(
        body: GameResultView(
          xp: _xp,
          accuracy: _firstTry / _queue.length,
          weak: _weak.toList(),
          passMark: widget.passMark,
          onPlayAgain: () => setState(_newSession),
        ),
      );
    }

    final reference = _reference(ref.watch(contentProvider).value);
    final score = _score;
    final problem = score?.firstProblem?.index;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.questionProgress(_index + 1, _queue.length)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    _kana.literal,
                    locale: const Locale('ja'),
                    style: TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 40, color: c.ink),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_kana.romaji, style: AppText.title2.copyWith(color: c.ink)),
                      Text(l10n.strokeCount(reference.length), style: AppText.label.copyWith(color: c.inkMuted)),
                    ],
                  ),
                  const Spacer(),
                  FilterChip(label: Text(l10n.guide), selected: _guide, onSelected: (v) => setState(() => _guide = v)),
                ],
              ),
              const SizedBox(height: AppSpace.m),
              Text(l10n.writeHint, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
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
                            onPanStart: score?.passed == true
                                ? null
                                : (d) => setState(() {
                                    if (_score != null) _reset();
                                    _strokes.add([d.localPosition]);
                                  }),
                            onPanUpdate: score?.passed == true
                                ? null
                                : (d) => setState(() => _strokes.last.add(d.localPosition)),
                            child: CustomPaint(
                              size: Size.square(_canvas),
                              painter: StrokePainter(
                                paths: _guide || (score != null && !score.passed) ? reference : const [],
                                progress: 0,
                                ink: c.ink,
                                faint: c.line,
                                accent: c.primaryText,
                                showNumbers: _guide,
                              ),
                              foregroundPainter: InkPainter(
                                strokes: _strokes,
                                color: score?.passed == true ? c.success : c.ink,
                                problem: problem,
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
              const SizedBox(height: AppSpace.m),
              SizedBox(
                height: 48,
                child: score == null
                    ? null
                    : Text(
                        writingFeedback(l10n, score),
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(color: score.passed ? c.success : c.ink),
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _strokes.isEmpty || score?.passed == true ? null : () => setState(_reset),
                      child: Text(l10n.clear),
                    ),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: score?.passed == true
                        ? FilledButton(onPressed: _next, child: Text(l10n.next))
                        : score != null
                        ? FilledButton(onPressed: () => setState(_reset), child: Text(l10n.tryAgain))
                        : FilledButton(
                            onPressed: _strokes.isEmpty || reference.isEmpty ? null : () => _check(reference),
                            child: Text(l10n.check),
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
