import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../utils/helpers/colored_print.dart';
import 'router_config.dart';

export 'router_config.dart' show AppPage;

/// A page and what it needs to open: path parameters by their base name
/// (`id`) and query parameters.
@immutable
class AppTarget {
  const AppTarget(
    this.page, {
    this.params = const <String, String>{},
    this.query = const <String, String>{},
  });

  final AppPage page;
  final Map<String, String> params;
  final Map<String, String> query;

  @override
  bool operator ==(Object other) =>
      other is AppTarget &&
      other.page == page &&
      mapEquals(other.params, params) &&
      mapEquals(other.query, query);

  @override
  int get hashCode => Object.hash(
    page,
    Object.hashAllUnordered(params.entries.map((e) => '${e.key}=${e.value}')),
    Object.hashAllUnordered(query.entries.map((e) => '${e.key}=${e.value}')),
  );

  @override
  String toString() => 'AppTarget(${page.name}, $params, $query)';
}

/// * AppNavigator
///
/// The one way a page is opened: PUSHED onto the single stack, as a child
/// of the page on top of it. The path grows with the stack —
/// `/root/items/1` → `/root/items/1/items/2` → `/root/items/1/items/2/login`
/// — and back pops to the page before, with the path before.
///
/// Where the page on top does not open [AppTarget.page] in the route graph
/// (`AppPage.children`), or the tree is already [AppRouteTree.maxDepth]
/// deep, the page is pushed as a child of the shell instead: the stack
/// still grows by one and back still returns, only the path restarts at
/// `/root`.
class AppNavigator {
  AppNavigator._();

  /// Opens [page] over whatever is on top. Returns null without pushing
  /// where there is no app router (a test, a preview) — the caller falls
  /// back to a plain push there.
  static Future<T?>? push<T extends Object?>(
    BuildContext context,
    AppPage page, {
    Map<String, String> params = const <String, String>{},
    Map<String, String> query = const <String, String>{},
  }) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return null;
    return pushTarget<T>(router, AppTarget(page, params: params, query: query));
  }

  /// [push] for a caller that holds the router rather than a context — a
  /// link from outside the app, the expired-session banner.
  static Future<T?> pushTarget<T extends Object?>(
    GoRouter router,
    AppTarget target,
  ) {
    final location = locationFor(router, target);
    printG('[Nav] push $location');
    return router.push<T>(location);
  }

  /// Where [target] lands when pushed over the current stack of [router].
  static String locationFor(GoRouter router, AppTarget target) {
    final matches = router.routerDelegate.currentConfiguration.matches;

    // The page on top and the tree node it is.
    AppRouteNode? topNode;
    String topLocation = '';
    if (matches.isNotEmpty) {
      final top = matches.last;
      topNode = AppRouteNode.of(top.route);
      topLocation = top.matchedLocation;
    }

    var parent = topNode;
    var base = topLocation;
    if (parent == null || !parent.children.containsKey(target.page)) {
      parent = _root(router);
      base = parent.segment;
      if (topNode != null && !topNode.isRoot) {
        printY(
          '[Nav] ${topNode.name} has no ${target.page.name} child — '
          'pushing it under the shell',
        );
      }
    }

    final node = parent.children[target.page]!;
    final path = '$base/${node.fill(target.params)}';
    return Uri(
      path: path,
      queryParameters: target.query.isEmpty ? null : target.query,
    ).toString();
  }

  static AppRouteNode _root(GoRouter router) {
    for (final route in router.configuration.routes) {
      final node = AppRouteNode.of(route);
      if (node != null && node.isRoot) return node;
    }
    throw StateError('The router has no shell route (AppRouteTree).');
  }
}
