import 'package:flutter/widgets.dart';

/// Commands the keyboard and the macOS menu bar run, provided by whichever
/// screen can carry them out right now.
///
/// The shortcut does not know the feed; the feed knows how to refresh. A
/// screen registers while it is up and unregisters when it goes, so Ctrl+R
/// refreshes whatever is showing and does nothing where nothing can.
abstract final class AppCommands {
  static final List<VoidCallback> _refreshers = <VoidCallback>[];
  static final List<FocusNode> _searchFields = <FocusNode>[];

  /// The most recently shown screen that can refresh.
  static void addRefresher(VoidCallback refresh) => _refreshers.add(refresh);

  static void removeRefresher(VoidCallback refresh) =>
      _refreshers.remove(refresh);

  static void refresh() {
    if (_refreshers.isNotEmpty) _refreshers.last();
  }

  /// A search field Ctrl/⌘+K can jump to: the title bar's on desktop, a
  /// screen's own elsewhere. The last one registered that is on screen wins.
  static void addSearchField(FocusNode node) => _searchFields.add(node);

  static void removeSearchField(FocusNode node) => _searchFields.remove(node);

  static void focusSearch() {
    for (final node in _searchFields.reversed) {
      final context = node.context;
      if (context != null && context.mounted && node.canRequestFocus) {
        node.requestFocus();
        return;
      }
    }
  }
}
