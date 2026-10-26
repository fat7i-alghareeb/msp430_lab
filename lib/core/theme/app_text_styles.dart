import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Named text styles that resolve against [AppTypography.textTheme].
///
/// Prefer `context.textTheme.titleMedium` in widgets. These aliases exist for
/// the pre-existing common widgets that were written before the scale in
/// `DESIGN_SYSTEM.md` was settled, and for the rare non-widget call site.
///
/// The names encode the ORIGINAL size/weight pairs of the starter template and
/// are kept so nothing breaks, but each getter now returns the style that
/// `DESIGN_SYSTEM.md` actually prescribes for that role. Where the two
/// disagree — the spec bans weights 300 and 600 — the spec wins and the
/// mismatch is called out on the getter.
class AppTextStyles {
  AppTextStyles._();

  /// Rebuilds [base] with [weight], dropping any color so the style inherits
  /// the active theme's color.
  ///
  /// `TextStyle.copyWith(color: null)` does NOT clear a color; it keeps the
  /// original. The style has to be rebuilt field by field.
  static TextStyle _withWeight(TextStyle? base, FontWeight weight) {
    final b = base ?? const TextStyle();
    return TextStyle(
      fontFamily: b.fontFamily,
      fontFamilyFallback: b.fontFamilyFallback,
      fontSize: b.fontSize,
      fontWeight: weight,
      fontStyle: b.fontStyle,
      letterSpacing: b.letterSpacing,
      wordSpacing: b.wordSpacing,
      textBaseline: b.textBaseline,
      height: b.height,
      leadingDistribution: b.leadingDistribution,
      locale: b.locale,
      // Intentionally omit: color, backgroundColor, foreground, background.
      decoration: b.decoration,
      decorationColor: b.decorationColor,
      decorationStyle: b.decorationStyle,
      decorationThickness: b.decorationThickness,
      debugLabel: b.debugLabel,
      shadows: b.shadows,
      fontFeatures: b.fontFeatures,
      overflow: b.overflow,
    );
  }

  static TextTheme get _t =>
      AppTypography.textTheme ?? AppTypography.buildTextTheme;

  /// Adds tabular figures — prices, ratings, counters.
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: AppTypography.tabularFigures);

  // ───────────────────────────── Display

  static TextStyle get s40w700 => _withWeight(_t.displayLarge, FontWeight.w800);

  static TextStyle get s34w700 =>
      _withWeight(_t.displayMedium, FontWeight.w800);

  static TextStyle get s28w700 => _withWeight(_t.displaySmall, FontWeight.w800);

  // ───────────────────────────── Headline

  static TextStyle get s24w700 =>
      _withWeight(_t.headlineLarge, FontWeight.w800);

  static TextStyle get s22w700 =>
      _withWeight(_t.headlineMedium, FontWeight.w800);

  static TextStyle get s20w700 =>
      _withWeight(_t.headlineSmall, FontWeight.w800);

  // ───────────────────────────── Title
  //
  // Weight 600 is banned by `DESIGN_SYSTEM.md`; these return 700.

  /// Screen title. **Returns w700** — the spec allows no w600.
  static TextStyle get s18w600 => _withWeight(_t.titleLarge, FontWeight.w700);

  /// Section title, store name. **Returns w700.**
  static TextStyle get s16w600 => _withWeight(_t.titleMedium, FontWeight.w700);

  /// Card title, price. **Returns w700.**
  static TextStyle get s14w600 => _withWeight(_t.titleSmall, FontWeight.w700);

  // ───────────────────────────── Body

  static TextStyle get s16w400 => _withWeight(_t.bodyLarge, FontWeight.w400);

  static TextStyle get s14w400 => _withWeight(_t.bodyMedium, FontWeight.w400);

  static TextStyle get s12w400 => _withWeight(_t.bodySmall, FontWeight.w400);

  // ───────────────────────────── Label

  /// Button text. **Returns w700** per `DESIGN_SYSTEM.md`.
  static TextStyle get s14w500 => _withWeight(_t.labelLarge, FontWeight.w700);

  /// Chips, field labels.
  static TextStyle get s12w500 => _withWeight(_t.labelMedium, FontWeight.w500);

  /// Badges. **Returns w700** per `DESIGN_SYSTEM.md`.
  static TextStyle get s11w500 => _withWeight(_t.labelSmall, FontWeight.w700);
}
