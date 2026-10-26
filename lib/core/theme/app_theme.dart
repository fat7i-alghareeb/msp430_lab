import 'package:flutter/material.dart';

import '../../utils/constants/design_constants.dart';
import 'app_colors.dart';
import 'app_page_transitions.dart';
import 'app_theme_colors.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData].
///
/// Every component default here traces back to `DESIGN_SYSTEM.md`. The goal
/// is that a widget never has to pass a color, a radius or a text style: the
/// theme already carries the right one.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(
    colorScheme: AppColorSchemes.light,
    semantic: AppSemanticColors.light,
  );

  static ThemeData get dark => _buildTheme(
    colorScheme: AppColorSchemes.dark,
    semantic: AppSemanticColors.dark,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required AppSemanticColors semantic,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final textTheme = AppTypography.buildTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
    );

    return base.copyWith(
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semantic],

      // The screen ground is NOT `surface` — see AppColorSchemes.
      scaffoldBackgroundColor: semantic.background,
      canvasColor: semantic.background,
      dividerColor: colorScheme.outline,

      // The elevation tint would drift the brand colour; the system wants one
      // explicit shadow instead.
      applyElevationOverlayColor: false,

      highlightColor: colorScheme.primary.withValues(alpha: AppStates.cardInk),
      splashColor: colorScheme.primary.withValues(alpha: AppStates.cardInk),

      // ─────────────────────── App bar
      appBarTheme: AppBarTheme(
        backgroundColor: semantic.background,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: AppIconSizes.bar,
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: AppIconSizes.bar,
        ),
      ),

      // ─────────────────────── Cards
      //
      // No border — the separation is the shadow. The shadow is drawn by the
      // widget through `context.shadows.card`, so Material elevation stays 0.
      // In dark mode a hairline border replaces it.
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: isDark
              ? BorderSide(color: colorScheme.outline)
              : BorderSide.none,
        ),
      ),

      // ─────────────────────── Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        // Helper text is permanent, not a hint that vanishes on focus.
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        helperMaxLines: 2,
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          // A soft primary ring on focus.
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppBorders.emphasis,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppBorders.emphasis,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide.none,
        ),
      ),

      // ─────────────────────── Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(
            alpha: AppStates.disabled,
          ),
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 40),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          minimumSize: const Size(
            AppIconSizes.minTouchTarget,
            AppIconSizes.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),

      // ─────────────────────── Chips
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: AppStates.disabled,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        side: BorderSide.none,
        showCheckmark: false,
        shape: const StadiumBorder(),
      ),

      // ─────────────────────── Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        dragHandleSize: const Size(34, 4),
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),

      // ─────────────────────── Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
        ),
      ),

      // ─────────────────────── SnackBar
      // A dark floating pill above the bottom bar, «Undo» in the primary
      // container colour.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.surface,
        ),
        actionTextColor: colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        shape: const StadiumBorder(),
      ),

      // ─────────────────────── Misc
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: AppBorders.hairline,
        space: AppBorders.hairline,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppIconSizes.list,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.md,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        titleTextStyle: textTheme.bodyMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        iconColor: colorScheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outlineVariant;
        }),
      ),
      // Android: the platform's predictive back — the back gesture previews
      // the page underneath and can be cancelled (Android 14+, on by default
      // in 16). A custom builder here switches that preview off, which is
      // why back had none.
      //
      // Elsewhere, forward navigation slides in from the end edge and back
      // reverses it; the direction follows the ambient text direction.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
        },
      ),
    );
  }
}
