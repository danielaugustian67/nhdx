import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colour palettes (names are proper names; [custom] is shown localized)
/// and the colours derived from a custom accent.
enum ThemePalette {
  sakura(
    id: 'sakura',
    name: 'Sakura Yoru',
    seedColor: Color(0xFFC2406F),
  ),
  matcha(
    id: 'matcha',
    name: 'Matcha Zen',
    seedColor: Color(0xFF2E7D32),
  ),
  aoi(
    id: 'aoi',
    name: 'Aoi Fuji',
    seedColor: Color(0xFF1E6091),
  ),
  mikan(
    id: 'mikan',
    name: 'Mikan Sunset',
    seedColor: Color(0xFFE65100),
  ),
  murasaki(
    id: 'murasaki',
    name: 'Murasaki',
    seedColor: Color(0xFF7E22CE),
  ),
  kuro(
    id: 'kuro',
    name: 'Kuro Slate',
    seedColor: Color(0xFF64748B),
  ),
  custom(
    id: 'custom',
    name: 'Custom',
    seedColor: null,
  );

  const ThemePalette({
    required this.id,
    required this.name,
    required this.seedColor,
  });

  final String id;
  final String name;
  final Color? seedColor;

  static const settingKey = 'device.theme_palette';
  static const customColorKey = 'device.custom_color';
  static const pureBlackKey = 'device.pure_black';

  static ThemePalette parse(String? v) =>
      values.firstWhere((p) => p.id == v || p.name == v, orElse: () => sakura);

  /// Resolves the [AppColors] for the given brightness and options.
  AppColors resolveColors(
    Brightness brightness, {
    int? customColorValue,
    bool pureBlack = false,
  }) {
    if (brightness == Brightness.dark) {
      return _buildDark(customColorValue, pureBlack);
    } else {
      return _buildLight(customColorValue);
    }
  }

  AppColors _buildDark(int? customColorValue, bool pureBlack) {
    switch (this) {
      case ThemePalette.sakura:
        final base = AppColors.dark;
        if (!pureBlack) return base;
        return base.copyWith(
          bg: const Color(0xFF000000),
          surface: const Color(0xFF100C14),
          surfaceHigh: const Color(0xFF1C1523),
          line: const Color(0xFF2A2033),
        );

      case ThemePalette.matcha:
        return AppColors(
          bg: pureBlack ? const Color(0xFF000000) : const Color(0xFF0F1612),
          surface: pureBlack ? const Color(0xFF0D1410) : const Color(0xFF16211B),
          surfaceHigh: pureBlack ? const Color(0xFF16221B) : const Color(0xFF1F2E25),
          ink: const Color(0xFFEFF7F1),
          inkMuted: const Color(0xFFA1B5A7),
          primary: const Color(0xFF2E7D32),
          primaryText: const Color(0xFF81C784),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFF4DB6AC),
          success: const Color(0xFF66BB6A),
          seal: const Color(0xFFFF8A5B),
          onSeal: const Color(0xFF0F1612),
          gold: const Color(0xFFFFD27A),
          goldFill: const Color(0xFFFFD27A),
          line: const Color(0xFF26382E),
          jlptBackground: const [
            Color(0xFF1F2E25),
            Color(0xFF274332),
            Color(0xFF2E6342),
            Color(0xFF2E7D32),
            Color(0xFF81C784),
          ],
          jlptForeground: const [
            Color(0xFFA8D5B5),
            Color(0xFFC8E6D2),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFF0F1612),
          ],
        );

