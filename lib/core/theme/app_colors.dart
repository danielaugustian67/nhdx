import 'package:flutter/material.dart';

/// Color tokens from ui-design.md §4.1 ("Sakura yoru": plum night, sakura
/// pink action color, gold/sky rewards, vermilion seal). Dark is the default
/// theme.
/// All text pairs are ≥ 4.5:1 (WCAG); ratios are listed in ui-design.md.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.ink,
    required this.inkMuted,
    required this.primary,
    required this.primaryText,
    required this.onPrimary,
    required this.accent,
    required this.success,
    required this.seal,
    required this.onSeal,
    required this.gold,
    required this.goldFill,
    required this.line,
    required this.jlptBackground,
    required this.jlptForeground,
  });

  final Color bg;
  final Color surface;

  /// Raised cards, kana tiles, selected chips.
  final Color surfaceHigh;
  final Color ink;
  final Color inkMuted;

  /// Fill for primary buttons, progress and active tab.
  final Color primary;

  /// Sakura pink used as text/link on [bg] (primary itself is too dark for text).
  final Color primaryText;
  final Color onPrimary;

  /// Combo, timer, secondary highlight.
  final Color accent;
  final Color success;

  /// Stamps, streaks, wrong answers.
  final Color seal;

  /// Text on a [seal] fill (white fails AA on the dark theme's light red).
  final Color onSeal;

  /// XP, coins, achievements (text and icons).
  final Color gold;

  /// Gold as a large fill (finished lesson nodes): light theme's [gold] is
  /// darkened for text contrast and looks brown as a fill. Pair with dark ink.
  final Color goldFill;
  final Color line;

  /// Sakura ramp for JLPT badges, index 0 = N5 … 4 = N1.
  final List<Color> jlptBackground;
  final List<Color> jlptForeground;

  Color jlptBg(int level) => jlptBackground[5 - level];
  Color jlptFg(int level) => jlptForeground[5 - level];

  /// Gradient for hero cards and the main call to action.
  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.lerp(primary, bg, 0.15)!, Color.lerp(primary, accent, 0.35)!],
  );

  static const dark = AppColors(
    bg: Color(0xFF141019), // Yoru, plum night
    surface: Color(0xFF1E1824),
    surfaceHigh: Color(0xFF2A2131),
    ink: Color(0xFFF7EEF3),
    inkMuted: Color(0xFFB5A6B4),
    primary: Color(0xFFC2406F), // Sakura
    primaryText: Color(0xFFFF9EC0),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF7CC8F0), // night sky
    success: Color(0xFF4FD69C),
    seal: Color(0xFFFF8A5B), // shuniku, vermilion seal ink
    onSeal: Color(0xFF141019),
    gold: Color(0xFFFFD27A),
    goldFill: Color(0xFFFFD27A),
    line: Color(0xFF352A3C),
    // Contrast: N5 9.49, N4 9.79, N3 8.91, N2 6.25, N1 9.75
    jlptBackground: [Color(0xFF2E2232), Color(0xFF45263F), Color(0xFF7A2E57), Color(0xFFA8365F), Color(0xFFFF9EC0)],
    jlptForeground: [Color(0xFFF2BFD6), Color(0xFFFFD3E4), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF141019)],
  );

  static const light = AppColors(
    bg: Color(0xFFFBF5F8),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF5E9EF),
    ink: Color(0xFF22161D),
    inkMuted: Color(0xFF6B5563),
    primary: Color(0xFFB8336A),
    primaryText: Color(0xFFA02A5C),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF0B6F94),
    success: Color(0xFF1A7A51),
    seal: Color(0xFFB8441A),
    onSeal: Color(0xFFFFFFFF),
    gold: Color(0xFF8A5F00),
    goldFill: Color(0xFFFFC24A),
    line: Color(0xFFEADCE3),
    // Contrast: N5 5.85, N4 6.22, N3 7.21, N2 5.65, N1 9.08
    jlptBackground: [Color(0xFFFBE4EE), Color(0xFFF6CADC), Color(0xFFE58BB0), Color(0xFFB8336A), Color(0xFF861F4C)],
    jlptForeground: [Color(0xFFA02A5C), Color(0xFF861F4C), Color(0xFF22161D), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceHigh,
    Color? ink,
    Color? inkMuted,
    Color? primary,
    Color? primaryText,
    Color? onPrimary,
    Color? accent,
    Color? success,
    Color? seal,
    Color? onSeal,
    Color? gold,
    Color? goldFill,
    Color? line,
    List<Color>? jlptBackground,
    List<Color>? jlptForeground,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    primary: primary ?? this.primary,
    primaryText: primaryText ?? this.primaryText,
    onPrimary: onPrimary ?? this.onPrimary,
    accent: accent ?? this.accent,
    success: success ?? this.success,
    seal: seal ?? this.seal,
    onSeal: onSeal ?? this.onSeal,
    gold: gold ?? this.gold,
    goldFill: goldFill ?? this.goldFill,
    line: line ?? this.line,
    jlptBackground: jlptBackground ?? this.jlptBackground,
    jlptForeground: jlptForeground ?? this.jlptForeground,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> l(List<Color> a, List<Color> b) => [for (var i = 0; i < a.length; i++) c(a[i], b[i])];
    return AppColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      ink: c(ink, other.ink),
      inkMuted: c(inkMuted, other.inkMuted),
      primary: c(primary, other.primary),
      primaryText: c(primaryText, other.primaryText),
      onPrimary: c(onPrimary, other.onPrimary),
      accent: c(accent, other.accent),
      success: c(success, other.success),
      seal: c(seal, other.seal),
      onSeal: c(onSeal, other.onSeal),
      gold: c(gold, other.gold),
      goldFill: c(goldFill, other.goldFill),
      line: c(line, other.line),
      jlptBackground: l(jlptBackground, other.jlptBackground),
      jlptForeground: l(jlptForeground, other.jlptForeground),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
