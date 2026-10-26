import 'package:flutter/foundation.dart';

/// What the app runs on, named after what the code needs to know.
///
/// The one place for platform checks (`docs/RESPONSIVE.md`):
///
/// - **Layout never branches here.** A desktop window can be phone-narrow and
///   an iPad window can be half a screen; layout reads the window size from
///   `AppLayout`.
/// - **Capabilities do.** A plugin that ships no code for a platform still
///   builds there — calling it throws `MissingPluginException` — so every
///   call into a mobile-only or desktop-only plugin sits behind a getter
///   below, named after the capability, not the device.
///
/// `defaultTargetPlatform` rather than `dart:io`'s `Platform`: it compiles on
/// the web, and a widget test can pretend to be another platform with
/// `debugDefaultTargetPlatformOverride`.
abstract final class AppPlatform {
  static bool get isWeb => kIsWeb;

  static bool get isAndroid => _is(TargetPlatform.android);

  static bool get isIOS => _is(TargetPlatform.iOS);

  static bool get isWindows => _is(TargetPlatform.windows);

  static bool get isMacOS => _is(TargetPlatform.macOS);

  static bool get isLinux => _is(TargetPlatform.linux);

  /// A phone or a tablet.
  static bool get isMobile => isAndroid || isIOS;

  /// A desktop OS. The window it draws into can be any size.
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// The app owns a resizable OS window with a title bar (window_manager).
  static bool get hasDesktopWindow => isDesktop;

  /// `vibration` ships Android and iOS code only.
  static bool get supportsVibration => isMobile;

  /// `permission_handler` has no macOS or Linux implementation; on desktop
  /// the notification permission comes from flutter_local_notifications.
  static bool get supportsPermissionHandler => isMobile || isWindows;

  /// Firebase Cloud Messaging. firebase_messaging has no Windows code, and
  /// the template keeps push to Android and iOS (`docs/DESKTOP_SETUP.md`).
  static bool get supportsPush => isMobile;

  /// The system font draws country-flag emoji. Windows and Linux fonts do
  /// not — they print the two letters of the code («EG») — and neither does a
  /// browser on them, so flags there are pictures instead.
  static bool get rendersFlagEmoji => isAndroid || isIOS || isMacOS;

  /// The OS draws a native splash before Flutter's first frame.
  /// flutter_native_splash generates Android, iOS and web only.
  static bool get hasNativeSplash => isMobile || isWeb;

  static bool _is(TargetPlatform platform) =>
      !kIsWeb && defaultTargetPlatform == platform;
}
