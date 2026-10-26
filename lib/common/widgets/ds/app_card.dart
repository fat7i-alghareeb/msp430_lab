import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import '../../../utils/extensions/theme_extensions.dart';
import 'app_context_menu.dart';
import 'app_focus_ring.dart';

/// The card of the system — `DESIGN_SYSTEM.md`.
///
/// `surface` + [AppRadii.lg] + the one card shadow, and **no border**: the
/// separation is the shadow, and the system forbids a shadow and a border on
/// the same element. In dark mode the shadow is invisible, so a hairline
/// `outline` border takes its place — again, never both.
///
/// The **whole** card is tappable, not just its title. Pressing scales it to
/// 0.985 over 90ms and washes it with `primary @ 6%`.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.radius = AppRadii.lg,
    this.color,
    this.clipBehavior,
    this.semanticLabel,
    this.menuActions = const <AppMenuAction>[],
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Defaults to 12dp all round. Pass [EdgeInsets.zero] when the child owns
  /// its own padding — an edge-to-edge cover image, for instance.
  final EdgeInsetsGeometry? padding;

  final double radius;
  final Color? color;

  /// Null: clip only when the child runs to the card's edge ([padding] is
  /// zero — an edge-to-edge picture). A padded child never reaches the
  /// rounded corners, and a clip there is raster work on every frame for
  /// nothing.
  final Clip? clipBehavior;

  /// Collapses the card into ONE node for screen readers. Pass the sentence a
  /// reader should hear; inner text is then excluded.
  final String? semanticLabel;

  /// A context menu: right click with a mouse, long press on touch.
  final List<AppMenuAction> menuActions;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _menuAtCentre() {
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    AppContextMenu.show(
      context,
      globalPosition: box.localToGlobal(box.size.center(Offset.zero)),
      actions: widget.menuActions,
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDarkTheme;
    final borderRadius = BorderRadius.circular(widget.radius);
    final padding = widget.padding ?? AppSpacing.cardPadding;
    final clip =
        widget.clipBehavior ??
        (padding == EdgeInsets.zero || padding == EdgeInsetsDirectional.zero
            ? Clip.antiAlias
            : Clip.none);

    Widget content = widget.onTap == null
        ? Padding(padding: padding, child: widget.child)
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              onSecondaryTapUp: widget.menuActions.isEmpty
                  ? null
                  : (details) => AppContextMenu.show(
                      context,
                      globalPosition: details.globalPosition,
                      actions: widget.menuActions,
                    ),
              onLongPress: widget.menuActions.isEmpty ? null : _menuAtCentre,
              // A pointer resting on the card: a 3% tint (AppStates).
              hoverColor: colors.onSurface.withValues(
                alpha: AppStates.hoverOverlay,
              ),
              borderRadius: borderRadius,
              splashColor: colors.primary.withValues(alpha: AppStates.cardInk),
              highlightColor: colors.primary.withValues(
                alpha: AppStates.cardInk / 2,
              ),
              child: Padding(padding: padding, child: widget.child),
            ),
          );
    if (clip != Clip.none) {
      // A rounded-rect clip: `Container.clipBehavior` clips with the
      // decoration's PATH, the slowest clip there is.
      content = ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clip,
        child: content,
      );
    }

    Widget card = AnimatedContainer(
      duration: AppDurations.press,
      curve: AppCurves.press,
      decoration: BoxDecoration(
        color: widget.color ?? colors.surface,
        borderRadius: borderRadius,
        // Shadow in light, hairline border in dark — never both.
        // Pressed, the card lifts its shadow as it sinks.
        boxShadow: _pressed && !isDark
            ? context.shadows.sheet
            : context.shadows.card,
        border: isDark ? Border.all(color: colors.outline) : null,
      ),
      child: content,
    );

    if (widget.onTap != null) {
      card = AnimatedScale(
        scale: _pressed ? AppStates.pressedScaleCard : 1,
        // Down fast, back with a spring.
        duration: _pressed
            ? AppDurations.press
            : const Duration(milliseconds: 280),
        curve: _pressed ? AppCurves.press : AppCurves.spring,
        child: card,
      );
    }

    if (widget.semanticLabel != null) {
      card = Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        excludeSemantics: true,
        child: card,
      );
    }

    if (widget.onTap == null) return card;
    return AppFocusRing(borderRadius: borderRadius, child: card);
  }
}

/// The card press for things that are not an [AppCard] — an
/// image-first product card, a coupon: sinks to [AppStates.pressedScaleCard]
/// and springs back, with an ink ripple clipped to [radius].
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.radius = AppRadii.lg,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final String? semanticLabel;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final radius = BorderRadius.circular(widget.radius);
    Widget child = widget.child;
    if (widget.onTap != null) {
      child = AnimatedScale(
        scale: _pressed ? AppStates.pressedScaleCard : 1,
        duration: _pressed
            ? AppDurations.press
            : const Duration(milliseconds: 280),
        curve: _pressed ? AppCurves.press : AppCurves.spring,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) {
              if (v != _pressed) setState(() => _pressed = v);
            },
            borderRadius: radius,
            splashColor: colors.primary.withValues(alpha: AppStates.cardInk),
            highlightColor: colors.primary.withValues(
              alpha: AppStates.cardInk / 2,
            ),
            child: child,
          ),
        ),
      );
    }
    if (widget.semanticLabel != null) {
      child = Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        excludeSemantics: true,
        child: child,
      );
    }
    return child;
  }
}
