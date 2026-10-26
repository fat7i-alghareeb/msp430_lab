import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' show EdgeInsets;

/// Spacing scale — `DESIGN_SYSTEM.md`.
///
/// A 4dp grid. Allowed values only:
/// `2 · 4 · 6 · 8 · 10 · 12 · 16 · 20 · 24 · 32 · 40 · 48`.
class AppSpacing {
  AppSpacing._();

  /// 2 — hairline gaps.
  static const double xxs = 2;

  /// 4 — between a badge and its text.
  static const double xs = 4;

  /// 6 — chip separator.
  static const double xs2 = 6;

  /// 8 — between elements inside a row; **between two cards in a list**.
  static const double sm = 8;

  /// 10 — floating nav bar side inset.
  static const double sm2 = 10;

  /// 12 — inner card padding; **between a section title and its content**.
  static const double md = 12;

  /// 16 — **the horizontal screen margin**, always; large card padding.
  static const double lg = 16;

  /// 20 — dialog padding.
  static const double lg2 = 20;

  /// 24 — **between one section and the next**.
  static const double xl = 24;

  /// 32 — before a new major section.
  static const double xxl = 32;

  /// 40
  static const double xxxl = 40;

  /// 48
  static const double huge = 48;

  /// The horizontal screen margin. 16dp, not negotiable.
  static const double screenMargin = lg;

  /// Gap between two cards in a vertical list.
  static const double cardGap = sm;

  /// Gap between a section header and its content.
  static const double sectionHeaderGap = md;

  /// Gap before a new section starts.
  static const double sectionGap = xl;

  static const EdgeInsets horizontal = EdgeInsets.symmetric(
    horizontal: screenMargin,
  );
  static const EdgeInsets vertical = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets standardPadding = EdgeInsets.symmetric(
    horizontal: screenMargin,
    vertical: lg,
  );

  /// Inner padding of a card.
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}

/// Corner radii — `DESIGN_SYSTEM.md`.
///
/// **No radius outside this scale.** When one shape nests inside another, the
/// inner radius is the outer radius minus 4.
class AppRadii {
  AppRadii._();

  /// 7 — badges.
  static const double xs = 7;

  /// 12 — compact icon buttons.
  static const double sm = 12;

  /// 14 — images inside cards, search field, buttons.
  static const double md = 14;

  /// 18 — **cards**, dialogs.
  static const double lg = 18;

  /// 20 — the floating bottom navigation bar.
  static const double xl = 20;

  /// 22 — bottom sheets (top corners only).
  static const double sheet = 26;

  /// 999 — chips, avatars, pills.
  static const double full = 999;

  /// Radius of a shape nested inside one with [outer].
  static double nestedIn(double outer) {
    final inner = outer - 4;
    return inner < xs ? xs : inner;
  }
}

/// Border widths — `DESIGN_SYSTEM.md`.
class AppBorders {
  AppBorders._();

  /// 1 — list dividers, ghost buttons.
  static const double hairline = 1;

  /// 1.5 — focused and errored input fields.
  static const double emphasis = 1.5;

  /// 2 — keyboard focus ring.
  static const double focusRing = 2;

  /// Offset of the keyboard focus ring from the element.
  static const double focusRingOffset = 2;
}

/// Icon sizes — `DESIGN_SYSTEM.md`.
class AppIconSizes {
  AppIconSizes._();

  /// 16 — inline with text.
  static const double inline = 16;

  /// 20 — list rows.
  static const double list = 20;

  /// 24 — app bar and navigation.
  static const double bar = 24;

  /// 28 — empty states.
  static const double emptyState = 28;

  /// Minimum touch target, regardless of icon size.
  static const double minTouchTarget = 44;

  /// Minimum touch target for bottom-navigation items.
  static const double navTouchTarget = 48;

  /// Stroke width of the icon set.
  static const double strokeWidth = 1.7;
}

/// Animation durations — `DESIGN_SYSTEM.md`.
///
/// Rule: **exit is ~70% of enter.**
class AppDurations {
  AppDurations._();

  /// 90ms — pressing a button or a card.
  static const Duration press = Duration(milliseconds: 90);

  /// 150ms — toggling a chip or a bookmark.
  static const Duration toggle = Duration(milliseconds: 150);

