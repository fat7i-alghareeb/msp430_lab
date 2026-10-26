import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Supported page transition types.
enum AppTransition {
  /// The theme's transition, through a [MaterialPage] — the default. On
  /// Android that is `PredictiveBackPageTransitionsBuilder`: the system back
  /// gesture previews the page underneath (Android 14+ / 16's predictive
  /// back), and a plain open or close uses Android's fade-forwards.
  ///
  /// Every other value builds a [CustomTransitionPage], which ignores the
  /// theme and so has NO predictive back — use them only where that is
  /// intended.
  platform,
  fade,
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  scale,
  fadeScale,
  none,
}

/// * AppPageTransitions
///
/// Small utility responsible only for building pages with a given
/// [AppTransition]. This keeps animation logic separate from route
/// registration.
class AppPageTransitions {
  const AppPageTransitions._();

  static Page<T> build<T>({
    required GoRouterState state,
    required Widget child,
    AppTransition transition = AppTransition.platform,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
  }) {
    final effectiveTransitionDuration =
        transitionDuration ?? const Duration(milliseconds: 300);
    final effectiveReverseTransitionDuration =
        reverseTransitionDuration ?? const Duration(milliseconds: 300);

    switch (transition) {
      case AppTransition.platform:
        return MaterialPage<T>(
          key: state.pageKey,
          name: state.name,
          arguments: <String, String>{
            ...state.pathParameters,
            ...state.uri.queryParameters,
          },
          restorationId: state.pageKey.value,
          child: child,
        );

      case AppTransition.none:
        return MaterialPage<T>(key: state.pageKey, child: child);

      case AppTransition.slideFromRight:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          child: child,
          transitionDuration: effectiveTransitionDuration,
          reverseTransitionDuration: effectiveReverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );

      case AppTransition.slideFromLeft:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          child: child,
          transitionDuration: effectiveTransitionDuration,
          reverseTransitionDuration: effectiveReverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(animation);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );

      case AppTransition.slideFromBottom:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          child: child,
          transitionDuration: effectiveTransitionDuration,
          reverseTransitionDuration: effectiveReverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(animation);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );

      case AppTransition.slideFromTop:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          child: child,
          transitionDuration: effectiveTransitionDuration,
          reverseTransitionDuration: effectiveReverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.0, -1.0),
              end: Offset.zero,
            ).animate(animation);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );

      case AppTransition.scale:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          child: child,
          transitionDuration: effectiveTransitionDuration,
          reverseTransitionDuration: effectiveReverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(scale: animation, child: child);
          },
        );

      case AppTransition.fadeScale:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          child: child,
          transitionDuration: effectiveTransitionDuration,
          reverseTransitionDuration: effectiveReverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
        );

      case AppTransition.fade:
        return CustomTransitionPage<T>(
          key: state.pageKey,
          child: child,
          transitionDuration: effectiveTransitionDuration,
          reverseTransitionDuration: effectiveReverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
    }
  }
}
