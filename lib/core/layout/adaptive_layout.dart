import 'package:flutter/widgets.dart';

import 'app_layout.dart';
import 'app_layout_scope.dart';

/// Swaps a whole subtree by window size class.
///
/// ```dart
/// AdaptiveLayout(
///   compact: (context) => const FeedList(),
///   medium: (context) => const FeedGrid(columns: 2),
///   expanded: (context) => const FeedSplitView(),
/// )
/// ```
///
/// A missing builder falls back to the next smaller one, so `compact` alone
/// is always enough. Rebuilds only when the size class changes — never on
/// each pixel of a window resize. For one-line tweaks (a padding, a flag)
/// read `context.layout` instead.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  /// Large and extra-large windows.
  final WidgetBuilder? large;

  @override
  Widget build(BuildContext context) {
    final size = AppLayoutScope.windowSizeOf(context);
    final builder = switch (size) {
      WindowSize.compact => compact,
      WindowSize.medium => medium ?? compact,
      WindowSize.expanded => expanded ?? medium ?? compact,
      WindowSize.large ||
      WindowSize.extraLarge => large ?? expanded ?? medium ?? compact,
    };
    return builder(context);
  }
}
