import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../learn/kana_path.dart';
import '../learn/path_providers.dart';

/// A path node drawn as a small floating pixel-art island (ui-design §5.2):
/// a grassy top on an earth cliff that tapers to jagged points, with hanging
/// vines, sometimes a tree or a waterfall, flowers in the unit color and the
/// lesson's pixel icon on the grass. Every node gets its own shape from
/// [seed]. Done islands fly a flag and show a gold check, locked ones are
/// grey with a lock (icon and shape, never color alone), and the current one
/// sparkles in the unit color. Pressing pushes the island down a pixel.
class PixelIsland extends StatelessWidget {
  const PixelIsland({
    super.key,
    required this.type,
    required this.state,
    required this.unitColor,
    required this.seed,
    this.pressed = false,
  });

  final NodeType type;
  final NodeState state;
  final Color unitColor;

  /// Picks the island's shape and decoration, the same on every visit.
  final int seed;
  final bool pressed;

  /// Size of one art pixel in logical pixels, before snapping to whole
  /// device pixels so the art stays sharp. Icons use two art pixels per
  /// icon pixel.
  static const cell = 2.0;
  static const columns = IslandArt.width, rows = IslandArt.height;

  /// Canvas size on a screen with [devicePixelRatio].
  static Size sizeFor(double devicePixelRatio) {
    final c = snappedCell(devicePixelRatio);
    return Size(columns * c, rows * c);
  }

  static double snappedCell(double devicePixelRatio) =>
      (cell * devicePixelRatio).roundToDouble().clamp(1, double.infinity) / devicePixelRatio;

  /// The icon on top: a check when done, a lock when locked (a locked chest
  /// still shows the chest), else the lesson type.
  static List<String> iconFor(NodeType type, NodeState state) => switch (state) {
    NodeState.done => PixelArt.check,
    NodeState.locked when type != NodeType.chest => PixelArt.lock,
    _ => switch (type) {
      NodeType.intro => PixelArt.star,
      NodeType.write => PixelArt.pencil,
      NodeType.review => PixelArt.replay,
      NodeType.match => PixelArt.cards,
      NodeType.speed => PixelArt.bolt,
      NodeType.chest => PixelArt.chest,
    },
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return RepaintBoundary(
      child: CustomPaint(
        size: sizeFor(dpr),
        painter: _IslandPainter(
          cell: snappedCell(dpr),
          art: IslandArt.of(seed, state),
          icon: iconFor(type, state),
          state: state,
          unitColor: unitColor,
          gold: c.goldFill,
          lockedFace: c.surfaceHigh,
          pressed: pressed,
        ),
      ),
    );
  }
}

/// Palette indices of [IslandArt] grids; 0 is transparent.
abstract final class Px {
  static const none = 0,
      outline = 1,
      grassLight = 2,
      grass = 3,
      grassDark = 4,
      grassDeep = 5,
      earthLight = 6,
      earth = 7,
      earthDark = 8,
      earthDeep = 9,
      stone = 10,
      vine = 11,
      vineLight = 12,
      water = 13,
      foam = 14,
      leafLight = 15,
      leaf = 16,
      leafDark = 17,
      trunk = 18,
      flower = 19,
      flowerLight = 20,
      pole = 21,
      flag = 22,
      sparkle = 23,
      count = 24;
}

/// Builds the island pixel grids: a grass ellipse seen from above, its lip,
/// an earth cliff under it tapering to a few points, then outline, vines,
/// waterfall and flowers. Deterministic in seed and state; cached.
abstract final class IslandArt {
  static const width = 48, height = 58;

  /// Center and radii of the grass top.
  static const cx = 24.0, gcy = 18.0, rx = 21.0, ry = 10.0;

  /// Top-left of the 18 × 18 icon (9 × 9 icon pixels, two art pixels each).
  static const iconX = 15, iconY = 9;

  static final _cache = <int, Uint8List>{};

