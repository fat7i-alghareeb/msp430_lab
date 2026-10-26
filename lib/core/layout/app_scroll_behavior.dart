import 'package:flutter/material.dart';

import '../platform/app_platform.dart';

/// Scrolling as each platform expects it.
///
/// Flutter's platform idioms guide: desktop users expect large scrollbars
/// that are always there to grab; mobile users expect thin ones that show
/// only while scrolling. So on desktop every vertical list shows its
/// scrollbar ([Scrollbar.thumbVisibility]); phones and tablets keep
/// Material's default.
///
/// Mouse dragging stays off for lists — the wheel and the scrollbar scroll
/// them, and a click-and-drag selects text. Horizontal rails and carousels
/// turn it on for themselves (`AppDragScroll`).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // An always-visible thumb needs the scroll view's own controller; a
    // list built without one keeps Material's default desktop scrollbar.
    if (AppPlatform.isDesktop &&
        details.controller != null &&
        axisDirectionToAxis(details.direction) == Axis.vertical) {
      return Scrollbar(
        controller: details.controller,
        thumbVisibility: true,
        child: child,
      );
    }
    return super.buildScrollbar(context, child, details);
  }
}
