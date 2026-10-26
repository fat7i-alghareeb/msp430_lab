import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/app_icon_source.dart';
import '../../../common/widgets/ds/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../utils/constants/design_constants.dart';
import '../../../utils/extensions/context_extensions.dart';
import '../../../utils/extensions/theme_extensions.dart';
import '../../../utils/extensions/widget_extensions.dart';
import '../../../utils/extensions/num_spacing_extensions.dart';

part 'app_scaffold_variants.dart';
part 'app_scaffold_app_bar.dart';
part 'app_scaffold_drawer.dart';
part 'app_scaffold_tap_area.dart';

/// Small wrapper for a minimal set of Scaffold configuration.
///
/// Keeping this in a separate config object allows the scaffold API to scale
/// without adding dozens of parameters to [AppScaffold].
final class AppScaffoldConfig {
  const AppScaffoldConfig({
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.safeArea = const <AppScaffoldSafeArea>[],
    this.extendBody = false,
  });

  /// Background color passed to [Scaffold].
  final Color? backgroundColor;

  /// Passed to [Scaffold.resizeToAvoidBottomInset].
  final bool resizeToAvoidBottomInset;

  /// Edges kept clear of system UI. Empty by default: screens draw edge to
  /// edge, behind the transparent status and navigation bars. An app bar
  /// pads itself; add an edge here only where content must avoid it.
  final List<AppScaffoldSafeArea> safeArea;

  /// Passed to [Scaffold.extendBody]: the body runs on under the
  /// `bottomNavigationBar` instead of stopping at its top edge. The shell
  /// sets it so the floating capsule floats OVER the tabs' content — the
  /// lists scroll on underneath it and show around its edges — and each
  /// list reserves `AppBottomNav.listBottomPadding` so its last row can
  /// still clear it.
  final bool extendBody;
}

/// A compact, feature-driven scaffold that composes optional UI sections
/// (custom app bar, end drawer) without using Flutter's [AppBar].
///
/// This widget is designed for:
/// - Low memory footprint
/// - Minimal rebuild surface
/// - Avoiding building/rendering disabled sections
///
/// Important constraints:
/// - Does **not** use Flutter's [AppBar].
/// - Does **not** wrap content in [SafeArea].
/// - Only renders sections whose [ScaffoldFeature] is enabled.
///
/// ## Recommended usage
///
/// ### 1) App bar only
/// ```dart
/// return AppScaffold.appBar(
///   appBarConfig: const AppScaffoldAppBarConfig(title: 'Profile'),
///   child: const ProfileBody(),
/// );
/// ```
///
/// ## Drawer behavior
/// The end drawer is only enabled when:
/// - [ScaffoldFeature.appBar] is enabled
/// - and [AppScaffoldAppBarConfig.enableDrawer] is `true`
class AppScaffold extends StatelessWidget {
  const AppScaffold._({
    super.key,
    required this.child,
    required Set<ScaffoldFeature> features,
    this.scaffoldConfig = const AppScaffoldConfig(),
    this.appBarConfig,
    this.endDrawer,

    this.bottomNavigationBar,
    this.topSpacing = 0,
    this.afterAppBarSpacing = AppSpacing.md,
  }) : _features = features;

  /// Creates a scaffold that renders only the [child] body.
  ///
  /// This constructor enables no optional features.
  factory AppScaffold.body({
    Key? key,
    required Widget child,
    AppScaffoldConfig scaffoldConfig = const AppScaffoldConfig(),
    double topSpacing = 0,
    Widget? bottomNavigationBar,
    Widget? endDrawer,
  }) {
    return AppScaffold._(
      key: key,
      features: const <ScaffoldFeature>{},
      scaffoldConfig: scaffoldConfig,
      topSpacing: topSpacing,
      bottomNavigationBar: bottomNavigationBar,
      endDrawer: endDrawer,
      child: child,
    );
  }

  factory AppScaffold.appBar({
    Key? key,
    required Widget child,
    AppScaffoldConfig scaffoldConfig = const AppScaffoldConfig(),
    required AppScaffoldAppBarConfig appBarConfig,
    double topSpacing = 0,
    double afterAppBarSpacing = AppSpacing.md,
    Widget? bottomNavigationBar,
    Widget? endDrawer,
  }) {
    return AppScaffold._(
      key: key,
      features: const {ScaffoldFeature.appBar},
      scaffoldConfig: scaffoldConfig,
      appBarConfig: appBarConfig,
      topSpacing: topSpacing,
      afterAppBarSpacing: afterAppBarSpacing,
      bottomNavigationBar: bottomNavigationBar,
      endDrawer: endDrawer,
      child: child,
    );
  }

  factory AppScaffold.custom({
    Key? key,
    required Widget child,
    required List<ScaffoldFeature> features,
    AppScaffoldConfig scaffoldConfig = const AppScaffoldConfig(),
    AppScaffoldAppBarConfig? appBarConfig,
    double topSpacing = 0,
    double afterAppBarSpacing = AppSpacing.md,
    Widget? bottomNavigationBar,
    Widget? endDrawer,
  }) {
    return AppScaffold._(
      key: key,
      features: Set<ScaffoldFeature>.unmodifiable(features),
      scaffoldConfig: scaffoldConfig,
      appBarConfig: appBarConfig,
      topSpacing: topSpacing,
      afterAppBarSpacing: afterAppBarSpacing,
      bottomNavigationBar: bottomNavigationBar,
      endDrawer: endDrawer,
      child: child,
    );
  }

  final Widget child;
  final Set<ScaffoldFeature> _features;
  final AppScaffoldConfig scaffoldConfig;

  final AppScaffoldAppBarConfig? appBarConfig;

  /// Optional end drawer content.
  ///
  /// Only built when the drawer feature is enabled.
  final Widget? endDrawer;

  final Widget? bottomNavigationBar;

  final double topSpacing;
  final double afterAppBarSpacing;

  /// Whether the app bar section is enabled by the feature set.
  bool get _appBarEnabled => _features.contains(ScaffoldFeature.appBar);

  /// Drawer is intentionally gated behind the app bar so:
  /// - we don't expose a drawer action without a chrome that can trigger it
  /// - we don't allocate/endDrawer unless explicitly required
  bool get _drawerEnabled =>
      _appBarEnabled && (appBarConfig?.enableDrawer ?? false);

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);

    final appBarConfig = this.appBarConfig;

    /// The body is composed from top-to-bottom.
    /// Disabled sections are not built at all.
    final body = SafeArea(
      top: scaffoldConfig.safeArea.contains(AppScaffoldSafeArea.top),
      bottom: scaffoldConfig.safeArea.contains(AppScaffoldSafeArea.bottom),
      left: scaffoldConfig.safeArea.contains(AppScaffoldSafeArea.left),
      right: scaffoldConfig.safeArea.contains(AppScaffoldSafeArea.right),
      child: Column(
        children: <Widget>[
          if (topSpacing > 0) topSpacing.verticalSpace,
          if (_appBarEnabled && appBarConfig != null) ...[
            _AppScaffoldAppBar(
              config: appBarConfig,
              drawerEnabled: _drawerEnabled,
            ).standardHorizontalPadding,
            if (afterAppBarSpacing > 0) afterAppBarSpacing.verticalSpace,
          ],
          Expanded(child: child),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => context.unfocusHard(),
      child: Scaffold(
        backgroundColor: scaffoldConfig.backgroundColor,
        resizeToAvoidBottomInset: scaffoldConfig.resizeToAvoidBottomInset,
        extendBody: scaffoldConfig.extendBody,
        endDrawer: _drawerEnabled ? _AppEndDrawerShell(child: endDrawer) : null,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
