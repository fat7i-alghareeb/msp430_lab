import 'dart:ui' show Display, Size;

import 'package:flutter/foundation.dart';

import '../platform/app_platform.dart';
import 'app_breakpoints.dart';

/// What the hardware is. Drives platform habits — a title bar, hover,
/// shortcuts — never the layout.
enum DeviceType { phone, tablet, desktop }

/// How much width the window has: Material 3's window size classes.
enum WindowSize {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  static WindowSize fromWidth(double width) {
    if (width < AppBreakpoints.medium) return compact;
    if (width < AppBreakpoints.expanded) return medium;
    if (width < AppBreakpoints.large) return expanded;
    if (width < AppBreakpoints.extraLarge) return large;
    return extraLarge;
  }

  bool isAtLeast(WindowSize other) => index >= other.index;
}

/// How much height the window has.
enum HeightClass {
  compact,
  medium,
  expanded;

  static HeightClass fromHeight(double height) {
    if (height < AppBreakpoints.compactHeight) return compact;
    if (height < AppBreakpoints.expandedHeight) return medium;
    return expanded;
  }
}

/// Where the app's top-level destinations are shown.
enum NavLayout {
  /// The floating capsule at the bottom — compact windows.
  bar,

  /// An 80dp column of icons with small labels — medium windows, and any
  /// compact-height window (a phone in landscape).
  rail,

  /// The expanded rail with labels — expanded windows and wider. Material 3
  /// Expressive's replacement for the navigation drawer.
  sidebar,
}

/// The screen this frame is drawn on: device type and window size classes.
///
/// Built once per frame by `AppLayoutHost` from `MediaQuery.sizeOf`, which
/// already holds the window's size in the very first frame — so the first
/// frame is laid out right, and a rotation or a window resize is picked up in
/// the same frame it happens. Read it through `context.layout`,
/// `AppLayoutScope.windowSizeOf` or `AdaptiveLayout`.
///
/// Compared by value: rebuilding the scope with an equal layout notifies
/// nobody.
@immutable
class AppLayout {
  const AppLayout({
    required this.deviceType,
    required this.windowSize,
    required this.heightClass,
    required this.size,
  });

  /// The layout for a window of [size] on a [deviceType].
  factory AppLayout.resolve({
    required Size size,
    required DeviceType deviceType,
  }) {
    return AppLayout(
      deviceType: deviceType,
      windowSize: WindowSize.fromWidth(size.width),
      heightClass: HeightClass.fromHeight(size.height),
      size: size,
    );
  }

  /// The device type from the platform and the PHYSICAL display — one of
  /// the few places the display, not the window, is right: an iPad running
  /// the app in a narrow window is still an iPad.
  static DeviceType deviceTypeOf({Display? display}) {
    if (AppPlatform.isDesktop) return DeviceType.desktop;
    if (display == null || display.devicePixelRatio == 0) {
      return DeviceType.phone;
    }
    final shortest = display.size.shortestSide / display.devicePixelRatio;
    return shortest >= AppBreakpoints.tabletShortestSide
        ? DeviceType.tablet
        : DeviceType.phone;
  }

  final DeviceType deviceType;
  final WindowSize windowSize;
  final HeightClass heightClass;

  /// The window size in logical pixels.
  final Size size;

  bool get isDesktop => deviceType == DeviceType.desktop;

  bool get isCompact => windowSize == WindowSize.compact;

  bool get isMedium => windowSize == WindowSize.medium;

  /// Expanded or wider: room for a list beside its detail.
  bool get isExpandedUp => windowSize.isAtLeast(WindowSize.expanded);

  /// Compact height — a phone in landscape.
  bool get isShort => heightClass == HeightClass.compact;

  bool get isLandscape => size.width > size.height;

  /// Where the destinations go (`docs/RESPONSIVE.md`).
  ///
  /// A compact-height window — every phone held sideways, 844 wide or not —
  /// always gets the rail: a sidebar with labels would eat the height it
  /// does not have, and the capsule would cover a third of it.
  NavLayout get nav {
    if (isShort) return NavLayout.rail;
    return switch (windowSize) {
      WindowSize.compact => NavLayout.bar,
      WindowSize.medium => NavLayout.rail,
      _ => NavLayout.sidebar,
    };
  }

  /// The side margin of a screen: 16 · 24 · 32.
  double get gutter => switch (windowSize) {
    WindowSize.compact => 16,
    WindowSize.medium => 24,
    _ => 32,
  };

  /// The widest content runs, centred beyond it.
  static const double contentMaxWidth = 1200;

  /// Reading width for long text and single-column screens.
  static const double readableMaxWidth = 640;

  /// Columns for a grid of cards [width] wide: 1 → 2 → 3.
  static int columnsFor(double width) {
    if (width >= 900) return 3;
    if (width >= 540) return 2;
    return 1;
  }

  @override
  bool operator ==(Object other) =>
      other is AppLayout &&
      other.deviceType == deviceType &&
      other.windowSize == windowSize &&
      other.heightClass == heightClass &&
      other.size == size;

  @override
  int get hashCode => Object.hash(deviceType, windowSize, heightClass, size);

  @override
  String toString() =>
      'AppLayout(${deviceType.name}, ${windowSize.name}, '
      'height ${heightClass.name}, ${size.width.round()}×${size.height.round()})';
}
