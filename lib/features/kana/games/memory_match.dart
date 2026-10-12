import 'dart:math';

import '../../../core/database/content_db.dart';

class MemoryCard {
  MemoryCard({required this.id, required this.kana, required this.showsKana});

  final int id;
  final Kana kana;

  /// True: face shows the kana; false: face shows the romaji.
  final bool showsKana;
  bool faceUp = false;
  bool matched = false;

  String get face => showsKana ? kana.literal : kana.romaji;
}

enum FlipResult { ignored, first, match, mismatch }

/// Memory Match rules (ui-design §5.7): [pairs] kana ↔ romaji pairs face
/// down; flip two, matching pairs stay open. After a mismatch both cards stay
/// up until [hideMismatch] is called (the UI waits briefly so they can be
/// read).
class MemoryMatchGame {
  MemoryMatchGame(List<Kana> pool, {int pairs = 6, Random? random}) {
    final rnd = random ?? Random();
    // One kana per romaji so a pair can never be ambiguous (ぢ/じ).
    final byRomaji = <String, Kana>{};
    for (final k in (pool.toList()..shuffle(rnd))) {
      byRomaji.putIfAbsent(k.romaji, () => k);
    }
    final chosen = byRomaji.values.take(pairs).toList();
    if (chosen.length < pairs) throw ArgumentError('need $pairs distinct kana');
    var id = 0;
    cards = [
      for (final k in chosen) ...[
        MemoryCard(id: id++, kana: k, showsKana: true),
        MemoryCard(id: id++, kana: k, showsKana: false),
      ],
    ]..shuffle(rnd);
  }

  late final List<MemoryCard> cards;
  MemoryCard? _open;
  final List<MemoryCard> _pendingHide = [];
  int moves = 0;
  int mistakes = 0;

  bool get finished => cards.every((c) => c.matched);
  bool get waitingToHide => _pendingHide.isNotEmpty;

  /// Kana that were part of a mismatch (for "perlu latihan").
  final Set<Kana> missed = {};

  FlipResult flip(MemoryCard card) {
    if (card.faceUp || card.matched || waitingToHide) return FlipResult.ignored;
    card.faceUp = true;
    final open = _open;
    if (open == null) {
      _open = card;
      return FlipResult.first;
    }
    moves++;
    _open = null;
    if (open.kana == card.kana) {
      open.matched = card.matched = true;
      return FlipResult.match;
    }
    mistakes++;
    missed.addAll([open.kana, card.kana]);
    _pendingHide.addAll([open, card]);
    return FlipResult.mismatch;
  }

  void hideMismatch() {
    for (final c in _pendingHide) {
      c.faceUp = false;
    }
    _pendingHide.clear();
  }

  /// 0–1: 1 when every pair was found without a mistake.
  double get accuracy => moves == 0 ? 0 : (moves - mistakes) / moves;
}
