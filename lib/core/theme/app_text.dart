import 'package:flutter/material.dart';

/// Font families (ui-design.md §4.2), bundled as subset assets (never
/// downloaded at runtime). The Japanese fonts contain kana plus the ~3,600
/// kanji used by common/JLPT words; rarer characters fall back to the
/// platform CJK font, so no fallback family is bundled.
abstract final class AppFonts {
  static const latin = 'PlusJakartaSans';
  static const jpUi = 'ZenKakuGothicNew';
  static const jpDisplay = 'ShipporiMincho';
  static const jpStroke = 'KleeOne';
  static const fallback = <String>[];
}

/// Type scale (≈ 1.25 ratio, sp). Japanese text uses 1.6–1.8 line height,
/// Latin 1.4–1.5.
abstract final class AppText {
  static const displayCard = TextStyle(
    fontFamily: AppFonts.jpDisplay,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 72,
    height: 80 / 72,
    fontWeight: FontWeight.w400,
  );
  static const displayWord = TextStyle(
    fontFamily: AppFonts.jpDisplay,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w400,
  );

  /// Headword in result rows (Mincho 22).
  static const rowHeadword = TextStyle(
    fontFamily: AppFonts.jpDisplay,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 22,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  // Latin styles fall back to the bundled Japanese UI font, so Japanese
  // characters inside Latin text ("あ Hiragana", "N5 たべる") never hit the
  // Latin font's missing glyphs or an inconsistent system font.
  static const _latinFallback = [AppFonts.jpUi];

  static const title1 = TextStyle(
    fontFamily: AppFonts.latin,
    fontFamilyFallback: _latinFallback,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
  );
  static const title2 = TextStyle(
    fontFamily: AppFonts.latin,
    fontFamilyFallback: _latinFallback,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );
  static const bodyJp = TextStyle(
    fontFamily: AppFonts.jpUi,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 18,
    height: 30 / 18,
    fontWeight: FontWeight.w400,
  );
  static const body = TextStyle(
    fontFamily: AppFonts.latin,
    fontFamilyFallback: _latinFallback,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );
  static const bodySmall = TextStyle(
    fontFamily: AppFonts.latin,
    fontFamilyFallback: _latinFallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  /// Kana readings next to Latin text (e.g. "たべる  taberu"); the Latin font
  /// has no kana glyphs, so Japanese spans must set this explicitly.
  static const bodySmallJp = TextStyle(
    fontFamily: AppFonts.jpUi,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const label = TextStyle(
    fontFamily: AppFonts.latin,
    fontFamilyFallback: _latinFallback,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w500,
  );
}
