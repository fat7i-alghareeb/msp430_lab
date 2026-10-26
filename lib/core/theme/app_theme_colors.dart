import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Explicit light and dark [ColorScheme]s.
///
/// Every slot is written out from [AppColors]. Nothing is generated with
/// `ColorScheme.fromSeed`: a generated tint drifts away from the brand and
/// breaks the measured contrast ratios asserted in
/// `test/core/theme/app_theme_test.dart`.
///
/// Note the split the Material scheme has no name for:
/// `surface` is the card/sheet/dialog colour while the SCREEN background is
/// [AppColors.backGroundLight]. The screen color lives in `ThemeData.scaffoldBackgroundColor`
/// and in `AppSemanticColors.background`.
class AppColorSchemes {
  AppColorSchemes._();

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,

    primary: AppColors.primaryLight,
    onPrimary: AppColors.onPrimaryLight,
    primaryContainer: AppColors.primaryContainerLight,
    onPrimaryContainer: AppColors.onPrimaryContainerLight,

    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.onSecondaryLight,
    secondaryContainer: AppColors.secondaryContainerLight,
    onSecondaryContainer: AppColors.onSecondaryContainerLight,

    tertiary: AppColors.tertiaryLight,
    onTertiary: AppColors.onTertiaryLight,
    tertiaryContainer: AppColors.tertiaryContainerLight,
    onTertiaryContainer: AppColors.onTertiaryContainerLight,

    error: AppColors.errorLight,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),

    surface: AppColors.surfaceLight,
    onSurface: AppColors.onSurfaceLight,
    onSurfaceVariant: AppColors.onSurfaceVariantLight,

    // Material's surface ladder, mapped onto the greys we own.
    surfaceDim: Color(0xFFDCE1E9),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF6F8FB),
    surfaceContainer: AppColors.backGroundLight,
    surfaceContainerHigh: Color(0xFFE8ECF2),
    surfaceContainerHighest: AppColors.surfaceVariantLight,

    outline: AppColors.outlineLight,
    outlineVariant: AppColors.outlineVariantLight,

    shadow: Color(0xFF1B1F27),
    scrim: AppColors.scrim,

    inverseSurface: Color(0xFF2B303A),
    onInverseSurface: Color(0xFFF1F3F7),
    inversePrimary: AppColors.primaryDark,
    surfaceTint: Color(0x00000000),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,

    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,

    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: AppColors.onSecondaryContainerDark,

    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    tertiaryContainer: AppColors.tertiaryContainerDark,
    onTertiaryContainer: AppColors.onTertiaryContainerDark,

    error: AppColors.errorDark,
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),

    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,

    surfaceDim: AppColors.backGroundDark,
    surfaceBright: Color(0xFF30343E),
    surfaceContainerLowest: Color(0xFF0A0C10),
    surfaceContainerLow: Color(0xFF13161C),
    surfaceContainer: AppColors.surfaceDark,
    surfaceContainerHigh: Color(0xFF1C2028),
    surfaceContainerHighest: AppColors.surfaceVariantDark,

    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,

    shadow: Color(0xFF000000),
    scrim: AppColors.scrim,

    inverseSurface: Color(0xFFE8EAF0),
    onInverseSurface: Color(0xFF171A21),
    inversePrimary: AppColors.primaryLight,
    surfaceTint: Color(0x00000000),
  );
}
