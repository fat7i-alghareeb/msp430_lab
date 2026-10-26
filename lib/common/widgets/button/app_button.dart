import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../../core/injection/injectable.dart';
import '../../../core/services/haptics/haptics_service.dart';
import '../../../utils/constants/design_constants.dart';
import '../../../utils/extensions/context_extensions.dart';

import 'app_button_child.dart';
import '../loading_dots.dart';
import 'app_button_variants.dart';

/// A pressable, animated button.
///
/// **Grey means inactive, and only that.** [AppButtonVariant.grey] is the look
/// of a button that cannot be pressed right now. It is never the colour of a
/// button that works, so a button cannot be grey AND active:
///
/// - "Cancel", "Exit", "Close" and "Reset" are real actions: use
///   [AppButton.error] (or [AppButton.primary]), never grey.
/// - To show a button as unavailable, keep its real variant and pass
///   `isActive: false`. It is drawn grey by itself and ignores taps; use
///   `onTapWhenInactive` to say why ("Fill in the form first").
/// - [AppButton.grey] is for a button that is ALWAYS inactive, and
///   `AppButton.variant(variant: AppButtonVariant.grey, isActive: true)`
///   fails an assertion in debug builds.
///
/// Features:
/// - Styling via [AppButtonVariant] + [AppButtonFill]
/// - Loading state (shows [LoadingDots])
/// - Optional layout control via [AppButtonLayout]
/// - Optional shadow override via [AppButtonShadowVariant]
class AppButton extends StatefulWidget {
  const AppButton._({
    super.key,
    required this.child,
    required this.onTap,
    this.onTapWhenInactive,
    required this.variant,
    required this.fill,
    this.layout = const AppButtonLayout(),
    this.isActive = true,
    this.isLoading = false,
    this.noShadow = false,
    this.shadowVariant,
    this.customShadows,
  });

