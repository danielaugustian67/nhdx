import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/theme/theme_palette.dart';

void main() {
  double contrast(Color a, Color b) {
    final (x, y) = (a.computeLuminance(), b.computeLuminance());
    return (max(x, y) + 0.05) / (min(x, y) + 0.05);
  }

  group('ThemePalette parsing', () {
    test('parses known ids and names with fallback to sakura', () {
      expect(ThemePalette.parse(null), ThemePalette.sakura);
      expect(ThemePalette.parse(''), ThemePalette.sakura);
      expect(ThemePalette.parse('unknown'), ThemePalette.sakura);
      expect(ThemePalette.parse('matcha'), ThemePalette.matcha);
      expect(ThemePalette.parse('aoi'), ThemePalette.aoi);
      expect(ThemePalette.parse('mikan'), ThemePalette.mikan);
      expect(ThemePalette.parse('murasaki'), ThemePalette.murasaki);
      expect(ThemePalette.parse('kuro'), ThemePalette.kuro);
      expect(ThemePalette.parse('custom'), ThemePalette.custom);
    });
  });

  group('Pure black mode', () {
    test('pureBlack sets bg to #000000 on dark themes', () {
      for (final p in ThemePalette.values) {
        final colors = p.resolveColors(Brightness.dark, pureBlack: true);
        expect(colors.bg, const Color(0xFF000000), reason: 'Palette ${p.id} pureBlack bg');
      }
    });

    test('pureBlack does not affect light theme bg', () {
      for (final p in ThemePalette.values) {
        final colors = p.resolveColors(Brightness.light, pureBlack: true);
        expect(colors.bg, isNot(const Color(0xFF000000)), reason: 'Palette ${p.id} light bg');
      }
    });
  });

  group('Custom color derivation', () {
    test('derives custom colors in both dark and light modes', () {
      const customSeed = Color(0xFFE11D48); // Rose
      final darkColors = ThemePalette.custom.resolveColors(
        Brightness.dark,
        customColorValue: customSeed.toARGB32(),
      );
      final lightColors = ThemePalette.custom.resolveColors(
        Brightness.light,
        customColorValue: customSeed.toARGB32(),
      );

      expect(darkColors.primary, customSeed);
      expect(lightColors.primary, isNotNull);
      expect(darkColors.primaryText, isNotNull);
      expect(lightColors.primaryText, isNotNull);
      expect(darkColors.jlptBackground.length, 5);
      expect(lightColors.jlptBackground.length, 5);
    });
  });

  group('Theme presets WCAG AA contrast', () {
    for (final palette in [
      ThemePalette.sakura,
      ThemePalette.matcha,
      ThemePalette.aoi,
      ThemePalette.mikan,
      ThemePalette.murasaki,
      ThemePalette.kuro,
    ]) {
      for (final brightness in [Brightness.dark, Brightness.light]) {
        test('${palette.name} in $brightness meets AA contrast for essential text', () {
          final c = palette.resolveColors(brightness);
          final backgrounds = {'bg': c.bg, 'surface': c.surface, 'surfaceHigh': c.surfaceHigh};
          final failures = <String>[];

          for (final MapEntry(key: bName, value: bg) in backgrounds.entries) {
            final inkRatio = contrast(c.ink, bg);
            if (inkRatio < 4.5) {
              failures.add('ink on $bName ($inkRatio)');
            }
            final primaryRatio = contrast(c.primaryText, bg);
            if (primaryRatio < 4.5) {
              failures.add('primaryText on $bName ($primaryRatio)');
            }
          }

          final onPrimaryRatio = contrast(c.onPrimary, c.primary);
          if (onPrimaryRatio < 4.5) {
            failures.add('onPrimary on primary ($onPrimaryRatio)');
          }

          expect(failures, isEmpty);
        });
      }
    }
  });
}
