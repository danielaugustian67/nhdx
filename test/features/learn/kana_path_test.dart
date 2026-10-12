import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/database/content_db.dart';
import 'package:nihondx/features/kana/games/kana_quiz.dart';
import 'package:nihondx/features/kana/games/memory_match.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/learn/path_providers.dart';

void main() {
  const dbPath = 'data_pipeline/output/content.db';
  final skip = File(dbPath).existsSync() ? false : 'content.db not built';
  late List<Kana> all;
  late List<PathUnit> units;

  setUpAll(() {
    if (skip != false) return;
    final db = ContentDb.open(dbPath);
    all = db.kana();
    db.close();
    units = buildKanaPath(all);
  });

  test('7 units per script, hiragana first', () {
    expect(units, hasLength(14));
    expect(units.take(7).every((u) => u.script == 'hiragana'), isTrue);
    expect(units.skip(7).every((u) => u.script == 'katakana'), isTrue);
    expect(units.map((u) => u.number), List.generate(14, (i) => i + 1));
  }, skip: skip);

  test('every kana is introduced exactly once', () {
    final introduced = [
      for (final u in units)
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) ...n.kana,
    ];
    expect(introduced.length, all.length);
    expect(introduced.toSet(), all.toSet());
  }, skip: skip);

  test('node ids are unique', () {
    final ids = [for (final u in units) ...u.nodes.map((n) => n.id)];
    expect(ids.toSet(), hasLength(ids.length));
  }, skip: skip);

  test('every game node can actually be generated', () {
    for (final u in units) {
      for (final n in u.nodes) {
        switch (n.type) {
          case NodeType.intro:
            final q = KanaQuizGenerator(n.kana, distractors: n.reviewPool.cast<Kana>()).session(count: 10);
            expect(q.every((x) => x.options.toSet().length == 4), isTrue, reason: n.id);
          case NodeType.match:
            expect(() => MemoryMatchGame(n.reviewPool.cast<Kana>()), returnsNormally, reason: n.id);
          case NodeType.speed:
            expect(() => KanaQuizGenerator(n.reviewPool.cast<Kana>()), returnsNormally, reason: n.id);
          case NodeType.write:
            expect(n.kana.every((k) => !k.isYoon), isTrue, reason: n.id);
          case NodeType.chest:
          case NodeType.review:
            break;
        }
      }
    }
  }, skip: skip);

  test('intro quizzes never use kana that have not been introduced yet', () {
    for (final script in ['hiragana', 'katakana']) {
      final met = <Kana>{};
      for (final u in units.where((u) => u.script == script)) {
        for (final n in u.nodes.where((n) => n.type == NodeType.intro)) {
          met.addAll(n.kana);
          expect(n.reviewPool.toSet(), met, reason: n.id);
        }
      }
    }
  }, skip: skip);

  test('nodes unlock strictly in order', () {
    final first = units.first.nodes[0].id, second = units.first.nodes[1].id, third = units.first.nodes[2].id;
    expect(nodeState(units, {}, first), NodeState.current);
    expect(nodeState(units, {}, second), NodeState.locked);
    expect(nodeState(units, {first}, first), NodeState.done);
    expect(nodeState(units, {first}, second), NodeState.current);
    expect(nodeState(units, {first}, third), NodeState.locked);
  }, skip: skip);
}