  /// Create an [AppButton] with an explicit [variant] + [fill].
  factory AppButton.variant({
    Key? key,
    required AppButtonVariant variant,
    required AppButtonFill fill,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    assert(
      !identical(variant, AppButtonVariant.grey) || !isActive,
      'AppButtonVariant.grey is only the look of an INACTIVE button. For '
      '"Cancel", "Exit" or "Reset" use AppButton.error (or primary); to show '
      'a button as unavailable, keep its variant and pass isActive: false.',
    );
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: variant,
      fill: fill,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  /// Convenience factory for a primary solid button.
  factory AppButton.primary({
    Key? key,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: AppButtonVariant.primary,
      fill: AppButtonFill.solid,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  /// A button that is ALWAYS inactive: grey, and deaf to taps.
  ///
  /// Grey is only ever the look of "not available" (see the class doc), so
  /// there is no `onTap` and no `isActive` here. For a button that is
  /// sometimes unavailable, use its real variant with `isActive: false`.
  factory AppButton.grey({
    Key? key,
    required AppButtonChild child,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton.variant(
      key: key,
      variant: AppButtonVariant.grey,
      fill: AppButtonFill.solid,
      child: child,
      onTap: null,
      onTapWhenInactive: onTapWhenInactive,
      layout: layout,
      isActive: false,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  /// [AppButton.grey] with the gradient fill, which the inactive look keeps
  /// flat. Always inactive.
  factory AppButton.greyGradient({
    Key? key,
    required AppButtonChild child,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton.variant(
      key: key,
      variant: AppButtonVariant.grey,
      fill: AppButtonFill.gradient,
      child: child,
      onTap: null,
      onTapWhenInactive: onTapWhenInactive,
      layout: layout,
      isActive: false,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  factory AppButton.primaryGradient({
    Key? key,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: AppButtonVariant.primary,
      fill: AppButtonFill.gradient,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  factory AppButton.success({
    Key? key,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: AppButtonVariant.success,
      fill: AppButtonFill.solid,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  factory AppButton.successGradient({
    Key? key,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: AppButtonVariant.success,
      fill: AppButtonFill.gradient,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  factory AppButton.error({
    Key? key,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: AppButtonVariant.error,
      fill: AppButtonFill.solid,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  factory AppButton.errorGradient({
    Key? key,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: AppButtonVariant.error,
      fill: AppButtonFill.gradient,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  factory AppButton.warning({
    Key? key,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: AppButtonVariant.warning,
      fill: AppButtonFill.solid,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  factory AppButton.warningGradient({
    Key? key,
    required AppButtonChild child,
    required VoidCallback? onTap,
    VoidCallback? onTapWhenInactive,
    AppButtonLayout layout = const AppButtonLayout(),
    bool isActive = true,
    bool isLoading = false,
    bool noShadow = false,
    AppButtonShadowVariant? shadowVariant,
    List<BoxShadow>? customShadows,
  }) {
    return AppButton._(
      key: key,
      child: child,
      onTap: onTap,
      onTapWhenInactive: onTapWhenInactive,
      variant: AppButtonVariant.warning,
      fill: AppButtonFill.gradient,
      layout: layout,
      isActive: isActive,
      isLoading: isLoading,
      noShadow: noShadow,
      shadowVariant: shadowVariant,
      customShadows: customShadows,
    );
  }

  final AppButtonChild child;
  final VoidCallback? onTap;
  final VoidCallback? onTapWhenInactive;
  final AppButtonVariant variant;
  final AppButtonFill fill;
  final AppButtonLayout layout;
  final bool isActive;
  final bool isLoading;
  final bool noShadow;
  final AppButtonShadowVariant? shadowVariant;
  final List<BoxShadow>? customShadows;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  bool _pressed = false;

  /// True when the button can receive interactions.
  ///
  /// We treat loading as a disabled state to avoid double submits.
  bool get _isEnabled =>
      widget.onTap != null && widget.isActive && !widget.isLoading;

  bool get _canTapWhenInactive =>
      widget.onTapWhenInactive != null && !widget.isActive && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: AppDurations.veryFast,
      reverseDuration: AppDurations.veryFast,
    );

    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    if (widget.isLoading) {
      _setPressed(true);
    }
  }

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _setPressed(true);
      } else {
        _setPressed(false);
      }
    }

    if (!widget.isLoading && !(_isEnabled || _canTapWhenInactive)) {
      _setPressed(false);
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    _pressed = value;

    if (_pressed) {
      _pressController.forward();
    } else {
      _pressController.reverse();
    }
  }

  /// Through [HapticsService]: a buzz on phones, nothing on desktop. A test
  /// with no DI gets the platform's own choice.
  static HapticsService get _haptics => getIt.isRegistered<HapticsService>()
      ? getIt<HapticsService>()
      : _fallbackHaptics;
  static final HapticsService _fallbackHaptics = HapticsService.forPlatform();

  void _vibratePress() => _haptics.press();

  void _vibrateTap() => _haptics.tap();

  //  simulate press when onTapDown is skipped
  Future<void> _simulateQuickTapPress() async {
    if (_pressed || !(_isEnabled || _canTapWhenInactive)) return;

    _setPressed(true);
    await Future.delayed(AppDurations.veryFast);
    if (mounted && !widget.isLoading) {
      _setPressed(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Resolve colors/gradients/shadows based on variant + fill + active state.
    ///
    /// A button that cannot be pressed is drawn grey, automatically: because it
    /// was told `isActive: false`, or because it has no `onTap` (and is not
    /// busy loading, which keeps its own colour). Nobody has to ask for grey.
    final style = AppButtonStyleResolver.resolve(
      context,
      variant: widget.variant,
      fill: widget.fill,
      isActive: widget.isActive && (widget.onTap != null || widget.isLoading),
      noShadow: widget.noShadow,
      shadowVariant: widget.shadowVariant,
      customShadows: widget.customShadows,
    );

    /// Optional fixed width. When null, the button wraps to content width.
    final width = widget.layout.percentageWidth != null
        ? context.screenWidth * widget.layout.percentageWidth!
        : widget.layout.width;

    final isCircle = widget.layout.shape == AppButtonShape.circle;

    /// Sizing rules:
    /// - If [layout.percentageHeight] is set → fixed height relative to screen.
    /// - Else if [layout.height] is set → fixed height.
    /// - Else → shrink-wrap to child + padding (subject to parent constraints).
    final double? height = widget.layout.percentageHeight != null
        ? context.screenHeight * widget.layout.percentageHeight!
        : widget.layout.height;

    /// Circle buttons always render square. If no explicit height is provided,
    /// we fall back to a sensible minimum size.
    final circleSize = height ?? 48.0;

    final borderRadiusValue = switch (widget.layout.shape) {
      AppButtonShape.circle => circleSize / 2,
      AppButtonShape.pill => 999.0,
      // DESIGN_SYSTEM.md: buttons use radius.md (14), not the icon radius.
      AppButtonShape.rounded => widget.layout.borderRadius ?? AppRadii.md,
    };

    final borderRadius = BorderRadius.circular(borderRadiusValue);

    final padding =
        widget.layout.contentPadding ?? widget.child.defaultPadding(context);

    /// Swap content with a lightweight loading indicator.
    final content = widget.isLoading
        ? LoadingDots(color: style.foreground)
        : widget.child.build(context, foreground: style.foreground);

    /// We use low-level gesture callbacks to drive the press animation and
    /// haptic feedback.
    final canHandleTap = _isEnabled || _canTapWhenInactive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: canHandleTap
          ? (_) {
              _setPressed(true);
              _vibratePress();
            }
          : null,
      onTapCancel: canHandleTap
          ? () {
              if (!widget.isLoading) _setPressed(false);
            }
          : null,
      onTapUp: canHandleTap
          ? (_) {
              if (!widget.isLoading) _setPressed(false);
            }
          : null,
      onTap: canHandleTap
          ? () {
              if (_isEnabled) {
                //ensures animation even for ultra-fast taps
                unawaited(_simulateQuickTapPress());
                _vibrateTap();
                widget.onTap?.call();
                return;
              }

              if (_canTapWhenInactive) {
                unawaited(_simulateQuickTapPress());
                _vibrateTap();
                widget.onTapWhenInactive?.call();
              }
            }
          : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: AppCurves.theme,
          width: isCircle ? circleSize : width,
          height: isCircle ? circleSize : height,
          padding: padding,
          decoration: BoxDecoration(
            color: style.color,
            gradient: style.gradient,
            borderRadius: borderRadius,
            boxShadow: style.shadows,
          ),
          // Align (instead of Center) keeps the widget shrink-wrappable.
          child: Align(widthFactor: 1, heightFactor: 1, child: content),
        ),
      ),
    );
  }
}