  /// 260ms — a bottom sheet appearing.
  static const Duration sheetIn = Duration(milliseconds: 260);

  /// 180ms — a bottom sheet dismissing.
  static const Duration sheetOut = Duration(milliseconds: 180);

  /// 280ms — pushing a screen.
  static const Duration routeIn = Duration(milliseconds: 280);

  /// 200ms — popping a screen.
  static const Duration routeOut = Duration(milliseconds: 200);

  /// 220ms — list items appearing.
  static const Duration listItem = Duration(milliseconds: 220);

  /// 45ms — stagger between consecutive list items.
  static const Duration listStagger = Duration(milliseconds: 45);

  /// 220ms — the two tabs dissolve into each other, nothing moving. What
  /// says «another tab» is the pill sliding in the bar, not the page.
  static const Duration tabSwitch = Duration(milliseconds: 220);

  /// 340ms — the pill behind the active tab sliding to the new one.
  static const Duration tabPill = Duration(milliseconds: 340);

  /// 220ms — the bar shows the new tab this long before the page changes,
  /// when a page asked for it: the eye is on the bar first.
  static const Duration tabHandoff = Duration(milliseconds: 220);

  /// 1400ms — the «Now in …» toast above the bar.
  static const Duration tabToast = Duration(milliseconds: 1400);

  /// 450ms — a list item growing and rising into view as it scrolls in
  /// (`ScrollReveal`). Between «balanced» (380) and «expressive» (520).
  static const Duration scrollReveal = Duration(milliseconds: 450);

  /// 100ms — the fade that replaces motion when animations are disabled.
  static const Duration reducedMotion = Duration(milliseconds: 100);

  /// 1500ms — one shimmer cycle.
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// 3000ms — how long a SnackBar stays.
  static const Duration snackBar = Duration(milliseconds: 3000);

  /// Below this, no loading indicator is shown at all (avoids flicker).
  static const Duration loaderThreshold = Duration(milliseconds: 300);

  /// Duration for theme transitions.
  static const Duration themeAnimation = Duration(milliseconds: 300);

  /// Fast UI feedback.
  static const Duration fast = Duration(milliseconds: 150);

  /// Very fast UI feedback.
  static const Duration veryFast = press;

  /// Default duration for most UI transitions.
  static const Duration normal = Duration(milliseconds: 250);

  /// Longer transitions.
  static const Duration slow = Duration(milliseconds: 350);
}

/// Curves — `DESIGN_SYSTEM.md`.
class AppCurves {
  AppCurves._();

  /// Pressing.
  static const Curve press = Curves.easeOut;

  /// State toggles.
  static const Curve toggle = Curves.easeInOut;

  /// Anything entering the screen.
  static const Curve enter = Curves.easeOutCubic;

  /// Anything leaving it.
  static const Curve exit = Curves.easeInCubic;

  /// Theme and other major transitions.
  static const Curve theme = Curves.easeInOut;

  /// Content arriving on scroll: decelerates with a whisker of overshoot, so
  /// an item settles rather than stops.
  static const Curve reveal = Cubic(0.2, 1.08, 0.36, 1);

  /// Springy arrivals — tiles popping, a button appearing.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);
}

/// Interaction-state values — `DESIGN_SYSTEM.md`.
class AppStates {
  AppStates._();

  /// Pressed: 4% darken.
  static const double pressedOverlay = 0.04;

  /// Pressed: scale down to 0.98 (0.985 for cards).
  static const double pressedScale = 0.98;

  /// Cards sink 3.5% and lift their shadow on press, then spring back.
  static const double pressedScaleCard = 0.965;

  /// Disabled opacity.
  static const double disabled = 0.38;

  /// A row that is shown but cannot be changed — the mandatory
  /// notifications. Dimmer than live text, and
  /// deliberately lighter than [disabled]: the reader is meant to READ it,
  /// not to skip it.
  static const double dimmedRow = 0.6;

  /// Hover — wherever there is a pointer: desktop, and a tablet with a
  /// mouse or trackpad. Touch has no hover.
  static const double hoverOverlay = 0.03;

  /// Ink splash tint on a card.
  static const double cardInk = 0.06;
}
