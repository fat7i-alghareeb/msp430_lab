import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../../../utils/constants/design_constants.dart';

/// The floating capsule a detail page's actions sit in — instead of a
/// full-width bottom bar with a hairline over it.
///
/// ```text
///   ╭──────────────────────────────────╮
///   │  🔖 Save   ⚑ Report   [ Share ]   │   floats 12dp over the page
///   ╰──────────────────────────────────╯
/// ```
///
/// Put it in a [Stack] over the page — `Positioned(left: 0, right: 0,
/// bottom: 0, child: …)` — and give the page's last row [clearanceOf] of
/// room. With a [controller] it tucks away while the page
/// scrolls down and comes back as soon as it scrolls up, or reaches either
/// end — the same rule the floating navigation bar follows.
class AppActionCapsule extends StatefulWidget {
  const AppActionCapsule({
    super.key,
    required this.child,
    this.controller,
    this.maxWidth = double.infinity,
  });

  final Widget child;
  final ScrollController? controller;

  /// The widest the capsule gets (the page's column); it centres beyond that.
  final double maxWidth;

  /// The capsule's own height.
  static const double height = 60;

  /// The gap around it.
  static const double margin = AppSpacing.md;

  /// How much room the page leaves under its last row for the capsule.
  static double clearanceOf(BuildContext context) =>
      height + margin * 2 + MediaQuery.viewPaddingOf(context).bottom;

  /// Scrolled down this far in one go, it tucks away; up this far, it
  /// comes back.
  static const double hideAfter = 24;
  static const double showAfter = 64;

  @override
  State<AppActionCapsule> createState() => _AppActionCapsuleState();
}

class _AppActionCapsuleState extends State<AppActionCapsule> {
  bool _hidden = false;
  double _run = 0;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AppActionCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?.removeListener(_onScroll);
    widget.controller?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.controller;
    if (controller == null || !controller.hasClients) return;
    final position = controller.position;
    final offset = position.pixels;
    final delta = offset - _last;
    _last = offset;

    // At either end the actions are always there.
    if (offset <= 0 || offset >= position.maxScrollExtent) {
      _set(false);
      return;
    }
    if (position.userScrollDirection == ScrollDirection.idle) return;

    // Runs in one direction; turning round starts a new one.
    if ((delta > 0) != (_run > 0)) _run = 0;
    _run += delta;
    if (_run > AppActionCapsule.hideAfter) _set(true);
    if (_run < -AppActionCapsule.showAfter) _set(false);
  }

  void _set(bool hidden) {
    _run = 0;
    if (hidden != _hidden) setState(() => _hidden = hidden);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);

    final capsule = Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppActionCapsule.margin,
            0,
            AppActionCapsule.margin,
            AppActionCapsule.margin,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: DecoratedBox(
              // A `BoxDecoration` with a full radius, not a `ShapeDecoration`:
              // its shadow is a blurred rounded rect, which the renderer
              // draws directly; a shape's shadow is blurred offscreen.
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: isDark ? Border.all(color: colors.outline) : null,
                boxShadow: isDark
                    ? null
                    : <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: SizedBox(
                height: AppActionCapsule.height,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedSlide(
      offset: _hidden ? const Offset(0, 1.6) : Offset.zero,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 320),
      curve: AppCurves.enter,
      child: IgnorePointer(ignoring: _hidden, child: capsule),
    );
  }
}