      case ThemePalette.aoi:
        return AppColors(
          bg: pureBlack ? const Color(0xFF000000) : const Color(0xFF0E141D),
          surface: pureBlack ? const Color(0xFF0C121A) : const Color(0xFF151E2B),
          surfaceHigh: pureBlack ? const Color(0xFF15202E) : const Color(0xFF1D293B),
          ink: const Color(0xFFEFF5FB),
          inkMuted: const Color(0xFFA2B4CA),
          primary: const Color(0xFF2563EB),
          primaryText: const Color(0xFF60A5FA),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFF38BDF8),
          success: const Color(0xFF34D399),
          seal: const Color(0xFFFF8A5B),
          onSeal: const Color(0xFF0E141D),
          gold: const Color(0xFFFFD27A),
          goldFill: const Color(0xFFFFD27A),
          line: const Color(0xFF25344A),
          jlptBackground: const [
            Color(0xFF1D293B),
            Color(0xFF1E3A5F),
            Color(0xFF1D4ED8),
            Color(0xFF2563EB),
            Color(0xFF60A5FA),
          ],
          jlptForeground: const [
            Color(0xFFBFDBFE),
            Color(0xFFDBEAFE),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFF0E141D),
          ],
        );

      case ThemePalette.mikan:
        return AppColors(
          bg: pureBlack ? const Color(0xFF000000) : const Color(0xFF1A1410),
          surface: pureBlack ? const Color(0xFF140F0D) : const Color(0xFF251D17),
          surfaceHigh: pureBlack ? const Color(0xFF221A15) : const Color(0xFF33271F),
          ink: const Color(0xFFFAF3EE),
          inkMuted: const Color(0xFFC0ADA1),
          primary: const Color(0xFFC2410C),
          primaryText: const Color(0xFFFB923C),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFFFBBF24),
          success: const Color(0xFF34D399),
          seal: const Color(0xFFFF8A5B),
          onSeal: const Color(0xFF1A1410),
          gold: const Color(0xFFFFD27A),
          goldFill: const Color(0xFFFFD27A),
          line: const Color(0xFF3E3026),
          jlptBackground: const [
            Color(0xFF33271F),
            Color(0xFF4D3220),
            Color(0xFF9A3412),
            Color(0xFFC2410C),
            Color(0xFFFB923C),
          ],
          jlptForeground: const [
            Color(0xFFFED7AA),
            Color(0xFFFFEDD5),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFF1A1410),
          ],
        );

      case ThemePalette.murasaki:
        return AppColors(
          bg: pureBlack ? const Color(0xFF000000) : const Color(0xFF15101A),
          surface: pureBlack ? const Color(0xFF100C14) : const Color(0xFF201827),
          surfaceHigh: pureBlack ? const Color(0xFF1C1523) : const Color(0xFF2B2034),
          ink: const Color(0xFFF7EFFB),
          inkMuted: const Color(0xFFB9A6C2),
          primary: const Color(0xFF9333EA),
          primaryText: const Color(0xFFC084FC),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFF38BDF8),
          success: const Color(0xFF34D399),
          seal: const Color(0xFFFF8A5B),
          onSeal: const Color(0xFF15101A),
          gold: const Color(0xFFFFD27A),
          goldFill: const Color(0xFFFFD27A),
          line: const Color(0xFF382944),
          jlptBackground: const [
            Color(0xFF2B2034),
            Color(0xFF3F2356),
            Color(0xFF6B21A8),
            Color(0xFF9333EA),
            Color(0xFFC084FC),
          ],
          jlptForeground: const [
            Color(0xFFE9D5FF),
            Color(0xFFF3E8FF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFF15101A),
          ],
        );

      case ThemePalette.kuro:
        return AppColors(
          bg: pureBlack ? const Color(0xFF000000) : const Color(0xFF121214),
          surface: pureBlack ? const Color(0xFF0E0E10) : const Color(0xFF1A1A1E),
          surfaceHigh: pureBlack ? const Color(0xFF17171C) : const Color(0xFF26262C),
          ink: const Color(0xFFF1F1F5),
          inkMuted: const Color(0xFFA0A0AB),
          primary: const Color(0xFF64748B),
          primaryText: const Color(0xFFCBD5E1),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFF94A3B8),
          success: const Color(0xFF4ADE80),
          seal: const Color(0xFFFF8A5B),
          onSeal: const Color(0xFF121214),
          gold: const Color(0xFFFFD27A),
          goldFill: const Color(0xFFFFD27A),
          line: const Color(0xFF33333C),
          jlptBackground: const [
            Color(0xFF26262C),
            Color(0xFF334155),
            Color(0xFF475569),
            Color(0xFF64748B),
            Color(0xFFCBD5E1),
          ],
          jlptForeground: const [
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFF121214),
          ],
        );

      case ThemePalette.custom:
        final seed = customColorValue != null ? Color(customColorValue) : const Color(0xFFC2406F);
        return _deriveCustomDark(seed, pureBlack);
    }
  }

  AppColors _buildLight(int? customColorValue) {
    switch (this) {
      case ThemePalette.sakura:
        return AppColors.light;

      case ThemePalette.matcha:
        return AppColors(
          bg: const Color(0xFFF5FAF6),
          surface: const Color(0xFFFFFFFF),
          surfaceHigh: const Color(0xFFE8F4EC),
          ink: const Color(0xFF132318),
          inkMuted: const Color(0xFF4D6654),
          primary: const Color(0xFF2E7D32),
          primaryText: const Color(0xFF1B5E20),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFF00695C),
          success: const Color(0xFF1B5E20),
          seal: const Color(0xFFB8441A),
          onSeal: const Color(0xFFFFFFFF),
          gold: const Color(0xFF8A5F00),
          goldFill: const Color(0xFFFFC24A),
          line: const Color(0xFFD6E8DC),
          jlptBackground: const [
            Color(0xFFE8F5E9),
            Color(0xFFC8E6C9),
            Color(0xFFA5D6A7),
            Color(0xFF4CAF50),
            Color(0xFF2E7D32),
          ],
          jlptForeground: const [
            Color(0xFF1B5E20),
            Color(0xFF1B5E20),
            Color(0xFF132318),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
          ],
        );

      case ThemePalette.aoi:
        return AppColors(
          bg: const Color(0xFFF4F7FC),
          surface: const Color(0xFFFFFFFF),
          surfaceHigh: const Color(0xFFE8EEF8),
          ink: const Color(0xFF111827),
          inkMuted: const Color(0xFF4B5563),
          primary: const Color(0xFF1D4ED8),
          primaryText: const Color(0xFF1E40AF),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFF0284C7),
          success: const Color(0xFF059669),
          seal: const Color(0xFFB8441A),
          onSeal: const Color(0xFFFFFFFF),
          gold: const Color(0xFF8A5F00),
          goldFill: const Color(0xFFFFC24A),
          line: const Color(0xFFD7E2F2),
          jlptBackground: const [
            Color(0xFFEFF6FF),
            Color(0xFFDBEAFE),
            Color(0xFFBFDBFE),
            Color(0xFF3B82F6),
            Color(0xFF1D4ED8),
          ],
          jlptForeground: const [
            Color(0xFF1E40AF),
            Color(0xFF1E40AF),
            Color(0xFF111827),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
          ],
        );

      case ThemePalette.mikan:
        return AppColors(
          bg: const Color(0xFFFDF8F5),
          surface: const Color(0xFFFFFFFF),
          surfaceHigh: const Color(0xFFF8EDE6),
          ink: const Color(0xFF261912),
          inkMuted: const Color(0xFF6F5649),
          primary: const Color(0xFFC2410C),
          primaryText: const Color(0xFF9A3412),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFFB45309),
          success: const Color(0xFF047857),
          seal: const Color(0xFFB8441A),
          onSeal: const Color(0xFFFFFFFF),
          gold: const Color(0xFF8A5F00),
          goldFill: const Color(0xFFFFC24A),
          line: const Color(0xFFEEDCD2),
          jlptBackground: const [
            Color(0xFFFFF7ED),
            Color(0xFFFFEDD5),
            Color(0xFFFED7AA),
            Color(0xFFF97316),
            Color(0xFFC2410C),
          ],
          jlptForeground: const [
            Color(0xFF9A3412),
            Color(0xFF9A3412),
            Color(0xFF261912),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
          ],
        );

      case ThemePalette.murasaki:
        return AppColors(
          bg: const Color(0xFFFAF7FC),
          surface: const Color(0xFFFFFFFF),
          surfaceHigh: const Color(0xFFF2ECF7),
          ink: const Color(0xFF1F1528),
          inkMuted: const Color(0xFF635272),
          primary: const Color(0xFF7E22CE),
          primaryText: const Color(0xFF6B21A8),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFF0284C7),
          success: const Color(0xFF047857),
          seal: const Color(0xFFB8441A),
          onSeal: const Color(0xFFFFFFFF),
          gold: const Color(0xFF8A5F00),
          goldFill: const Color(0xFFFFC24A),
          line: const Color(0xFFE6DCEE),
          jlptBackground: const [
            Color(0xFFFAF5FF),
            Color(0xFFF3E8FF),
            Color(0xFFE9D5FF),
            Color(0xFFA855F7),
            Color(0xFF7E22CE),
          ],
          jlptForeground: const [
            Color(0xFF6B21A8),
            Color(0xFF6B21A8),
            Color(0xFF1F1528),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
          ],
        );

      case ThemePalette.kuro:
        return AppColors(
          bg: const Color(0xFFF8F9FA),
          surface: const Color(0xFFFFFFFF),
          surfaceHigh: const Color(0xFFEEF0F2),
          ink: const Color(0xFF18191B),
          inkMuted: const Color(0xFF5A5C63),
          primary: const Color(0xFF475569),
          primaryText: const Color(0xFF334155),
          onPrimary: const Color(0xFFFFFFFF),
          accent: const Color(0xFF334155),
          success: const Color(0xFF16A34A),
          seal: const Color(0xFFB8441A),
          onSeal: const Color(0xFFFFFFFF),
          gold: const Color(0xFF8A5F00),
          goldFill: const Color(0xFFFFC24A),
          line: const Color(0xFFDCE0E5),
          jlptBackground: const [
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
            Color(0xFFCBD5E1),
            Color(0xFF64748B),
            Color(0xFF475569),
          ],
          jlptForeground: const [
            Color(0xFF334155),
            Color(0xFF334155),
            Color(0xFF18191B),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
          ],
        );

      case ThemePalette.custom:
        final seed = customColorValue != null ? Color(customColorValue) : const Color(0xFFB8336A);
        return _deriveCustomLight(seed);
    }
  }

  static AppColors _deriveCustomDark(Color seed, bool pureBlack) {
    final hsl = HSLColor.fromColor(seed);
    final primary = seed;
    final primaryText = hsl.withLightness(0.75).withSaturation(0.65).toColor();
    final accent = hsl.withHue((hsl.hue + 40) % 360).withLightness(0.72).toColor();

    final bg = pureBlack
        ? const Color(0xFF000000)
        : hsl.withLightness(0.08).withSaturation(0.12).toColor();
    final surface = pureBlack
        ? const Color(0xFF0F0E13)
        : hsl.withLightness(0.12).withSaturation(0.14).toColor();
    final surfaceHigh = pureBlack
        ? const Color(0xFF1B1922)
        : hsl.withLightness(0.17).withSaturation(0.16).toColor();
    final line = hsl.withLightness(0.24).withSaturation(0.16).toColor();

    return AppColors(
      bg: bg,
      surface: surface,
      surfaceHigh: surfaceHigh,
      ink: const Color(0xFFF7EFF3),
      inkMuted: const Color(0xFFB6A8B4),
      primary: primary,
      primaryText: primaryText,
      onPrimary: const Color(0xFFFFFFFF),
      accent: accent,
      success: const Color(0xFF4FD69C),
      seal: const Color(0xFFFF8A5B),
      onSeal: const Color(0xFF141019),
      gold: const Color(0xFFFFD27A),
      goldFill: const Color(0xFFFFD27A),
      line: line,
      jlptBackground: [
        surfaceHigh,
        hsl.withLightness(0.25).withSaturation(0.35).toColor(),
        hsl.withLightness(0.35).withSaturation(0.45).toColor(),
        primary,
        primaryText,
      ],
      jlptForeground: [
        primaryText,
        primaryText,
        const Color(0xFFFFFFFF),
        const Color(0xFFFFFFFF),
        const Color(0xFF141019),
      ],
    );
  }

  static AppColors _deriveCustomLight(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    // Ensure primary in light mode is dark enough for white onPrimary (contrast >= 4.5)
    final primary = hsl.withLightness(0.36).withSaturation(0.75).toColor();
    final primaryText = hsl.withLightness(0.26).withSaturation(0.75).toColor();
    final accent = hsl.withHue((hsl.hue + 40) % 360).withLightness(0.32).toColor();

    final bg = hsl.withLightness(0.98).withSaturation(0.08).toColor();
    const surface = Color(0xFFFFFFFF);
    final surfaceHigh = hsl.withLightness(0.93).withSaturation(0.10).toColor();
    final line = hsl.withLightness(0.87).withSaturation(0.10).toColor();

    return AppColors(
      bg: bg,
      surface: surface,
      surfaceHigh: surfaceHigh,
      ink: const Color(0xFF22161D),
      inkMuted: const Color(0xFF655460),
      primary: primary,
      primaryText: primaryText,
      onPrimary: const Color(0xFFFFFFFF),
      accent: accent,
      success: const Color(0xFF1A7A51),
      seal: const Color(0xFFB8441A),
      onSeal: const Color(0xFFFFFFFF),
      gold: const Color(0xFF8A5F00),
      goldFill: const Color(0xFFFFC24A),
      line: line,
      jlptBackground: [
        hsl.withLightness(0.93).withSaturation(0.20).toColor(),
        hsl.withLightness(0.84).withSaturation(0.35).toColor(),
        hsl.withLightness(0.70).withSaturation(0.45).toColor(),
        primary,
        primaryText,
      ],
      jlptForeground: [
        primaryText,
        primaryText,
        const Color(0xFF22161D),
        const Color(0xFFFFFFFF),
        const Color(0xFFFFFFFF),
      ],
    );
  }
}

/// Popular curated swatch colors for custom color picking.
abstract final class CustomThemeSwatches {
  static const list = <Color>[
    Color(0xFFE11D48), // Rose
    Color(0xFFDC2626), // Crimson
    Color(0xFFEA580C), // Orange
    Color(0xFFD97706), // Amber
    Color(0xFF16A34A), // Green
    Color(0xFF059669), // Emerald
    Color(0xFF0D9488), // Teal
    Color(0xFF0284C7), // Sky
    Color(0xFF2563EB), // Blue
    Color(0xFF4F46E5), // Indigo
    Color(0xFF7C3AED), // Violet
    Color(0xFFC026D3), // Fuchsia
  ];
}
