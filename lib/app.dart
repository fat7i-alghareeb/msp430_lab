import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'common/widgets/rebuild_on_locale_change.dart';
import 'core/config/app_config.dart';
import 'core/injection/injectable.dart';
import 'core/layout/adaptive_typography.dart';
import 'core/layout/app_layout_scope.dart';
import 'core/layout/app_scroll_behavior.dart';
import 'core/layout/layout_reader.dart';
import 'core/platform/app_platform.dart';
import 'core/router/router_config.dart';
import 'core/services/localization/locale_service.dart';
import 'core/shortcuts/app_menu_bar.dart';
import 'core/shortcuts/app_shortcut_catalog.dart';
import 'core/shortcuts/app_shortcuts.dart';
import 'core/theme/app_system_ui_overlay.dart';
import 'core/theme/app_theme.dart';
import 'core/window/app_title_bar.dart';
import 'features/root/presentation/ui/screens/root_screen.dart';
import 'features/root/presentation/ui/widgets/nav_bar/navigation_controller.dart';
import 'features/root/presentation/ui/widgets/nav_bar/side_nav_controller.dart';
import 'utils/constants/design_constants.dart';

/// The page name the desktop title bar shows beside the app's: the open tab
/// on the shell, nothing elsewhere.
class _WindowPageTitle extends ValueNotifier<String?> {
  _WindowPageTitle() : super(null) {
    if (!AppPlatform.hasDesktopWindow) return;
    _router = getIt.isRegistered<AppRouterConfig>()
        ? getIt<AppRouterConfig>().router
        : null;
    _tabs = getIt.isRegistered<NavigationController>()
        ? getIt<NavigationController>()
        : null;
    _router?.routerDelegate.addListener(_update);
    _tabs?.addListener(_update);
    _update();
  }

  GoRouter? _router;
  NavigationController? _tabs;

  void _update() {
    final router = _router;
    if (router == null) return;
    final uri = router.routerDelegate.currentConfiguration.uri;
    value = uri.path == RootScreen.pagePath
        ? RootScreen.tabLabelAt(_tabs?.currentIndex ?? 0)
        : null;
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_update);
    _tabs?.removeListener(_update);
    super.dispose();
  }
}

/// The root widget, from the outside in: `MaterialApp.router` with the
/// light theme and the saved locale; then, in `builder`, the system-UI
/// colours, the reader's text size, the window size class for each frame
/// (`docs/RESPONSIVE.md`), the shortcuts and the desktop title bar.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _WindowPageTitle _pageTitle = _WindowPageTitle();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(getIt<LocaleService>().reconcilePersistedLocale(context));
    });
  }

  @override
  void dispose() {
    _pageTitle.dispose();
    super.dispose();
  }

  AppShortcutHandlers _shortcutHandlers(AppRouterConfig routerConfig) {
    final router = routerConfig.router;
    BuildContext? pageContext() =>
        router.routerDelegate.navigatorKey.currentContext;
    final tabs = getIt.isRegistered<NavigationController>()
        ? getIt<NavigationController>()
        : null;
    final sideNav = getIt.isRegistered<SideNavController>()
        ? getIt<SideNavController>()
        : null;
    return AppShortcutHandlers(
      switchTab: (index) {
        if (tabs == null) return;
        if (router.routerDelegate.currentConfiguration.uri.path !=
            RootScreen.pagePath) {
          router.go(RootScreen.pagePath);
        }
        tabs.setIndex(index);
      },
      goBack: () {
        final context = pageContext();
        if (context != null) Navigator.maybeOf(context)?.maybePop();
      },
      refresh: () {},
      toggleSidebar: () => sideNav?.toggle(),
      showHelp: () {
        final context = pageContext();
        if (context != null) AppShortcutCatalog.showHelp(context);
      },
    );
  }

  AppTitleBarConfig _titleBarConfig() {
    if (!AppPlatform.hasDesktopWindow) return const AppTitleBarConfig();
    final sideNav = getIt.isRegistered<SideNavController>()
        ? getIt<SideNavController>()
        : null;
    return AppTitleBarConfig(
      pageTitle: _pageTitle,
      onToggleSidebar: sideNav?.toggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRouterConfig = getIt<AppRouterConfig>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appTitle,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      themeAnimationDuration: AppDurations.themeAnimation,
      themeAnimationCurve: AppCurves.theme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: appRouterConfig.router,
      // Always-visible scrollbars on desktop (platform idioms).
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) {
        final overlayStyle = AppSystemUiOverlay.forTheme(Theme.of(context));
        final app = child ?? const SizedBox.shrink();

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          // The reader's own text size (85–130%) and a little more in a big
          // window.
          child: AppTextScaleHost(
            // Device type and window size classes for this frame: right in
            // the first frame, and in the same frame as a rotation or a
            // window resize.
            child: AppLayoutHost(
              reader: getIt.isRegistered<LayoutReader>()
                  ? getIt<LayoutReader>()
                  : null,
              child: AdaptiveTypography(
                // A language change rebuilds the whole app in place, keyed to
                // the loaded `Localizations`, not to `context.locale`.
                child: RebuildOnLocaleChange(
                  locale: Localizations.localeOf(context),
                  child: AppMenuBar(
                    handlers: _shortcutHandlers(appRouterConfig),
                    child: AppShortcuts(
                      handlers: _shortcutHandlers(appRouterConfig),
                      child: AppDesktopFrame(
                        config: _titleBarConfig(),
                        child: app,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
