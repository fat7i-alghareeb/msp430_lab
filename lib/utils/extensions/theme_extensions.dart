import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme_effects.dart';

/// Theme-related convenience extensions on [BuildContext].
///
/// These helpers make accessing [ThemeData], [ColorScheme] and
/// [TextTheme] more concise and expressive across the app.
extension AppThemeContextX on BuildContext {
  /// Returns the current [ThemeData] for this [BuildContext].
  ThemeData get theme => Theme.of(this);

  /// Returns the current [ColorScheme] from [ThemeData].
  ColorScheme get colorScheme => theme.colorScheme;

  /// Returns the current [TextTheme] from [ThemeData].
  TextTheme get textTheme => theme.textTheme;

  /// Whether the current theme brightness is dark.
  bool get isDarkTheme => theme.brightness == Brightness.dark;

  AppThemeGradients get gradients => AppThemeEffects.gradients(theme);

  AppThemeShadows get shadows => AppThemeEffects.shadows(theme);

  /// Colours the Material scheme has no slot for — success, warning,
  /// urgent, info, the screen background, text over photos.
  AppSemanticColors get semantic =>
      theme.extension<AppSemanticColors>() ??
      (isDarkTheme ? AppSemanticColors.dark : AppSemanticColors.light);

  /// Primary color from the current [ColorScheme].
  Color get primary => colorScheme.primary;

  /// Color used for content on top of [primary].
  Color get onPrimary => colorScheme.onPrimary;

  /// Secondary color from the current [ColorScheme].
  Color get secondary => colorScheme.secondary;

  /// Color used for content on top of [secondary].
  Color get onSecondary => colorScheme.onSecondary;

  /// Tertiary color from the current [ColorScheme].
  Color get tertiary => colorScheme.tertiary;

  /// Color used for content on top of [tertiary].
  Color get onTertiary => colorScheme.onTertiary;

  /// Background color for large surfaces.
  Color get background => colorScheme.surface;

  /// Color used for content on top of [background].
  Color get onBackground => colorScheme.onSurface;

  /// Default surface color for components.
  Color get surface => colorScheme.surface;

  /// Color used for content on top of [surface].
  Color get onSurface => colorScheme.onSurface;

  /// The grey of a control's edge and of its quiet icons: `outlineVariant`,
  /// 3:1 against a card. It is NOT a text colour — secondary text is
  /// [ColorScheme.onSurfaceVariant] — and not a button fill.
  Color get grey => colorScheme.outlineVariant;

  /// Error color from the current [ColorScheme].
  Color get error => colorScheme.error;

  /// Color used for content on top of [error].
  Color get onError => colorScheme.onError;
}

/// Extensions for accessing text styles directly from [BuildContext].
///
/// These helpers mirror the fields of [TextTheme] but remove the
/// `textTheme` prefix for more concise usage.
extension AppTextStylesContextX on BuildContext {
  /// Large display style used for prominent headings.
  TextStyle get displayLarge => Theme.of(this).textTheme.displayLarge!;

  /// Medium display style used for secondary prominent headings.
  TextStyle get displayMedium => Theme.of(this).textTheme.displayMedium!;

  /// Small display style used for tertiary prominent headings.
  TextStyle get displaySmall => Theme.of(this).textTheme.displaySmall!;

  /// Large headline style used for section headers.
  TextStyle get headlineLarge => Theme.of(this).textTheme.headlineLarge!;

  /// Medium headline style used for section headers.
  TextStyle get headlineMedium => Theme.of(this).textTheme.headlineMedium!;

  /// Small headline style used for section headers.
  TextStyle get headlineSmall => Theme.of(this).textTheme.headlineSmall!;

  /// Large title style used for app bars and list titles.
  TextStyle get titleLarge => Theme.of(this).textTheme.titleLarge!;

  /// Medium title style used for inline titles.
  TextStyle get titleMedium => Theme.of(this).textTheme.titleMedium!;

  /// Small title style used for dense headers.
  TextStyle get titleSmall => Theme.of(this).textTheme.titleSmall!;

  /// Large body style used for main content text.
  TextStyle get bodyLarge => Theme.of(this).textTheme.bodyLarge!;

  /// Medium body style used for standard content text.
  TextStyle get bodyMedium => Theme.of(this).textTheme.bodyMedium!;

  /// Small body style used for supporting text.
  TextStyle get bodySmall => Theme.of(this).textTheme.bodySmall!;

  /// Large label style used for buttons and chips.
  TextStyle get labelLarge => Theme.of(this).textTheme.labelLarge!;

  /// Medium label style used for smaller labels.
  TextStyle get labelMedium => Theme.of(this).textTheme.labelMedium!;

  /// Small label style used for captions and helper text.
  TextStyle get labelSmall => Theme.of(this).textTheme.labelSmall!;
}
