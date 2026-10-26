import 'package:flutter/material.dart';

import '../../common/widgets/ds/app_icons.dart';
import '../../core/layout/app_layout.dart';
import '../../core/platform/app_platform.dart';
import '../../core/layout/app_layout_scope.dart';

/// Layout and focus utilities for [BuildContext].
///
/// Example:
/// ```dart
/// final w = context.screenWidth;
/// final h = context.screenHeight;
/// if (context.isSmallHeight) { ... }
/// context.unfocus();
/// ```
extension AppContextExtensions on BuildContext {
  EdgeInsets get paddingOf => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsetsOf => MediaQuery.viewInsetsOf(this);

  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  double get topPadding => paddingOf.top;

  double get bottomPadding => paddingOf.bottom;

  double get bottomInset => viewInsetsOf.bottom;

  bool get isSmallHeight => screenHeight < 650;

  /// Device type and window size classes for this frame
  /// (`docs/RESPONSIVE.md`). Rebuilds on any change of the window size; to
  /// rebuild only when the CLASS changes, use
  /// `AppLayoutScope.windowSizeOf(context)`.
  AppLayout get layout => AppLayoutScope.of(this);

  /// The device is a tablet — a hardware question, for platform habits.
  /// Layout reads `layout.windowSize` instead: an iPad window can be
  /// phone-narrow.
  bool get isTablet =>
      (AppLayoutScope.maybeOf(this)?.deviceType ??
          AppLayout.deviceTypeOf(display: View.maybeOf(this)?.display)) ==
      DeviceType.tablet;

  /// How far a toolbar's LEADING buttons must move in so iPadOS's window
  /// controls (the three dots and the resize handle it draws at the leading
  /// edge of a windowed app, Apple's HIG «Windows») do not cover them.
  ///
  /// iPadOS draws them when the app is in a window rather than full screen,
  /// which shows up as a window smaller than the display. Split View is
  /// treated the same way: it has no such controls, and the extra gap there
  /// is harmless. Zero on every other device. *Check on a real iPad running
  /// iPadOS 26* — the amount is Apple's, not measured here.
  double get leadingWindowControlsInset {
    if (!AppPlatform.isIOS) return 0;
    final display = View.maybeOf(this)?.display;
    if (display == null || display.devicePixelRatio == 0) return 0;
    final screen = display.size / display.devicePixelRatio;
    final window = screenSize;
    final windowed =
        window.width < screen.width - 1 || window.height < screen.height - 1;
    return windowed ? windowControlsWidth : 0;
  }

  /// The width iPadOS reserves for its window controls.
  static const double windowControlsWidth = 72;

  void unfocus() {
    final scope = FocusScope.of(this);
    if (scope.hasFocus) {
      scope.unfocus();
    }
  }

  /// 🚨 Aggressive unfocus
  /// Clears focus history and prevents restoration
  void unfocusHard() {
    FocusScope.of(this).requestFocus(FocusNode());
  }

  bool get hasFocus => FocusScope.of(this).hasFocus;

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  bool get isLtr => !isRtl;

  /// The chevron pointing at the START edge — back, previous. The app's own
  /// Lucide glyph (an [AppIcons] asset for `AppIcon`), never a fixed
  /// left or right: a fixed glyph points backwards in one of the two
  /// languages, and `AppIcon` does not mirror.
  String get chevronStart =>
      isRtl ? AppIcons.chevronRight : AppIcons.chevronLeft;

  /// The chevron pointing at the END edge — forward, «عرض الكل», a row that
  /// opens a screen.
  String get chevronEnd => isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight;
}
