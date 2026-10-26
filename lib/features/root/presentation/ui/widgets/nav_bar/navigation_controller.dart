import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Root-level navigation controller for the bottom tabs.
///
/// Responsibilities:
/// - Tracks the current selected tab index.
/// - Exposes a [transitionToken] that increments on tab changes.
///   Widgets can use it as a "change id" to restart animations.
/// - Exposes a [reselectToken] for a tap on the tab that is already active.
///
/// The handover itself — the fade through between two tabs — belongs to
/// `RootTabStack`, which listens to this controller. There is no
/// `PageController` any more: a `PageView` shows one page at a time, so the
/// tab being left vanished on the frame the new one began, and the switch
/// flashed bare background.
///
/// Notes on DI:
/// - This controller is a `@lazySingleton`: there is ONE tab bar, and a screen
///   pushed over it (a listing's page, unified search) reaches the shell's
///   controller through `getIt` because `NavigationScope` is not its ancestor.
///   As a plain `@injectable` every such call got a fresh controller nobody
///   listened to, and «عرض الكل» popped the search screen without switching
///   the tab.
/// - In the template (`__brick__`) the DI config might not include it until the
///   consumer project runs code generation.
@lazySingleton
class NavigationController extends ChangeNotifier {
  NavigationController();

  int _currentIndex = 0;
  int _transitionToken = 0;
  int _reselectToken = 0;
  int? _highlighted;

  int get currentIndex => _currentIndex;

  /// The tab the BAR shows as active. It runs ahead of [currentIndex] for a
  /// moment when a page asks for another tab: the bar's pill moves first,
  /// then the page changes.
  int get barIndex => _highlighted ?? _currentIndex;

  /// A tab change asked for from inside a page, for the shell to stage
  ///. The shell sets [hasStager] while it listens; with no
  /// stager (a test, no shell) the switch happens at once.
  final ValueNotifier<TabSwitchRequest?> bodyRequests =
      ValueNotifier<TabSwitchRequest?>(null);
  bool hasStager = false;
  int _requestSerial = 0;

  /// Asks for [index] from inside a page — «عرض الكل», a section tile, a
  /// «back to the tab» from a pushed page.
  void switchFromBody(int index) {
    if (index == _currentIndex || !hasStager) {
      setIndex(index);
      return;
    }
    bodyRequests.value = TabSwitchRequest(
      index: index,
      serial: ++_requestSerial,
    );
  }

  /// The bar shows [index] as active before the page changes.
  void highlight(int index) {
    if (_highlighted == index) return;
    _highlighted = index;
    notifyListeners();
  }

  int get transitionToken => _transitionToken;

  /// Bumped when the ACTIVE tab is tapped again: the tab
  /// scrolls its list back to the top. A screen compares this against the value
  /// it last saw; the index itself does not change, so nothing else would tell
  /// it the tap happened.
  int get reselectToken => _reselectToken;

  /// Sets the index the shell opens on, before it is built. Nothing is
  /// animated and nobody is told: there is nothing on screen yet.
  void setInitialIndex(int index) {
    _currentIndex = index;
  }

  /// Changes the selected tab — or, for the tab already showing, asks it to
  /// scroll back to the top ([reselectToken]).
  void setIndex(int index) {
    _highlighted = null;
    if (index == _currentIndex) {
      _reselectToken++;
      notifyListeners();
      return;
    }

    _currentIndex = index;
    _transitionToken++;
    notifyListeners();
  }

  @override
  void dispose() {
    bodyRequests.dispose();
    super.dispose();
  }
}

/// One tab change asked for from inside a page.
@immutable
class TabSwitchRequest {
  const TabSwitchRequest({required this.index, required this.serial});

  final int index;

  /// Makes two requests for the same tab different values.
  final int serial;
}
