import 'package:flutter/foundation.dart';

import 'navigation_controller.dart';

/// Something a page asks ANOTHER tab to do when it opens — show a filter,
/// scroll to an item — together with switching to that tab.
///
/// The request is a [ValueNotifier] because the target tab may not exist yet
/// (tabs are built on their first visit): the tab reads it when it builds
/// and listens for later requests, then [take]s it so it runs once.
///
/// ```dart
/// // In the target tab's feature:
/// static final TabIntent<String> openCategory = TabIntent<String>();
///
/// // Anywhere:
/// FeedNavigation.openCategory.request(controller, feedTabIndex, 'design');
///
/// // In the target tab's state (initState + a listener):
/// final category = FeedNavigation.openCategory.take();
/// if (category != null) _applyFilter(category);
/// ```
class TabIntent<T> {
  final ValueNotifier<T?> pending = ValueNotifier<T?>(null);

  /// Leaves [value] for the tab at [tabIndex] and switches to it — staged
  /// like any tab change asked for from inside a page.
  void request(NavigationController controller, int tabIndex, T value) {
    pending.value = value;
    controller.switchFromBody(tabIndex);
  }

  /// The waiting value, cleared so it runs once. Null when none waits.
  T? take() {
    final value = pending.value;
    pending.value = null;
    return value;
  }
}
