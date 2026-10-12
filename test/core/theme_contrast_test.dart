import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/theme/app_colors.dart';

/// WCAG AA (4.5:1 for body text) for every text color on every background
/// it is drawn on, in both themes. Checked on the tokens because the widget
/// contrast guideline estimates colors from anti-aliased pixels.
void main() {
  double contrast(Color a, Color b) {
    final (x, y) = (a.computeLuminance(), b.computeLuminance());
    return (max(x, y) + 0.05) / (min(x, y) + 0.05);
  }

  for (final (name, c) in [('dark', AppColors.dark), ('light', AppColors.light)]) {
    test('$name theme text meets AA', () {
      final backgrounds = {'bg': c.bg, 'surface': c.surface, 'surfaceHigh': c.surfaceHigh};
      final texts = {
        'ink': c.ink,
        'inkMuted': c.inkMuted,
        'primaryText': c.primaryText,
        'accent': c.accent,
        'success': c.success,
        'seal': c.seal,
        'gold': c.gold,
      };
      final failures = [
        for (final MapEntry(key: t, value: fg) in texts.entries)
          for (final MapEntry(key: b, value: bg) in backgrounds.entries)
            if (contrast(fg, bg) < 4.5) '$t on $b: ${contrast(fg, bg).toStringAsFixed(2)}',
        if (contrast(c.onPrimary, c.primary) < 4.5) 'onPrimary on primary',
        if (contrast(c.onSeal, c.seal) < 4.5) 'onSeal on seal',
        for (var level = 5; level >= 1; level--)
          if (contrast(c.jlptFg(level), c.jlptBg(level)) < 4.5) 'JLPT N$level badge',
      ];
      expect(failures, isEmpty);
    });
  }
}
