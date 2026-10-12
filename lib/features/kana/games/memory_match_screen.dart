import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/content_db.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../kana_providers.dart';
import 'game_result_view.dart';
import 'kana_quiz.dart';
import 'memory_match.dart';

/// Memory Match (ui-design §5.7): 6 kana ↔ romaji pairs.
class MemoryMatchScreen extends ConsumerStatefulWidget {
  const MemoryMatchScreen({super.key, required this.pool});
  final List<Kana> pool;

  @override
  ConsumerState<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends ConsumerState<MemoryMatchScreen> {
  late MemoryMatchGame _game = MemoryMatchGame(widget.pool);
  Timer? _hide;
  bool _recorded = false;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  int get _xp => _game.cards.length ~/ 2 * XpRules.perCorrect + (_game.mistakes == 0 ? 20 : 0);

  void _flip(MemoryCard card) {
    final result = _game.flip(card);
    switch (result) {
      case FlipResult.match:
        HapticFeedback.lightImpact();
      case FlipResult.mismatch:
        HapticFeedback.selectionClick();
        _hide = Timer(const Duration(milliseconds: 900), () => setState(_game.hideMismatch));
      case FlipResult.first || FlipResult.ignored:
        break;
    }
    setState(() {});
    if (_game.finished && !_recorded) {
      _recorded = true;
      final progress = ref.read(kanaProgressProvider.notifier);
      for (final c in _game.cards.where((c) => c.showsKana)) {
        progress.record(c.kana, correct: !_game.missed.contains(c.kana));
      }
      progress.addXp(_xp);
      progress.recordGame('match', score: _xp, accuracy: _game.accuracy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;

    if (_game.finished) {
      return Scaffold(
        body: GameResultView(
          xp: _xp,
          accuracy: _game.accuracy,
          detail: l10n.movesCount(_game.moves),
          weak: _game.missed.toList(),
          onPlayAgain: () => setState(() {
            _game = MemoryMatchGame(widget.pool);
            _recorded = false;
          }),
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
        title: Text(l10n.gameMatch),
        actions: [
          Center(
            child: Text(l10n.movesCount(_game.moves), style: AppText.body.copyWith(color: c.inkMuted)),
          ),
          const SizedBox(width: AppSpace.screen),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: LayoutBuilder(
            builder: (context, box) {
              const cols = 3, rows = 4;
              final cellW = (box.maxWidth - AppSpace.m * (cols - 1)) / cols;
              final cellH = (box.maxHeight - AppSpace.m * (rows - 1)) / rows;
              return GridView.count(
                crossAxisCount: cols,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpace.m,
                crossAxisSpacing: AppSpace.m,
                childAspectRatio: cellW / math.min(cellH, cellW * 1.3),
                children: [for (final card in _game.cards) _FlipCard(card: card, onTap: () => _flip(card))],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.card, required this.onTap});
  final MemoryCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final up = card.faceUp || card.matched;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: up ? 1 : 0),
      duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 220),
      builder: (context, t, _) {
        final showFace = t >= 0.5;
        final angle = t * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(showFace ? angle - math.pi : angle),
          child: Semantics(
            button: true,
            label: up ? card.face : '?',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: AppDurations.bookmark,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  gradient: showFace ? null : c.heroGradient,
                  color: showFace ? (card.matched ? c.success.withValues(alpha: 0.16) : c.surfaceHigh) : null,
                  border: Border.all(color: card.matched ? c.success : c.line, width: card.matched ? 2 : 1),
                  boxShadow: card.matched ? [BoxShadow(color: c.success.withValues(alpha: 0.3), blurRadius: 16)] : null,
                ),
                alignment: Alignment.center,
                child: showFace
                    ? Text(
                        card.face,
                        locale: card.showsKana ? const Locale('ja') : null,
                        style: card.showsKana
                            ? TextStyle(fontFamily: AppFonts.jpStroke, fontSize: 40, color: c.ink)
                            : AppText.title1.copyWith(color: c.ink),
                      )
                    : Icon(Icons.auto_awesome_rounded, color: c.onPrimary.withValues(alpha: 0.85), size: 28),
              ),
            ),
          ),
        );
      },
    );
  }
}
