import 'package:flutter/widgets.dart';

import '../../../core/layout/app_layout.dart';

/// Centres [child] in a column at most [maxWidth] wide.
///
/// Flutter's large-screen guidance: neither boxes nor lines of text should
/// run the full width of a desktop window. Put it INSIDE the scroll view, so
/// the scrollbar stays at the window's edge while the content is centred.
class AppContentWidth extends StatelessWidget {
  const AppContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
  });

  /// A column of reading width — forms, settings, articles.
  const AppContentWidth.readable({super.key, required this.child})
    : maxWidth = 840;

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