  static Uint8List of(int seed, NodeState state) {
    final key = seed * NodeState.values.length + state.index;
    if (_cache.length > 400) _cache.clear();
    return _cache.putIfAbsent(key, () => build(seed, state));
  }

  /// A stable hash of ([x], [y]) for [seed] and [salt] in [0, 1).
  static double noise(int seed, int x, int y, int salt) {
    var h = (seed * 374761393 + x * 668265263 + y * 1274126177 + salt * 1013904223) & 0xFFFFFFFF;
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF;
    h = h ^ (h >> 16);
    return (h & 0xFFFFFF) / 0x1000000;
  }

  static Uint8List build(int seed, NodeState state) {
    final g = Uint8List(width * height);
    double rnd(int x, int y, int salt) => noise(seed, x, y, salt);
    int at(int x, int y) => x < 0 || y < 0 || x >= width || y >= height ? Px.none : g[y * width + x];
    void set(int x, int y, int v) {
      if (x >= 0 && y >= 0 && x < width && y < height) g[y * width + x] = v;
    }

    bool inIcon(int x, int y) => x >= iconX - 2 && x < iconX + 20 && y >= iconY - 2 && y < iconY + 22;

    // Grass top: an ellipse with a slightly ragged rim, lit from the back
    // left, darker towards the front, speckled.
    final topEnd = List.filled(width, -1);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final dx = (x + 0.5 - cx) / rx, dy = (y + 0.5 - gcy) / ry;
        final d = dx * dx + dy * dy;
        if (d > 1 + 0.12 * (rnd(x ~/ 2, y ~/ 2, 1) - 0.5)) continue;
        topEnd[x] = math.max(topEnd[x], y);
        var v = dy > 0.55 ? Px.grassDark : Px.grass;
        if (d > 0.7 && dy < 0 && dx < 0.5) v = Px.grassLight;
        final r = rnd(x, y, 2);
        if (r < 0.1) v = Px.grassLight;
        if (r > 0.93) v = Px.grassDark;
        set(x, y, v);
      }
    }

    // Earth under the top: deepest in the middle, a little jagged, with a
    // few stalactite points.
    final bottom = List.filled(width, -1);
    final spikes = [
      for (var i = 0; i < 3; i++) (cx + (rnd(i, 0, 5) - 0.5) * rx * 1.3, 4 + rnd(i, 1, 5) * 7, 2 + rnd(i, 2, 5) * 2),
    ];
    for (var x = 0; x < width; x++) {
      final yb = topEnd[x];
      if (yb < 0) continue;
      final t = ((x + 0.5 - cx).abs() / rx).clamp(0.0, 1.0);
      var depth = 15 * math.pow(1 - t, 1.2) + 2 + rnd(x, 0, 4) * 2.5;
      for (final (sx, sh, sw) in spikes) {
        depth += sh * math.max(0, 1 - (x + 0.5 - sx).abs() / sw) * (1 - t);
      }
      bottom[x] = math.min(yb + 3 + depth.floor(), height - 5);
      final rel = (x + 0.5 - cx) / rx;
      for (var y = yb + 1; y <= bottom[x]; y++) {
        var v = rel < -0.35 ? Px.earthLight : (rel > 0.4 ? Px.earthDark : Px.earth);
        // Vertical streaks and the odd lighter ledge.
        if (rnd(x, y ~/ 4, 6) < 0.25) v = math.min(v + 1, Px.earthDeep);
        if (rnd(x ~/ 2, y, 7) < 0.06) v = math.max(v - 1, Px.earthLight);
        if (y >= bottom[x] - 1 || y <= yb + 4) v = math.max(v, Px.earthDark);
        if (y == yb + 4) v = Px.earthDeep;
        if (rnd(x, y, 8) < 0.03) v = Px.stone;
        set(x, y, v);
      }
      // The grass lip hangs over the cliff, with drips.
      final drip = (rnd(x, 0, 3) * 4).floor() - 1;
      for (var y = yb + 1; y <= yb + 3 + math.max(0, drip); y++) {
        set(x, y, y == yb + 1 ? Px.grassDark : Px.grassDeep);
      }
    }

    // A tree on every third island, a flag on done ones.
    final done = state == NodeState.done;
    if (seed % 3 == 0) {
      final left = done || rnd(0, 0, 9) < 0.5;
      _tree(set, rnd, left ? (cx - 14).round() : (cx + 13).round(), (gcy - 4).round());
    }
    if (done) {
      final px = (cx + 15).round(), base = (gcy - 3).round();
      for (var y = base - 11; y <= base; y++) {
        set(px, y, Px.pole);
      }
      const cloth = [5, 6, 5, 4];
      for (final (dy, length) in cloth.indexed) {
        for (var dx = 0; dx < length; dx++) {
          set(px + 1 + dx, base - 11 + dy, Px.flag);
        }
      }
    }

    // Small rocks floating beside the island.
    _rock(set, 1, (gcy + 13).round(), 3, 2);
    _rock(set, width - 5, (gcy + 19).round(), 3, 2);

    // Outline everything drawn so far.
    final edge = <int>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (at(x, y) != Px.none) continue;
        if (at(x - 1, y) != Px.none || at(x + 1, y) != Px.none || at(x, y - 1) != Px.none || at(x, y + 1) != Px.none) {
          edge.add(y * width + x);
        }
      }
    }
    for (final i in edge) {
      g[i] = Px.outline;
    }

    // A waterfall on every third island: a stream across the grass, then
    // down the cliff into mist.
    final waterfall = seed % 3 == 1;
    final wx = (cx + 12).round();
    if (waterfall && topEnd[wx] >= 0) {
      for (var y = (gcy - 3).round(); y <= topEnd[wx]; y++) {
        set(wx, y, Px.water);
        set(wx + 1, y, rnd(wx, y, 10) < 0.3 ? Px.foam : Px.water);
      }
      final end = math.min(bottom[wx] + 7, height - 3);
      for (var y = topEnd[wx] + 1; y <= end; y++) {
        for (var dx = 0; dx < 2; dx++) {
          set(wx + dx, y, rnd(wx + dx, y, 11) < 0.25 ? Px.foam : Px.water);
        }
      }
      for (final (dx, dy) in const [(-1, 0), (2, 0), (-2, 1), (0, 1), (3, 1), (1, 2)]) {
        set(wx + dx, end + dy, Px.foam);
      }
    }

    // Vines hanging from the lip, past the bottom.
    final vines = 2 + (rnd(1, 1, 12) * 3).floor();
    for (var i = 0; i < vines; i++) {
      final x = 5 + (rnd(i, 3, 12) * (width - 10)).floor();
      if (topEnd[x] < 0 || (waterfall && (x - wx).abs() <= 2)) continue;
      final length = 6 + (rnd(i, 4, 12) * 14).floor();
      for (var k = 0; k < length; k++) {
        final y = topEnd[x] + 3 + k;
        if (y >= height - 3) break;
        set(x, y, Px.vine);
        if (k % 3 == 1) set(x + (k % 2 == 0 ? 1 : -1), y, Px.vineLight);
      }
    }

    // Flowers on the grass, clear of the icon.
    for (var i = 0; i < 24; i++) {
      final x = (rnd(i, 5, 13) * width).floor(), y = (rnd(i, 6, 13) * height).floor();
      final v = at(x, y);
      if (inIcon(x, y) || (v != Px.grass && v != Px.grassLight && v != Px.grassDark)) continue;
      if (y > topEnd[x] - 1) continue;
      set(x, y, rnd(i, 7, 13) < 0.3 ? Px.flowerLight : Px.flower);
    }

    // Twinkles around the current island.
    if (state == NodeState.current) {
      for (final (x, y) in [(2, 2), (width - 6, (gcy + 1).round()), (3, (gcy + 24).round()), (width - 9, height - 8)]) {
        for (final (dx, dy) in const [(2, 0), (2, 1), (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (2, 3), (2, 4)]) {
          if (at(x + dx, y + dy) == Px.none) set(x + dx, y + dy, Px.sparkle);
        }
      }
    }
    return g;
  }

  static void _tree(void Function(int, int, int) set, double Function(int, int, int) rnd, int x, int base) {
    for (var y = base - 6; y <= base; y++) {
      set(x, y, Px.trunk);
      set(x + 1, y, Px.trunk);
    }
    set(x - 1, base, Px.trunk);
    set(x + 2, base, Px.trunk);
    final cy = base - 8;
    const r = 4.8;
    for (var y = cy - 5; y <= cy + 5; y++) {
      for (var xx = x - 5; xx <= x + 6; xx++) {
        final dx = xx + 0.5 - (x + 1), dy = y + 0.5 - cy;
        if (dx * dx + dy * dy > r * r) continue;
        var v = Px.leaf;
        if (dx + dy < -3) v = Px.leafLight;
        if (dx + dy > 3) v = Px.leafDark;
        final n = rnd(xx, y, 14);
        if (n < 0.15) v = Px.leafLight;
        if (n > 0.85) v = Px.leafDark;
        set(xx, y, v);
      }
    }
  }

  static void _rock(void Function(int, int, int) set, int x, int y, int w, int h) {
    for (var dy = 0; dy < h; dy++) {
      for (var dx = 0; dx < w; dx++) {
        set(x + dx, y + dy, dy == 0 ? Px.stone : Px.earthDark);
      }
    }
  }
}

