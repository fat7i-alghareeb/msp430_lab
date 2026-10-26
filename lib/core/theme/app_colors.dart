import 'package:flutter/material.dart';

/// The raw palette.
///
/// **This is the one file to change for a new brand.** Every value feeds
/// [AppColorSchemes] (`app_theme_colors.dart`) or [AppSemanticColors]; widgets
/// never read this class directly — colours reach the UI through
/// `Theme.of(context).colorScheme` or `context.semantic`.
///
/// The shipped values are a brand-neutral indigo/slate. Keep the measured
/// contrast pairs in `test/core/theme/app_theme_test.dart` passing when you
/// swap them.
class AppColors {
  AppColors._();

  // ───────────────────────────── Over a photograph

  /// Text over a picture behind a dark scrim. The same in both themes: the
  /// scrim is the ground, not the surface.
  static const Color onPhoto = Color(0xFFF7F8FA);

  /// Secondary text (a date) over the same scrim.
  static const Color onPhotoMuted = Color(0xFFCDD2DC);

  /// The scrim's full-strength end.
  static const Color photoScrim = Color(0xDB0E1016);

  // ───────────────────────────── Light scheme

  static const Color primaryLight = Color(0xFF3B5BDB);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFE3E8FB);
  static const Color onPrimaryContainerLight = Color(0xFF1E2F72);

  static const Color secondaryLight = Color(0xFF5C6B8A);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryContainerLight = Color(0xFFE1E6F0);
  static const Color onSecondaryContainerLight = Color(0xFF2A3347);

  /// A soft accent for fills and quiet badges. **Fill only** — it fails
  /// contrast as a text colour on white (asserted in `app_theme_test.dart`).
  static const Color tertiaryLight = Color(0xFFB7C4E6);
  static const Color onTertiaryLight = Color(0xFF1B2340);
  static const Color tertiaryContainerLight = Color(0xFFE6EBF7);
  static const Color onTertiaryContainerLight = Color(0xFF1B2340);

  /// Screen background — NOT the card colour ([surfaceLight]). A cool grey that
  /// reads as grey beside the white cards (it was #F5F6F8, which looked white).
  static const Color backGroundLight = Color(0xFFEDF0F5);

  /// Cards, bottom sheets, dialogs.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Thumbnails, inactive chips, disabled fields.
  static const Color surfaceVariantLight = Color(0xFFE3E8EF);

  /// Primary text.
  static const Color onSurfaceLight = Color(0xFF1B1F27);

  /// Secondary text, labels, timestamps.
  static const Color onSurfaceVariantLight = Color(0xFF5B6272);

  /// Dividers, card borders — hairlines that must be seen against both the
  /// background and a white card.
  static const Color outlineLight = Color(0xFFD0D6E1);

  /// Field borders, ghost-button borders, icons: 3:1 against white, the
  /// minimum for the edge of a control (WCAG 1.4.11).
  static const Color outlineVariantLight = Color(0xFF8893A8);

  // ───────────────────────────── Dark scheme
  //
  // Deliberately NOT an inversion of light: every value is chosen for a dark
  // ground and checked for contrast on its own.

  static const Color primaryDark = Color(0xFF9DB0FF);
  static const Color onPrimaryDark = Color(0xFF0F1A45);
  static const Color primaryContainerDark = Color(0xFF28366E);
  static const Color onPrimaryContainerDark = Color(0xFFDCE3FF);

  static const Color secondaryDark = Color(0xFFA3AFC8);
  static const Color onSecondaryDark = Color(0xFF1A2233);
  static const Color secondaryContainerDark = Color(0xFF2C3548);
  static const Color onSecondaryContainerDark = Color(0xFFDCE2EF);

  static const Color tertiaryDark = Color(0xFFB7C4E6);
  static const Color onTertiaryDark = Color(0xFF1B2340);
  static const Color tertiaryContainerDark = Color(0xFF2C3558);
  static const Color onTertiaryContainerDark = Color(0xFFE6EBF7);

  static const Color backGroundDark = Color(0xFF0F1115);
  static const Color surfaceDark = Color(0xFF171A21);
  static const Color surfaceVariantDark = Color(0xFF20242D);
  static const Color onSurfaceDark = Color(0xFFE8EAF0);
  static const Color onSurfaceVariantDark = Color(0xFFA0A7B6);
  static const Color outlineDark = Color(0xFF363C49);
  /// 3:1 against the dark card colour, like its light twin.
  static const Color outlineVariantDark = Color(0xFF636C7E);

  // ───────────────────────────── Semantic

  static const Color successLight = Color(0xFF2E7D4F);
  static const Color successDark = Color(0xFF7FD1A0);

  static const Color warningLight = Color(0xFFB45309);
  static const Color warningDark = Color(0xFFE7C15A);

  static const Color errorLight = Color(0xFFB3261E);
  static const Color errorDark = Color(0xFFF2B8B5);

  /// Things that must stand out from the brand colour: «urgent», «-20%».
  /// A badge in this colour always carries a word too — never signal by
  /// colour alone.
  static const Color urgentLight = Color(0xFFB4402A);
  static const Color urgentDark = Color(0xFFF0A48F);

  /// Text/icon color on top of [urgentLight] / [urgentDark].
  static const Color onUrgentLight = Color(0xFFFFFFFF);
  static const Color onUrgentDark = Color(0xFF3A1208);

  static const Color infoLight = Color(0xFF1F6FA3);
  static const Color infoDark = Color(0xFF8CC8EE);

  /// Behind bottom sheets and dialogs.
  static const Color scrim = Color(0x80101217);

  // ───────────────────────────── Fixed (theme-independent) shortcuts
  //
  // The LIGHT values, for the older common widgets that predate the theme
  // extension. New code reads `colorScheme` or [AppSemanticColors], which
  // follow dark mode.

  static const Color greyLight = outlineLight;
  static const Color greyDark = outlineDark;
  static const Color success = successLight;
  static const Color warning = warningLight;
  static const Color error = errorLight;
  static const Color info = infoLight;
}

