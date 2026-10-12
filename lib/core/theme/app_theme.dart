import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';
import 'app_tokens.dart';
import 'theme_palette.dart';

/// Builds ThemeData from the design tokens (ui-design §4). Dark is the
/// default; elevation is expressed with surface tones and glow, not grey
/// shadows (§4.4).
abstract final class AppTheme {
  static ThemeData light([AppColors? colors]) => _build(colors ?? AppColors.light, Brightness.light);
  static ThemeData dark([AppColors? colors]) => _build(colors ?? AppColors.dark, Brightness.dark);

  static ThemeData build(
    Brightness brightness, {
    ThemePalette palette = ThemePalette.sakura,
    int? customColor,
    bool pureBlack = false,
  }) {
    final colors = palette.resolveColors(
      brightness,
      customColorValue: customColor,
      pureBlack: pureBlack,
    );
    return _build(colors, brightness);
  }

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.primary,
      onSecondary: c.onPrimary,
      error: c.seal,
      onError: c.onPrimary,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      outline: c.line,
      outlineVariant: c.line,
    );
    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      fontFamily: AppFonts.latin,
      extensions: [c],
      textTheme: TextTheme(
        headlineSmall: AppText.title1.copyWith(color: c.ink),
        titleLarge: AppText.title2.copyWith(color: c.ink),
        bodyLarge: AppText.body.copyWith(color: c.ink),
        bodyMedium: AppText.bodySmall.copyWith(color: c.ink),
        labelMedium: AppText.label.copyWith(color: c.ink),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppText.title2.copyWith(color: c.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primary.withValues(alpha: 0.28),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? c.primaryText : c.inkMuted),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppText.label.copyWith(
            color: states.contains(WidgetState.selected) ? c.ink : c.inkMuted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        showDragHandle: true,
        dragHandleColor: c.inkMuted,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.inkMuted,
          selectedBackgroundColor: c.primary,
          selectedForegroundColor: c.onPrimary,
          side: BorderSide(color: c.line),
          textStyle: AppText.label,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceHigh,
        circularTrackColor: c.surfaceHigh,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: controlShape,
          elevation: 0,
          textStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              shape: controlShape,
              foregroundColor: c.primaryText,
            ).copyWith(
              // Disabled buttons must not keep the violet border (looks tappable).
              side: WidgetStateProperty.resolveWith(
                (states) =>
                    BorderSide(color: states.contains(WidgetState.disabled) ? c.line : c.primaryText, width: 1.5),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: c.primaryText)),
      // The M3 default (inverse surface) left the "Urungkan" action unreadable.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceHigh,
        contentTextStyle: AppText.body.copyWith(color: c.ink),
        actionTextColor: c.primaryText,
        shape: controlShape,
      ),
      chipTheme: ChipThemeData(
        shape: controlShape,
        side: BorderSide(color: c.line),
        backgroundColor: c.surface,
        selectedColor: c.surfaceHigh,
        // Visible checkmark so selection is not shown by color alone (§4.1).
        checkmarkColor: c.primaryText,
        labelStyle: AppText.label.copyWith(color: c.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: AppText.body.copyWith(color: c.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.m),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c.primaryText, width: 2),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
