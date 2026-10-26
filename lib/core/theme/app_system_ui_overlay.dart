import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilities for building a [SystemUiOverlayStyle] that matches the
/// active [ThemeData] of the application.
///
/// This allows the system status bar and navigation bar colors and icon
/// brightness to adapt automatically when the app theme changes.
class AppSystemUiOverlay {
  AppSystemUiOverlay._();

  /// Builds a [SystemUiOverlayStyle] for the given [theme].
  ///
  /// - Uses [ThemeData.scaffoldBackgroundColor] as the base color. That is
  ///   the SCREEN ground (`#F4F3EE` in light), which is not the same as
  ///   [ColorScheme.surface] (`#FFFFFF`, the card color) — see
  ///   `DESIGN_SYSTEM.md`. Matching `surface` would leave a visible seam
  ///   between the system navigation bar and the screen.
  /// - Chooses icon brightness based on the estimated brightness of the
  ///   surface color to ensure good contrast.
  static SystemUiOverlayStyle forTheme(ThemeData theme) {
    final surface = theme.scaffoldBackgroundColor;

    // Estimate how light or dark the surface color is so we can pick
    // icon colors that remain legible.
    final surfaceBrightness = ThemeData.estimateBrightnessForColor(surface);

    // On Android, [statusBarIconBrightness] and
    // [systemNavigationBarIconBrightness] control the icon color. We want
    // icons to be the opposite of the background brightness.
    final iconBrightness = surfaceBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return SystemUiOverlayStyle(
      // Background color for the status bar (Android). On iOS this is
      // combined with [statusBarBrightness].
      statusBarColor: Colors.transparent,
      statusBarBrightness: surfaceBrightness,
      statusBarIconBrightness: iconBrightness,
      systemStatusBarContrastEnforced: false,
      // Transparent: the app draws edge to edge behind both system bars.
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
