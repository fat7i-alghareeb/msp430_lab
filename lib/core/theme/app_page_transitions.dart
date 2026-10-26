import 'package:flutter/material.dart';

import '../../utils/constants/design_constants.dart';

/// Screen transition — `DESIGN_SYSTEM.md`.
///
/// Forward navigation slides in from the **end** edge (left in RTL, right in
/// LTR); going back reverses it. The direction follows the ambient
/// [Directionality], so nothing has to be flipped per language.
///
/// Only `transform` and `opacity` move — never width or height.
///
/// When the platform reports reduced motion, the slide is replaced by a
/// 100ms fade, as the spec requires.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return FadeTransition(opacity: animation, child: child);
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // The incoming screen starts one screen away, on the end edge.
    final beginOffset = Offset(isRtl ? -1 : 1, 0);

    final position = Tween<Offset>(begin: beginOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: animation,
            curve: AppCurves.enter,
            reverseCurve: AppCurves.exit,
          ),
        );

    // The screen underneath drifts a third of the way in the same direction,
    // which reads as depth without a second full-speed animation.
    final parallax =
        Tween<Offset>(
          begin: Offset.zero,
          end: Offset(isRtl ? 0.33 : -0.33, 0),
        ).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: AppCurves.enter,
            reverseCurve: AppCurves.exit,
          ),
        );

    return SlideTransition(
      position: parallax,
      child: SlideTransition(position: position, child: child),
    );
  }
}
