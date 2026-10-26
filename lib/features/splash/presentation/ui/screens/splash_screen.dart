import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../common/widgets/custom_scaffold/app_scaffold.dart'
    show AppScaffold, AppScaffoldConfig;
import '../../../../../common/widgets/ds/app_mark.dart';
import '../../../../../common/widgets/loading_dots.dart';
import '../../../../../core/layout/app_layout.dart';
import '../../../../../core/layout/app_layout_scope.dart';
import '../../../../../utils/constants/app_flow_constants.dart';
import '../../../../../utils/constants/design_constants.dart';
import '../../../../../utils/extensions/theme_extensions.dart';
import '../../../../../utils/helpers/app_strings.dart';

/// The first Flutter screen.
///
/// It fills the moment between the OS splash and the app, while the app reads
/// the session, the onboarding flag and — behind it — the first tab's data
/// (`BlocPreloader`).
///
/// - **The mark rises in here, not in the native splash.** The native splash
///   (`flutter_native_splash.yaml`) is the bare background colour, and this
///   screen draws on the SAME colour, so the hand-over is invisible; a mark
///   in the native splash would appear, vanish and build itself again.
///   `AppMark` is sized to the window class (72 · 96 · 112).
/// - The name and the tagline rise in, then three pulsing dots.
/// - The entrance clock starts once the first frame is out — started in
///   `initState` it would run under the OS splash (which only fades once the
///   first frame is up) and appear half done.
/// - Reduced motion: a plain fade.
/// - The router leaves it after [SplashConfig.initialDelay] at the earliest
///   and [SplashConfig.maxWait] at the latest; nothing here navigates.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String pagePath = '/splash';
  static const String pageName = 'SplashScreen';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashConfig.entrance,
  );

  /// The name first, then the tagline, then the dots — never more than two
  /// things moving at once.
  late final Animation<double> _name = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: AppCurves.reveal),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 0.85, curve: AppCurves.enter),
  );
  late final Animation<double> _dots = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 1, curve: AppCurves.enter),
  );

  bool _entranceScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceScheduled) return;
    _entranceScheduled = true;

    // Add `precacheImage(...)` futures here if you put pictures on the
    // splash, so they are decoded before the clock starts.
    unawaited(
      WidgetsBinding.instance.endOfFrame.then((_) {
        if (mounted) _controller.forward();
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AppScaffold.body(
      // The splash paints edge to edge: the OS splash it replaces has no safe
      // area either, so honouring one here would shift the content on
      // handover.
      scaffoldConfig: AppScaffoldConfig(
        backgroundColor: context.semantic.background,
      ),
      child: Stack(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // The mark rises with the name, sized to the window: 72
                  // on a phone, 96 at medium width, 112 from 840dp.
                  _Rise(
                    animation: _name,
                    reducedMotion: reducedMotion,
                    distance: 16,
                    startScale: 0.94,
                    child: AppMark(
                      size: switch (AppLayoutScope.maybeOf(
                        context,
                      )?.windowSize) {
                        null || WindowSize.compact => 72,
                        WindowSize.medium => 96,
                        _ => 112,
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Rise(
                    animation: _name,
                    reducedMotion: reducedMotion,
                    distance: 16,
                    startScale: 0.94,
                    child: Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Rise(
                    animation: _tagline,
                    reducedMotion: reducedMotion,
                    child: Text(
                      AppStrings.appTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.huge + MediaQuery.viewPaddingOf(context).bottom,
            child: _Rise(
              animation: _dots,
              reducedMotion: reducedMotion,
              child: Center(
                child: Semantics(
                  label: AppStrings.appLoading,
                  liveRegion: true,
                  // `container: true` is load-bearing: LoadingDots produces
                  // no semantics of its own, so without it this label would
                  // merge into the app name and never be announced.
                  container: true,
                  child: LoadingDots(color: colors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades a block in while lifting it a few pixels (and optionally growing
/// it); a plain fade under reduced motion.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.animation,
    required this.child,
    required this.reducedMotion,
    this.distance = 10,
    this.startScale = 1,
  });

  final Animation<double> animation;
  final Widget child;
  final bool reducedMotion;
  final double distance;
  final double startScale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        final opacity = t.clamp(0.0, 1.0);
        if (reducedMotion) return Opacity(opacity: opacity, child: child);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * distance),
            child: Transform.scale(
              scale: startScale + (1 - startScale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
