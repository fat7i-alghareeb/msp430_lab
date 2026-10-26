import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utils/extensions/theme_extensions.dart';

/// Shared types and style resolution for [AppButton].
enum AppButtonFill { solid, gradient }

/// Shadow style used by [AppButtonStyleResolver].
///
/// Defaults to [AppButtonShadowVariant.grey] unless overridden.
enum AppButtonShadowVariant { primary, success, error, warning, grey }

/// Shape used by [AppButtonLayout] to compute border radius and sizing.
enum AppButtonShape { rounded, pill, circle }

/// Layout configuration for [AppButton].
///
/// Notes:
/// - If [height] is null, the button wraps content + padding.
/// - If [percentageHeight] is set, it overrides [height].
class AppButtonLayout {
  const AppButtonLayout({
    this.width,
    this.height,
    this.percentageWidth,
    this.percentageHeight,
    this.borderRadius,
    this.shape = AppButtonShape.rounded,
    this.contentPadding,
  });

  final double? width;
  final double? height;

  final double? percentageWidth;
  final double? percentageHeight;

  final double? borderRadius;
  final AppButtonShape shape;

  final EdgeInsetsGeometry? contentPadding;
}

abstract class AppButtonVariant {
  const AppButtonVariant();

  Color solidColor(BuildContext context);

  LinearGradient gradient(BuildContext context);

  Color foreground(BuildContext context);

  static const AppButtonVariant primary = _PrimaryButtonVariant();
  static const AppButtonVariant success = _SuccessButtonVariant();
  static const AppButtonVariant error = _ErrorButtonVariant();
  static const AppButtonVariant warning = _WarningButtonVariant();

  /// **The look of an INACTIVE button, and nothing else.**
  ///
  /// Grey says "you cannot press this right now": a form that is not valid
  /// yet, an action that is waiting for something. It is never a colour for a
  /// button that works. "Cancel", "Exit", "Reset" and "Close" are real,
  /// pressable actions, so they are `error` (red) or `primary`, not grey.
  ///
  /// Because of that a button cannot be BOTH grey and active:
  /// `AppButton.variant(variant: grey, isActive: true)` fails an assertion in
  /// debug builds, `AppButton.grey` is always inactive, and any button given
  /// `isActive: false` is drawn grey by itself, with no variant needed.
  static const AppButtonVariant grey = _GreyButtonVariant();
}

class AppButtonResolvedStyle {
  const AppButtonResolvedStyle({
    required this.fill,
    required this.color,
    required this.gradient,
    required this.foreground,
    required this.shadows,
  });

  final AppButtonFill fill;
  final Color? color;
  final LinearGradient? gradient;
  final Color foreground;
  final List<BoxShadow> shadows;
}

class AppButtonStyleResolver {
  AppButtonStyleResolver._();

  static AppButtonResolvedStyle resolve(
    BuildContext context, {
    required AppButtonVariant variant,
    required AppButtonFill fill,
    required bool isActive,
    required bool noShadow,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    // An inactive button IS the grey variant — that is the only thing grey
    // means (see [AppButtonVariant.grey]).
    final effectiveVariant = isActive ? variant : AppButtonVariant.grey;

    final color = fill == AppButtonFill.solid
        ? effectiveVariant.solidColor(context)
        : null;

    final gradient = fill == AppButtonFill.gradient
        ? effectiveVariant.gradient(context)
        : null;

    final foreground = effectiveVariant.foreground(context);

    final shadows = noShadow
        ? const <BoxShadow>[]
        : (customShadows ??
              _resolveShadows(
                context,
                shadowVariant ?? AppButtonShadowVariant.grey,
              ));

    return AppButtonResolvedStyle(
      fill: fill,
      color: color,
      gradient: gradient,
      foreground: foreground,
      shadows: shadows,
    );
  }

  static List<BoxShadow> _resolveShadows(
    BuildContext context,
    AppButtonShadowVariant variant,
  ) {
    return switch (variant) {
      AppButtonShadowVariant.primary => context.shadows.primary,
      AppButtonShadowVariant.success => context.shadows.success,
      AppButtonShadowVariant.error => context.shadows.error,
      AppButtonShadowVariant.warning => context.shadows.warning,
      AppButtonShadowVariant.grey => context.shadows.grey,
    };
  }
}

class _PrimaryButtonVariant extends AppButtonVariant {
  const _PrimaryButtonVariant();

  @override
  Color solidColor(BuildContext context) => context.colorScheme.primary;

  @override
  LinearGradient gradient(BuildContext context) => context.gradients.primary;

  @override
  Color foreground(BuildContext context) => context.colorScheme.onPrimary;
}

/// Text on a saturated plate: white on the light theme's deep colours, the
/// page's dark on the dark theme's pale ones. (The page colour itself is a
/// light grey now, which is not white enough for the deep greens and reds.)
Color _onSolid(BuildContext context) =>
    context.colorScheme.brightness == Brightness.dark
    ? context.background
    : AppColors.onPrimaryLight;

class _SuccessButtonVariant extends AppButtonVariant {
  const _SuccessButtonVariant();

  @override
  Color solidColor(BuildContext context) => context.semantic.success;

  @override
  LinearGradient gradient(BuildContext context) => context.gradients.success;

  @override
  Color foreground(BuildContext context) => _onSolid(context);
}

class _ErrorButtonVariant extends AppButtonVariant {
  const _ErrorButtonVariant();

  @override
  Color solidColor(BuildContext context) => context.colorScheme.error;

  @override
  LinearGradient gradient(BuildContext context) => context.gradients.error;

  @override
  Color foreground(BuildContext context) => _onSolid(context);
}

class _WarningButtonVariant extends AppButtonVariant {
  const _WarningButtonVariant();

  @override
  Color solidColor(BuildContext context) => context.semantic.warning;

  @override
  LinearGradient gradient(BuildContext context) => context.gradients.warning;

  @override
  Color foreground(BuildContext context) => _onSolid(context);
}

/// The inactive look: a flat, quiet plate with muted text (Material's 12%
/// content colour behind 38% content colour). Flat on purpose: a gradient
/// would make a button that does nothing look inviting.
class _GreyButtonVariant extends AppButtonVariant {
  const _GreyButtonVariant();

  @override
  Color solidColor(BuildContext context) =>
      context.colorScheme.surfaceContainerHighest;

  @override
  LinearGradient gradient(BuildContext context) {
    final plate = solidColor(context);
    return LinearGradient(colors: <Color>[plate, plate]);
  }

  @override
  Color foreground(BuildContext context) =>
      context.colorScheme.onSurface.withValues(alpha: 0.45);
}

class CustomButtonVariant extends AppButtonVariant {
  final Color? color;
  final LinearGradient? gradientColor;
  const CustomButtonVariant({this.color, this.gradientColor});

  @override
  Color solidColor(BuildContext context) =>
      color ?? AppButtonVariant.grey.solidColor(context);

  @override
  LinearGradient gradient(BuildContext context) =>
      gradientColor ?? AppButtonVariant.grey.gradient(context);

  @override
  Color foreground(BuildContext context) =>
      color == null && gradientColor == null
      ? AppButtonVariant.grey.foreground(context)
      : _onSolid(context);
}
