import 'package:flutter/material.dart';

/// Typography — `DESIGN_SYSTEM.md`.
///
/// Family is **Tajawal**, bundled in `assets/fonts/` rather than fetched at
/// runtime through `google_fonts`: a
/// network-loaded face means a flash of unstyled text on first launch and a
/// silent fallback to Roboto when offline. Tajawal covers Arabic and Latin
/// with the same rhythm, so switching language does not shift the layout.
///
/// Allowed weights are **400 / 500 / 700 / 800** only — no 300, no 600.
class AppTypography {
  AppTypography._();

  /// Family name as declared in `pubspec.yaml`.
  static const String fontFamily = 'Tajawal';

  /// Falls back to the platform Arabic face if the bundle is ever stripped.
  static const List<String> fontFamilyFallback = <String>[
    'Noto Sans Arabic',
    'Geeza Pro',
    'Roboto',
  ];

  /// Tabular figures — mandatory for prices, ratings and statistics so digits
  /// do not jitter as values change.
  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static TextTheme? _cachedTextTheme;

  /// The built text theme, available to non-widget code such as
  /// [AppTextStyles]. Null until [buildTextTheme] has run once.
  static TextTheme? get textTheme => _cachedTextTheme;

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      // Tracking is expressed in `em` in the spec; multiply by the size.
      letterSpacing: letterSpacing * size,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// The scale from `DESIGN_SYSTEM.md`, in plain logical pixels. The
  /// reader's own text size still applies on top (clamped to 85–130% in
  /// `App`), and expanded windows step the headings up ([expandedFrom]).
  static TextTheme get buildTextTheme {
    const tight = -0.01; // headings >= 18
    const wide = 0.02; // small badges

    final theme = TextTheme(
      // Display — app name on the splash/onboarding.
      displayLarge: _style(
        size: 40,
        weight: FontWeight.w800,
        height: 1.20,
        letterSpacing: tight,
      ),
      displayMedium: _style(
        size: 32,
        weight: FontWeight.w800,
        height: 1.25,
        letterSpacing: tight,
      ),
      displaySmall: _style(
        size: 26,
        weight: FontWeight.w800,
        height: 1.30,
        letterSpacing: tight,
      ),

      // Headline — news detail title.
      headlineLarge: _style(
        size: 24,
        weight: FontWeight.w800,
        height: 1.35,
        letterSpacing: tight,
      ),
      headlineMedium: _style(
        size: 23,
        weight: FontWeight.w800,
        height: 1.35,
        letterSpacing: tight,
      ),
      headlineSmall: _style(
        size: 22,
        weight: FontWeight.w800,
        height: 1.35,
        letterSpacing: tight,
      ),

      // Title — screen title, section title, card title, price.
      titleLarge: _style(
        size: 18,
        weight: FontWeight.w700,
        height: 1.40,
        letterSpacing: tight,
      ),
      titleMedium: _style(size: 16, weight: FontWeight.w700, height: 1.40),
      titleSmall: _style(size: 14, weight: FontWeight.w700, height: 1.45),

      // Body — article text, descriptions, secondary lines.
      bodyLarge: _style(size: 16, weight: FontWeight.w400, height: 1.75),
      bodyMedium: _style(size: 14, weight: FontWeight.w400, height: 1.65),
      bodySmall: _style(size: 12, weight: FontWeight.w400, height: 1.55),

      // Label — buttons, chips, badges.
      labelLarge: _style(size: 14, weight: FontWeight.w700, height: 1.30),
      labelMedium: _style(size: 12, weight: FontWeight.w500, height: 1.30),
      labelSmall: _style(
        size: 11,
        weight: FontWeight.w700,
        height: 1.30,
        letterSpacing: wide,
      ),
    );

    _cachedTextTheme = theme;
    return theme;
  }

  /// The headings one step larger, for expanded windows (840dp and wider).
  ///
  /// Display and headline +4, the two larger titles +2: a 28 large title
  /// reads small across a desktop window. Body, small titles and labels keep
  /// their size — lines stay a comfortable length because content is capped
  /// in width, not because the text grows.
  static TextTheme expandedFrom(TextTheme base) {
    TextStyle? up(TextStyle? style, double by) => style?.copyWith(
      fontSize: style.fontSize == null ? null : style.fontSize! + by,
    );
    return base.copyWith(
      displayLarge: up(base.displayLarge, 4),
      displayMedium: up(base.displayMedium, 4),
      displaySmall: up(base.displaySmall, 4),
      headlineLarge: up(base.headlineLarge, 4),
      headlineMedium: up(base.headlineMedium, 4),
      headlineSmall: up(base.headlineSmall, 4),
      titleLarge: up(base.titleLarge, 2),
      titleMedium: up(base.titleMedium, 2),
    );
  }
}
