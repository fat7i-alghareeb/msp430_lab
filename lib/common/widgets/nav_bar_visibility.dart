import 'package:flutter/widgets.dart';

/// Whether the floating bottom bar is out of the way: scrolling down a tab
/// tucks the bar into a small dock
/// that stays where it was; a clear scroll up, the top or the end of the
/// list, a tap or a swipe up on the dock, a tab switch, or coming back to
/// the tabs brings it back.
class NavBarVisibility extends ChangeNotifier {
  bool _hidden = false;

  bool get hidden => _hidden;

  void hide() {
    if (_hidden) return;
    _hidden = true;
    notifyListeners();
  }

  void show() {
    if (!_hidden) return;
    _hidden = false;
    notifyListeners();
  }
}

/// Hands a [NavBarVisibility] to the tabs and to anything that follows the
/// bar — the back-to-top button rides down with it.
class NavBarVisibilityScope extends InheritedNotifier<NavBarVisibility> {
  const NavBarVisibilityScope({
    super.key,
    required NavBarVisibility visibility,
    required super.child,
  }) : super(notifier: visibility);

  /// Null outside the tabs (a pushed page, a test).
  static NavBarVisibility? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NavBarVisibilityScope>()
      ?.notifier;
}

/// Watches the tabs' own vertical scrolling and hides or shows the bar
///:
/// - 24dp of scrolling down hides it;
/// - 64dp of scrolling up — not a small correction — shows it;
/// - reaching the top or the end of a list shows it.
///
/// Horizontal rails and carousels are ignored. With a screen reader on the
/// bar never hides: swiping through a list must not lose the tabs.
class NavBarScrollWatcher extends StatefulWidget {
  const NavBarScrollWatcher({
    super.key,
    required this.visibility,
    required this.child,
  });

  final NavBarVisibility visibility;
  final Widget child;

  /// Scrolling down this far hides the bar.
  static const double hideAfter = 24;

  /// Scrolling up this far brings it back.
  static const double showAfter = 64;

  @override
  State<NavBarScrollWatcher> createState() => _NavBarScrollWatcherState();
}

class _NavBarScrollWatcherState extends State<NavBarScrollWatcher> {
  double _down = 0;
  double _up = 0;

  bool _onScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return false;
    final metrics = n.metrics;
    if (metrics.axis != Axis.vertical) return false;
    if (MediaQuery.maybeAccessibleNavigationOf(context) ?? false) {
      widget.visibility.show();
      return false;
    }

    final delta = n.scrollDelta ?? 0;
    final atTop = metrics.pixels <= metrics.minScrollExtent + 1;
    final atEnd =
        metrics.maxScrollExtent > metrics.minScrollExtent &&
        metrics.pixels >= metrics.maxScrollExtent - 1;

    if (atTop || atEnd) {
      _down = 0;
      _up = 0;
      widget.visibility.show();
      return false;
    }
    if (delta > 0) {
      _down += delta;
      _up = 0;
      if (_down > NavBarScrollWatcher.hideAfter) widget.visibility.hide();
    } else if (delta < 0) {
      _up -= delta;
      _down = 0;
      if (_up > NavBarScrollWatcher.showAfter) widget.visibility.show();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}
