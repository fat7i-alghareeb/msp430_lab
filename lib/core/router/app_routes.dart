part of 'router_config.dart';

/// * AppPage
///
/// Every screen that is pushed over the shell, with the relative path it
/// takes UNDER the page that opens it (the screen's own `pagePath`).
///
/// Paths nest: an item opened from another item is `/root/items/1/items/2`,
/// and sign-in opened from it is `/root/items/1/items/2/login`. Each page is
/// pushed onto the ONE stack there is, and back pops to the page before it.
///
/// The enum order is the matching order among siblings: list a more specific
/// path (`items/featured`) before a parameterised one (`items/:id`).
enum AppPage {
  topic(TopicScreen.pagePath, TopicScreen.pageName);

  const AppPage(this.segment, this.screenName);

  /// The relative path template, e.g. `items/:id`.
  final String segment;

  /// The screen's own name — the last part of every route name for it.
  final String screenName;

  /// * The graph: what each parent opens, and so its child routes.
  ///
  /// A page opened from somewhere this list does not name still opens — it
  /// is pushed as a child of the shell instead (`AppNavigator`).
  List<AppPage> get children => switch (this) {
    AppPage.topic => const <AppPage>[],
  };

  /// The shell opens every page — the tabs, their headers and a link from
  /// outside all start here.
  static const List<AppPage> rootChildren = AppPage.values;
}

/// One route in the generated tree: which page, how deep, and what it opens.
class AppRouteNode {
  AppRouteNode._({
    required this.page,
    required this.depth,
    required this.name,
    required this.segment,
  });

  /// Null for the shell itself.
  final AppPage? page;

  /// 0 for the shell, 1 for a page opened from it, and so on.
  final int depth;

  final String name;

  /// This node's path, relative to its parent, with its parameters renamed
  /// for the depth (`items/:id2`).
  final String segment;

  final Map<AppPage, AppRouteNode> children = <AppPage, AppRouteNode>{};

  late final GoRoute route;

  bool get isRoot => page == null;

  /// The name this node gives the path parameter [base] — `id` becomes
  /// `id3` three pages deep. go_router refuses the same parameter twice in
  /// one path, and an item opened from an item has two ids.
  String param(String base) => '$base$depth';

  /// Fills this node's segment: `items/:id2` + `{id: 42}` → `items/42`.
  String fill(Map<String, String> params) {
    var filled = segment;
    params.forEach((base, value) {
      filled = filled.replaceFirst(
        ':${param(base)}',
        Uri.encodeComponent(value),
      );
    });
    return filled;
  }

  static final Expando<AppRouteNode> _byRoute = Expando<AppRouteNode>();

  /// The node a route of the generated tree belongs to, or null for a route
  /// outside it (the splash).
  static AppRouteNode? of(RouteBase route) => _byRoute[route];
}

/// Builds the screen for [page] from the route state; [param] reads a path
/// parameter by its base name (`id`).
typedef AppPageBuilder =
    Widget Function(
      AppPage page,
      GoRouterState state,
      String Function(String base) param,
    );

/// * AppRouteTree
///
/// The shell and everything pushed over it, as ONE nested tree generated
/// from [AppPage.children]: every parent owns its own child routes, with
/// their own names, even when two parents open the same screen.
///
/// The graph may have cycles (an item opens a related item, which opens
/// another), so the tree stops at [maxDepth] pages over the shell. A page
/// opened deeper than that is pushed as a child of the shell — the stack is
/// untouched, only its path starts again from `/root`. The route count grows
/// quickly with the graph: keep [maxDepth] as low as real walks need.
class AppRouteTree {
  AppRouteTree._();

  /// Pages over the shell the tree spells out.
  static const int maxDepth = 6;

  /// Builds the tree. [builder] and [shell] are the real screens by
  /// default; a test hands in stand-ins.
  static AppRouteNode build({
    AppPageBuilder builder = _buildScreen,
    WidgetBuilder? shell,
  }) {
    final root = AppRouteNode._(
      page: null,
      depth: 0,
      name: RootScreen.pageName,
      segment: RootScreen.pagePath,
    );
    root.route = GoRoute(
      path: RootScreen.pagePath,
      name: root.name,
      pageBuilder: (context, state) => AppPageTransitions.build(
        state: state,
        child: shell?.call(context) ?? const RootScreen(),
      ),
      routes: _childRoutes(root, AppPage.rootChildren, builder),
    );
    AppRouteNode._byRoute[root.route] = root;
    return root;
  }

  static List<RouteBase> _childRoutes(
    AppRouteNode parent,
    List<AppPage> pages,
    AppPageBuilder builder,
  ) {
    final depth = parent.depth + 1;
    if (depth > maxDepth) return const <RouteBase>[];

    // Siblings in enum order (see [AppPage]).
    final wanted = <AppPage>{...pages}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return <RouteBase>[
      for (final page in wanted) _node(parent, page, depth, builder).route,
    ];
  }

  static AppRouteNode _node(
    AppRouteNode parent,
    AppPage page,
    int depth,
    AppPageBuilder builder,
  ) {
    final node = AppRouteNode._(
      page: page,
      depth: depth,
      name: '${parent.name}.${page.name}',
      segment: page.segment.replaceAllMapped(
        RegExp(r':(\w+)'),
        (m) => ':${m[1]}$depth',
      ),
    );
    parent.children[page] = node;

    node.route = GoRoute(
      path: node.segment,
      name: node.name,
      pageBuilder: (context, state) => AppPageTransitions.build(
        state: state,
        child: builder(
          page,
          state,
          (base) => state.pathParameters[node.param(base)] ?? '',
        ),
      ),
      routes: _childRoutes(node, page.children, builder),
    );
    AppRouteNode._byRoute[node.route] = node;
    return node;
  }

  static Widget _buildScreen(
    AppPage page,
    GoRouterState state,
    String Function(String base) param,
  ) {
    return switch (page) {
      AppPage.topic => TopicScreen(topicId: param(TopicScreen.idParam)),
    };
  }
}

/// * AppRouteRegistry
///
/// The app's routes: the splash, then the shell
/// with the whole tree of pages pushed over it. Every page is a
/// `MaterialPage`, so it takes the theme's transition — on Android that is
/// the predictive back gesture.
@lazySingleton
class AppRouteRegistry {
  AppRouteRegistry();

  /// Built once.
  late final AppRouteNode tree = AppRouteTree.build();

  /// * All GoRouter routes for the app.
  List<RouteBase> get routes => <RouteBase>[
    GoRoute(
      path: SplashScreen.pagePath,
      name: SplashScreen.pageName,
      pageBuilder: (context, state) =>
          AppPageTransitions.build(state: state, child: const SplashScreen()),
    ),
    tree.route,
  ];
}
