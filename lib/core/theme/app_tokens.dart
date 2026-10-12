/// Spacing, radius and motion tokens (ui-design.md §4.3, §4.4, §8).
library;

/// 4 dp base unit.
abstract final class AppSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Screen margin (24 on tablets).
  static const double screen = 16;
  static const double screenTablet = 24;

  /// Max content width on wide screens.
  static const double maxContentWidth = 640;

  /// Minimum touch target.
  static const double touch = 48;
}

/// Radius by hierarchy (ui-design §4.4).
abstract final class AppRadius {
  static const double badge = 6; // JLPT badge, small chips
  static const double control = 14; // buttons, fields, kana tiles
  static const double card = 20; // menu cards, flashcards, quiz cards
  static const double hero = 24; // one hero card per screen
  static const double sheet = 28; // bottom sheet top corners
  static const double stamp = 6; // square hanko
}

abstract final class AppDurations {
  static const page = Duration(milliseconds: 240);
  static const cardFlip = Duration(milliseconds: 240);
  static const nextCard = Duration(milliseconds: 200);
  static const bookmark = Duration(milliseconds: 160);
  static const stamp = Duration(milliseconds: 180);
  static const sheet = Duration(milliseconds: 220);
  static const press = Duration(milliseconds: 80);

  /// Reduced-motion replacement for flips and slides.
  static const crossFade = Duration(milliseconds: 120);

  /// Search debounce (PRD NFR: ≤ 150 ms).
  static const searchDebounce = Duration(milliseconds: 150);
}

abstract final class AppSizes {
  /// Smallest touch area of a control (Material, WCAG target size).
  static const double minTap = 48;
  static const double buttonHeight = 52;
  static const double searchFieldHeight = 52;
  static const double wordRowMinHeight = 72;
  static const double exactMatchBar = 3;
  static const double progressRingStroke = 6;
}
