import 'package:flutter/material.dart';

import '../../utils/constants/design_constants.dart';
import '../platform/app_platform.dart';
import '../theme/app_typography.dart';
import 'app_layout.dart';
import 'app_layout_scope.dart';

/// How far the app follows the reader's system text size.
///
/// 85–130%: enough for most readers who raise it, and the capsule, the rail
/// and the cards still fit. `App` applies it with
/// `MediaQuery.withClampedTextScaling`.
abstract final class AppTextScale {
  static const double min = 0.85;
  static const double max = 1.3;

  /// A little more type as the window grows.
  ///
  /// A desktop window is read from an arm's length on a bigger screen than a
  /// phone is from a hand, and the same 14dp body text that suits the phone
  /// looks small in it. The boost is slight and in steps, by window size
  /// class: nothing below 840dp, then +5%, +10%, +15%. It multiplies the
  /// reader's own text size, so a reader who raised theirs still gets more.
  static double windowBoost(WindowSize size) => switch (size) {
    WindowSize.compact || WindowSize.medium => 1,
    WindowSize.expanded => 1.05,
    WindowSize.large => 1.1,
    WindowSize.extraLarge => 1.15,
  };
}

/// Applies the reader's text size (kept within [AppTextScale.min]..`max`) and
/// the window-size boost ([AppTextScale.windowBoost]) to everything below.
///
/// Where the boost is 1 the reader's own scaler is passed on untouched — an
/// Android 14 non-linear one included. Above it, a linear scale stands in:
/// desktop systems scale text linearly.
class AppTextScaleHost extends StatelessWidget {
  const AppTextScaleHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final clamped = media.textScaler.clamp(
      minScaleFactor: AppTextScale.min,
      maxScaleFactor: AppTextScale.max,
    );
    final boost = AppTextScale.windowBoost(
      WindowSize.fromWidth(media.size.width),
    );
    final scaler = boost == 1
        ? clamped
        : TextScaler.linear(clamped.scale(1) * boost);
    return MediaQuery(
      data: media.copyWith(textScaler: scaler),
      child: child,
    );
  }
}

/// Theme adjustments for expanded windows (840dp and wider):
///
/// - the headings one size larger (`AppTypography.expandedFrom`); body text
///   keeps its size;
/// - snackbars in the bottom END corner, about 360dp wide, instead of
///   stretched along the bottom of a desktop window.
///
/// The snackbar inset depends on the window width; it moves in 40dp steps,
/// so dragging a window edge rebuilds the theme a few times, not on every
/// pixel.
class AdaptiveTypography extends StatelessWidget {
  const AdaptiveTypography({super.key, required this.child});

  final Widget child;

  /// A snackbar's width in an expanded window, give or take one step.
  static const double snackBarWidth = 360;
  static const double _step = 40;

  @override
  Widget build(BuildContext context) {
    final expanded = AppLayoutScope.windowSizeOf(
      context,
    ).isAtLeast(WindowSize.expanded);
    // A mouse is precise: desktop controls take Material's compact density
    // (Flutter's input guide). Touch targets elsewhere keep their size.
    final desktop = AppPlatform.isDesktop;
    if (!expanded) {
      if (!desktop) return child;
      return Theme(
        data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
        child: child,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final width = (constraints.maxWidth / _step).floor() * _step;
        final start = (width - snackBarWidth - AppSpacing.xl).clamp(
          AppSpacing.xl,
          double.infinity,
        );
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return Theme(
          data: theme.copyWith(
            visualDensity: desktop ? VisualDensity.compact : null,
            textTheme: AppTypography.expandedFrom(theme.textTheme),
            snackBarTheme: theme.snackBarTheme.copyWith(
              insetPadding: EdgeInsets.fromLTRB(
                rtl ? AppSpacing.xl : start,
                0,
                rtl ? start : AppSpacing.xl,
                AppSpacing.xl,
              ),
            ),
          ),
          child: child,
        );
      },
    );
  }
}