/// Colors the Material [ColorScheme] has no slot for.
///
/// Registered as a [ThemeExtension] so they follow light/dark automatically
/// and are reachable with `context.semantic.urgent`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.background,
    required this.success,
    required this.warning,
    required this.urgent,
    required this.onUrgent,
    required this.info,
    this.onPhoto = AppColors.onPhoto,
    this.onPhotoMuted = AppColors.onPhotoMuted,
    this.photoScrim = AppColors.photoScrim,
  });

  /// Screen background. Separate from `colorScheme.surface`, which is the
  /// card/sheet color — they are different values on purpose.
  final Color background;
  final Color success;
  final Color warning;

  /// «عاجل» / «خصم».
  final Color urgent;
  final Color onUrgent;
  final Color info;

  /// Text over a photograph, behind [photoScrim]. Not theme-dependent: a
  /// picture is as dark in light mode as in dark.
  final Color onPhoto;
  final Color onPhotoMuted;
  final Color photoScrim;

  static const AppSemanticColors light = AppSemanticColors(
    background: AppColors.backGroundLight,
    success: AppColors.successLight,
    warning: AppColors.warningLight,
    urgent: AppColors.urgentLight,
    onUrgent: AppColors.onUrgentLight,
    info: AppColors.infoLight,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    background: AppColors.backGroundDark,
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    urgent: AppColors.urgentDark,
    onUrgent: AppColors.onUrgentDark,
    info: AppColors.infoDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? success,
    Color? warning,
    Color? urgent,
    Color? onUrgent,
    Color? info,
    Color? onPhoto,
    Color? onPhotoMuted,
    Color? photoScrim,
  }) {
    return AppSemanticColors(
      background: background ?? this.background,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      urgent: urgent ?? this.urgent,
      onUrgent: onUrgent ?? this.onUrgent,
      info: info ?? this.info,
      onPhoto: onPhoto ?? this.onPhoto,
      onPhotoMuted: onPhotoMuted ?? this.onPhotoMuted,
      photoScrim: photoScrim ?? this.photoScrim,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      background: Color.lerp(background, other.background, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      urgent: Color.lerp(urgent, other.urgent, t)!,
      onUrgent: Color.lerp(onUrgent, other.onUrgent, t)!,
      info: Color.lerp(info, other.info, t)!,
      onPhoto: Color.lerp(onPhoto, other.onPhoto, t)!,
      onPhotoMuted: Color.lerp(onPhotoMuted, other.onPhotoMuted, t)!,
      photoScrim: Color.lerp(photoScrim, other.photoScrim, t)!,
    );
  }
}