class _IslandPainter extends CustomPainter {
  _IslandPainter({
    required this.cell,
    required this.art,
    required this.icon,
    required this.state,
    required this.unitColor,
    required this.gold,
    required this.lockedFace,
    required this.pressed,
  });

  final double cell;
  final Uint8List art;
  final List<String> icon;
  final NodeState state;
  final Color unitColor, gold, lockedFace;
  final bool pressed;

  static const _base = <int, Color>{
    Px.outline: Color(0xFF231A14),
    Px.grassLight: Color(0xFF8BD45A),
    Px.grass: Color(0xFF5DB043),
    Px.grassDark: Color(0xFF3F8A35),
    Px.grassDeep: Color(0xFF2C6A2E),
    Px.earthLight: Color(0xFFA8754A),
    Px.earth: Color(0xFF85573A),
    Px.earthDark: Color(0xFF64402C),
    Px.earthDeep: Color(0xFF462C20),
    Px.stone: Color(0xFF9A948E),
    Px.vine: Color(0xFF3E8F3A),
    Px.vineLight: Color(0xFF7CC75A),
    Px.water: Color(0xFF5AB4E6),
    Px.foam: Color(0xFFD8F1FF),
    Px.leafLight: Color(0xFF7CC95A),
    Px.leaf: Color(0xFF4E9E3E),
    Px.leafDark: Color(0xFF2F6F30),
    Px.trunk: Color(0xFF5A3A26),
    Px.pole: Color(0xFF4A3524),
    Px.flag: Color(0xFFE5484D),
  };

