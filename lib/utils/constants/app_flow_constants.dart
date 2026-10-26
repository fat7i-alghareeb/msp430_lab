import '../../core/platform/app_platform.dart';

/// How long the splash holds, in total: the entrance plus a short rest.
class SplashConfig {
  SplashConfig._();

  /// The mark's entrance animation.
  static const Duration entrance = Duration(milliseconds: 950);

  /// How long the finished splash is held before the app moves on.
  static const Duration holdAfterEntrance = Duration(milliseconds: 800);

  /// Phones hold the splash while the first frame settles. A desktop window
  /// already waited for its first frame, so it does not hold.
  static Duration get initialDelay =>
      AppPlatform.hasDesktopWindow ? Duration.zero : _mobileInitialDelay;
  static const Duration _mobileInitialDelay = Duration(milliseconds: 1750);
}

/// Log tags for the router.
class RouterLogTags {
  RouterLogTags._();

  static const String router = '[Router]';
  static const String redirect = '[RouterRedirect]';
}
