import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/theme/app_theme.dart';
import 'package:nihondx/features/learn/kana_path.dart';
import 'package:nihondx/features/learn/path_providers.dart';
import 'package:nihondx/features/today/pixel_island.dart';

void main() {
  const w = IslandArt.width, h = IslandArt.height;
  int at(List<int> art, int x, int y) => art[y * w + x];
  final seeds = [for (var i = 0; i < 60; i++) i * 7919 + 13];

  test('icons are 9 × 9', () {
    for (final icon in [
      PixelArt.star,
      PixelArt.check,
      PixelArt.lock,
      PixelArt.pencil,
      PixelArt.replay,
      PixelArt.cards,
      PixelArt.bolt,
      PixelArt.chest,
    ]) {
      expect(icon, hasLength(9));
      for (final row in icon) {
        expect(row.length, 9, reason: row);
      }
    }
  });

  test('every island is the same for a seed, differs between seeds and fits the canvas', () {
    final shapes = <String>{};
    for (final seed in seeds) {
      for (final state in NodeState.values) {
        final art = IslandArt.build(seed, state);
        expect(art, IslandArt.build(seed, state));
        // Two free rows at the bottom so a pressed island is not cut off.
        for (var y = h - 2; y < h; y++) {
          for (var x = 0; x < w; x++) {
            final v = at(art, x, y);
            expect(v == Px.none || v == Px.sparkle, isTrue, reason: 'seed $seed ($x, $y)');
          }
        }
      }
      shapes.add(IslandArt.build(seed, NodeState.open).join());
    }
    expect(shapes.length, seeds.length);
  });

  test('every icon sits on grass, clear of flowers and decorations', () {
    const grass = {Px.grass, Px.grassLight, Px.grassDark, Px.grassDeep};
    for (final seed in seeds) {
      for (final state in NodeState.values) {
        final art = IslandArt.build(seed, state);
        for (final type in NodeType.values) {
          for (final (iy, row) in PixelIsland.iconFor(type, state).indexed) {
            for (var ix = 0; ix < row.length; ix++) {
              if (row[ix] != '#') continue;
              for (final (dx, dy) in const [(0, 0), (1, 0), (0, 1), (1, 1)]) {
                final x = IslandArt.iconX + ix * 2 + dx, y = IslandArt.iconY + iy * 2 + dy;
                expect(grass.contains(at(art, x, y)), isTrue, reason: 'seed $seed $state ($x, $y): ${at(art, x, y)}');
              }
            }
          }
        }
      }
    }
  });

  test('done islands fly a flag; only the current one sparkles', () {
    for (final seed in seeds) {
      expect(IslandArt.build(seed, NodeState.done), contains(Px.flag));
      expect(IslandArt.build(seed, NodeState.open), isNot(contains(Px.flag)));
      expect(IslandArt.build(seed, NodeState.current), contains(Px.sparkle));
      expect(IslandArt.build(seed, NodeState.locked), isNot(contains(Px.sparkle)));
    }
  });

  test('done shows a check, locked a lock (but a chest stays a chest)', () {
    for (final type in NodeType.values) {
      expect(PixelIsland.iconFor(type, NodeState.done), PixelArt.check);
      expect(PixelIsland.iconFor(type, NodeState.locked), type == NodeType.chest ? PixelArt.chest : PixelArt.lock);
    }
    final open = {for (final t in NodeType.values) PixelIsland.iconFor(t, NodeState.open)};
    expect(open, hasLength(NodeType.values.length), reason: 'each lesson type has its own icon');
  });

  test('cells snap to whole device pixels and keep a 48dp tap target', () {
    for (final dpr in [1.0, 2.0, 2.625, 3.0, 3.5]) {
      final cell = PixelIsland.snappedCell(dpr);
      expect((cell * dpr) % 1, closeTo(0, 1e-9));
      expect(PixelIsland.sizeFor(dpr).width, greaterThanOrEqualTo(48));
      expect(PixelIsland.sizeFor(dpr).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('paints in every state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: ListView(
          children: [
            for (final state in NodeState.values)
              PixelIsland(
                type: NodeType.intro,
                state: state,
                unitColor: Colors.pink,
                seed: state.index,
                pressed: state == NodeState.open,
              ),
          ],
        ),
      ),
    );
    expect(find.byType(PixelIsland), findsNWidgets(NodeState.values.length));
  });
}