  bool get _locked => state == NodeState.locked;

  /// A locked island is mid-grey in both themes, a little tinted by the
  /// theme's surface, so it stays visible on light and dark backgrounds.
  Color _tone(Color color) {
    if (!_locked) return color;
    final l = (60 + color.computeLuminance() * 300).round().clamp(0, 255);
    return Color.lerp(Color.fromARGB(255, l, l, l), lockedFace, 0.2)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final colors = List<Color?>.filled(Px.count, null);
    for (final MapEntry(:key, :value) in _base.entries) {
      colors[key] = key == Px.outline ? value : _tone(value);
    }
    colors[Px.flower] = _tone(Color.lerp(unitColor, Colors.white, 0.3)!);
    colors[Px.flowerLight] = _tone(Color.lerp(unitColor, Colors.white, 0.65)!);
    colors[Px.sparkle] = unitColor;

    final push = pressed ? 2 : 0;
    final paint = Paint()..isAntiAlias = false;
    void rect(int x0, int x1, int y, int scale, Color color) {
      paint.color = color;
      canvas.drawRect(Rect.fromLTRB(x0 * cell, y * cell, x1 * cell, (y + scale) * cell), paint);
    }

    // Runs of one color are one rect.
    const w = IslandArt.width;
    for (var y = 0; y < IslandArt.height; y++) {
      var x = 0;
      while (x < w) {
        final v = art[y * w + x];
        var end = x + 1;
        while (end < w && art[y * w + end] == v) {
          end++;
        }
        final color = colors[v];
        if (color != null) rect(x, end, y + (v == Px.sparkle ? 0 : push), 1, color);
        x = end;
      }
    }

    // The icon, two art pixels per icon pixel, with a one-pixel dark edge
    // and a drop shadow so it reads on the grass.
    final (ink, edge) = switch (state) {
      NodeState.done => (gold, const Color(0xFF3D2A00)),
      NodeState.locked => (const Color(0xFFE6E2EA), _base[Px.outline]!),
      _ => (Colors.white, _base[Px.outline]!),
    };
    void glyph(int ox, int oy, Color color) {
      for (final (iy, line) in icon.indexed) {
        for (var ix = 0; ix < line.length; ix++) {
          if (line[ix] != '#') continue;
          final x = IslandArt.iconX + ix * 2 + ox, y = IslandArt.iconY + iy * 2 + oy + push;
          rect(x, x + 2, y, 2, color);
        }
      }
    }

    for (final (dx, dy) in const [(-1, 0), (1, 0), (0, -1), (0, 1), (0, 2)]) {
      glyph(dx, dy, edge);
    }
    glyph(0, 0, ink);
  }

