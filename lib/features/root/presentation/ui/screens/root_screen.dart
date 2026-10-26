import '../../../../../common/imports/imports.dart';
import '../../../../../common/widgets/custom_scaffold/app_scaffold.dart';
import '../../../../../common/widgets/nav_bar_visibility.dart';
import '../../../constants/root_constants.dart';
import '../widgets/nav_bar/app_bottom_nav.dart';
import '../widgets/nav_bar/app_side_nav.dart';
import '../widgets/nav_bar/navigation_controller.dart';
import '../widgets/nav_bar/navigation_scope.dart';
import '../widgets/nav_bar/side_nav_controller.dart';
import '../widgets/root_back_guard.dart';
import '../widgets/root_tab_placeholder.dart';
import '../widgets/root_tab_stack.dart';
import '../widgets/tab_switch_stager.dart';

/// Root screen that hosts the top-level navigation — the app's shell.
///
/// The floating capsule in a compact window, a rail in a medium one (or on
/// a phone held sideways), the sidebar from 840dp (`docs/RESPONSIVE.md`).
///
/// Implementation notes:
/// - The tabs live in a [RootTabStack]: each is built on its first visit and
///   kept from then on (scroll position, filters, loaded data), and a switch
///   is a 220ms cross-fade.
/// - A tab asked for from inside a page is staged by [TabSwitchStager] so it
///   reads as a tab change, not a new page.
/// - Back on another tab returns to the first tab; back on the first tab
///   asks before leaving the app ([RootBackGuard]).
/// - The floating capsule sits over the tabs' content (`extendBody`), and
///   tucks into a dock while a tab scrolls down ([NavBarVisibility]).
/// - Tabs own no scaffold: two scaffolds stacked would give the page two
///   grounds and two safe areas.
///
/// The three destinations below are placeholders — replace them with the
/// app's own tabs (five is the ceiling).
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  static const String pagePath = RootConstants.routePath;
  static const String pageName = 'RootScreen';

  /// The tabs' names, in the order of the bar — also what the desktop title
  /// bar shows for the open tab.
  static List<String> get tabLabels => <String>[
    AppStrings.navHome,
    AppStrings.navTopics,
    AppStrings.navAbout,
  ];

  static String? tabLabelAt(int index) {
    final labels = tabLabels;
    return index >= 0 && index < labels.length ? labels[index] : null;
  }

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late final NavigationController _controller;
  late final bool _ownsController;

  /// The bar tucks into its dock on scroll.
  final NavBarVisibility _barVisibility = NavBarVisibility();

  /// Keeps the tabs alive across a change of navigation layout.
  final GlobalKey _tabsKey = GlobalKey(debugLabel: 'root-tabs');

  bool _wasCurrent = true;

  @override
  void initState() {
    super.initState();

    // Prefer DI when available; fall back to a local instance (a test).
    final hasDiController = getIt.isRegistered<NavigationController>();
    _controller = hasDiController
        ? getIt<NavigationController>()
        : NavigationController();
    _ownsController = !hasDiController;
    // Every new screen shows the bar: a tab switch, or a tap on the tab
    // already open.
    _controller.addListener(_barVisibility.show);

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // …and so does coming back to the tabs from a page opened over them.
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (isCurrent && !_wasCurrent) _barVisibility.show();
    _wasCurrent = isCurrent;
  }

  @override
  void dispose() {
    _controller.removeListener(_barVisibility.show);
    _barVisibility.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale;

    final destinations = <AppNavDestination>[
      AppNavDestination(icon: AppIcons.home, label: AppStrings.navHome),
      AppNavDestination(icon: AppIcons.grid, label: AppStrings.navTopics),
      AppNavDestination(icon: AppIcons.comment, label: AppStrings.navAbout),
    ];

    // One builder per tab, in the order of the bar.
    final pageBuilders = <WidgetBuilder>[
      (_) => RootTabPlaceholder(title: AppStrings.navHome),
      (_) => RootTabPlaceholder(title: AppStrings.navTopics),
      (_) => RootTabPlaceholder(title: AppStrings.navAbout),
    ];

    // Where the destinations go is the window's call, not the device's
    // (`docs/RESPONSIVE.md`): the capsule in a compact window, the rail in
    // a medium one or on a phone held sideways, the sidebar from 840dp.
    final nav = AppLayoutScope.navOf(context);

    // The SAME tab stack in every layout: a GlobalKey carries it — its
    // scroll positions, loaded data and open search — across a rotation or
    // a window resize instead of rebuilding it from scratch.
    final tabs = NavBarScrollWatcher(
      key: _tabsKey,
      visibility: _barVisibility,
      child: RootTabStack(controller: _controller, tabs: pageBuilders),
    );

    final body = nav == NavLayout.bar
        ? tabs
        : _sideNavLayout(context, nav, destinations, tabs);

    return RootBackGuard(
      controller: _controller,
      child: NavigationScope(
        controller: _controller,
        child: NavBarVisibilityScope(
          visibility: _barVisibility,
          child: TabSwitchStager(
            controller: _controller,
            visibility: _barVisibility,
            labels: <String>[
              for (final destination in destinations) destination.label,
            ],
            child: AppScaffold.body(
              // The capsule floats OVER the tabs rather than sitting on a
              // strip of its own: the lists run on underneath it and show
              // around its edges (`AppBottomNav.listBottomPadding` keeps
              // each last row clear).
              scaffoldConfig: AppScaffoldConfig(
                extendBody: nav == NavLayout.bar,
              ),
              bottomNavigationBar: nav == NavLayout.bar
                  ? AppBottomNav(
                      controller: _controller,
                      destinations: destinations,
                      visibility: _barVisibility,
                    )
                  : null,
              child: body,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sideNavLayout(
    BuildContext context,
    NavLayout nav,
    List<AppNavDestination> destinations,
    Widget tabs,
  ) {
    final layout = context.layout;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final sideNav = getIt.isRegistered<SideNavController>()
        ? getIt<SideNavController>()
        : null;

    Widget buildSide(bool collapsed) {
      final extended = nav == NavLayout.sidebar && !collapsed;
      return SafeArea(
        // Clear of the status bar, the home indicator and, on a phone held
        // sideways, the notch on the start side.
        left: !isRtl,
        right: isRtl,
        child: AppSideNav(
          controller: _controller,
          destinations: destinations,
          extended: extended,
          short: layout.isShort,
          config: AppSideNavConfig(
            // On desktop the search lives in the title bar.
            showSearch: false,
            collapsible: nav == NavLayout.sidebar,
          ),
        ),
      );
    }

    // The rail sits on the START edge, so it flips with the language like
    // everything else: right in Arabic, left in English.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (sideNav == null)
          buildSide(false)
        else
          ValueListenableBuilder<bool>(
            valueListenable: sideNav,
            builder: (context, collapsed, _) => buildSide(collapsed),
          ),
        Expanded(child: tabs),
      ],
    );
  }
}
