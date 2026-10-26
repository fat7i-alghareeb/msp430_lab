import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../core/router/app_page_transitions.dart';
import '../../features/root/presentation/ui/screens/root_screen.dart';
import '../../features/splash/presentation/ui/screens/splash_screen.dart';
import '../../features/topic/presentation/ui/screens/topic_screen.dart';
import '../../utils/constants/app_flow_constants.dart';
import '../../utils/helpers/colored_print.dart';

part 'app_routes.dart';

/// * RouterRefreshListenable
///
/// Tells GoRouter to run its redirect again once the splash has been held
/// for [SplashConfig.initialDelay], so a fast device never cuts the
/// entrance off mid-flight.
class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable() {
    _timer = Timer(SplashConfig.initialDelay, () {
      _splashDelayElapsed = true;
      printC('${RouterLogTags.router} splash minimum elapsed');
      notifyListeners();
    });
  }

  Timer? _timer;
  bool _splashDelayElapsed = false;

  bool get splashDelayElapsed => _splashDelayElapsed;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// * AppRouterConfig
///
/// Owns the [GoRouter]: the splash, then the shell with the tree of pages
/// pushed over it ([AppRouteRegistry]).
@lazySingleton
class AppRouterConfig {
  AppRouterConfig(this._routeRegistry) {
    _refresh = RouterRefreshListenable();
    _guard = AppRouteGuard(
      splashPath: SplashScreen.pagePath,
      rootPath: RootScreen.pagePath,
    );

    _router = GoRouter(
      initialLocation: SplashScreen.pagePath,
      routes: _routeRegistry.routes,
      refreshListenable: _refresh,
      redirect: (context, state) => _guard.handleRedirect(
        state: state,
        splashDelayElapsed: _refresh.splashDelayElapsed,
      ),
    );
  }

  final AppRouteRegistry _routeRegistry;

  late final RouterRefreshListenable _refresh;
  late final AppRouteGuard _guard;
  late final GoRouter _router;

  GoRouter get router => _router;
}

/// * AppRouteGuard
///
/// The redirect rules, in one place: stay on the splash until its delay has
/// passed, then leave it for the shell.
class AppRouteGuard {
  AppRouteGuard({required this.splashPath, required this.rootPath});

  final String splashPath;
  final String rootPath;

  String? handleRedirect({
    required GoRouterState state,
    required bool splashDelayElapsed,
  }) {
    final currentPath = state.matchedLocation;

    printM('${RouterLogTags.redirect} currentPath="$currentPath"');

    // While the splash is held, nothing else may redirect: GoRouter would
    // leave it before its first frame is painted.
    if (!splashDelayElapsed) {
      return currentPath == splashPath ? null : splashPath;
    }

    if (currentPath == splashPath) {
      printG('${RouterLogTags.redirect} to root');
      return rootPath;
    }
    return null;
  }
}