  @override
  bool shouldRepaint(_IslandPainter old) =>
      old.cell != cell ||
      old.art != art ||
      old.icon != icon ||
      old.state != state ||
      old.unitColor != unitColor ||
      old.gold != gold ||
      old.lockedFace != lockedFace ||
      old.pressed != pressed;
}

/// The icons, one string per row, # filled.
abstract final class PixelArt {
  static const star = [
    '....#....',
    '....#....',
    '...###...',
    '#########',
    '.#######.',
    '..#####..',
    '..##.##..',
    '.##...##.',
    '.#.....#.',
  ];

  static const check = [
    '.........',
    '........#',
    '.......##',
    '#.....##.',
    '##...##..',
    '.##.##...',
    '..###....',
    '...#.....',
    '.........',
  ];

  static const lock = [
    '..#####..',
    '.##...##.',
    '.#.....#.',
    '#########',
    '#########',
    '####.####',
    '####.####',
    '#########',
    '.#######.',
  ];

  static const pencil = [
    '......##.',
    '.....####',
    '....####.',
    '...####..',
    '..####...',
    '.####....',
    '.###.....',
    '##.......',
    '#........',
  ];

  static const replay = [
    '..####.#.',
    '.#....##.',
    '#....###.',
    '#........',
    '#.......#',
    '#.......#',
    '.#.....#.',
    '..#####..',
    '.........',
  ];

  static const cards = [
    '#####....',
    '#...#....',
    '#.######.',
    '#.#....#.',
    '#.#....#.',
    '###....#.',
    '..#....#.',
    '..######.',
    '.........',
  ];

  static const bolt = [
    '....####.',
    '...####..',
    '..####...',
    '.#######.',
    '....###..',
    '...###...',
    '..###....',
    '.##......',
    '#........',
  ];

  static const chest = [
    '.#######.',
    '#########',
    '#########',
    '.........',
    '####.####',
    '####.####',
    '#########',
    '#########',
    '.#######.',
  ];
}
