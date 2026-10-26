import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import '../../../utils/extensions/context_extensions.dart';
import '../../../utils/extensions/theme_extensions.dart';
import '../../../utils/helpers/app_strings.dart';
import 'app_icons.dart';

/// Lets a mouse drag a horizontal rail or carousel, which Flutter's default
/// scroll behaviour leaves to touch and trackpads.
///
/// Only sideways strips get it (`docs/RESPONSIVE.md`): vertical lists keep
/// the wheel and the scrollbar, so a click-and-drag there still selects text.
class AppDragScroll extends StatelessWidget {
  const AppDragScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return ScrollConfiguration(
      behavior: behavior.copyWith(
        dragDevices: <PointerDeviceKind>{
          ...behavior.dragDevices,
          PointerDeviceKind.mouse,
        },
      ),
      child: child,
    );
  }
}

/// Previous / next buttons over a horizontal strip, shown while a mouse
/// hovers it.
///
/// A mouse cannot swipe; the arrows are the visible way to move, and they
/// appear only for a pointer, so touch screens never see them. The arrows
/// follow the reading direction: «next» is on the end side.
class AppPointerArrows extends StatefulWidget {
  const AppPointerArrows({
    super.key,
    required this.child,
    required this.onPrevious,
    required this.onNext,
    this.canPrevious,
    this.canNext,
  });

  final Widget child;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Hides an arrow at the start or end of the strip. Null: always shown.
  final ValueGetter<bool>? canPrevious;
  final ValueGetter<bool>? canNext;

  @override
  State<AppPointerArrows> createState() => _AppPointerArrowsState();
}

class _AppPointerArrowsState extends State<AppPointerArrows> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final showPrev = _hovering && (widget.canPrevious?.call() ?? true);
    final showNext = _hovering && (widget.canNext?.call() ?? true);
    return MouseRegion(
      onEnter: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          setState(() => _hovering = true);
        }
      },
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          widget.child,
          PositionedDirectional(
            start: AppSpacing.sm,
            child: _Arrow(
              visible: showPrev,
              next: false,
              onTap: () {
                widget.onPrevious();
                setState(() {});
              },
            ),
          ),
          PositionedDirectional(
            end: AppSpacing.sm,
            child: _Arrow(
              visible: showNext,
              next: true,
              onTap: () {
                widget.onNext();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.visible,
    required this.next,
    required this.onTap,
  });

  final bool visible;
  final bool next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final label = next ? AppStrings.galleryNext : AppStrings.galleryPrevious;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppDurations.toggle,
        child: Tooltip(
          message: label,
          child: Material(
            color: colors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: context.shadows.card,
                ),
                child: SizedBox.square(
                  dimension: AppIconSizes.minTouchTarget,
                  child: Center(
                    // The chevron that points to the end in this direction.
                    child: AppIcon(
                      next ? context.chevronEnd : context.chevronStart,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
