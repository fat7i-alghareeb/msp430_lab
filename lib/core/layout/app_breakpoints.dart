/// Material 3 window size classes — the widths where the layout changes.
///
/// Window widths, not device widths: an iPad window in Stage Manager or a
/// desktop window dragged narrow moves down a class
/// (`docs/RESPONSIVE.md`).
///
/// ```text
///  compact      medium      expanded       large        extra-large
///  0 ───── 600 ────── 840 ─────── 1200 ────── 1600 ──────────▶ width
///  phones       iPad port.  iPad land.     big tablets  monitors
/// ```
abstract final class AppBreakpoints {
  /// From here the window is medium: a rail replaces the bottom bar.
  static const double medium = 600;

  /// From here the window is expanded: the sidebar shows its labels, and
  /// lists sit beside their detail.
  static const double expanded = 840;

  static const double large = 1200;

  static const double extraLarge = 1600;

  /// Below this height the window is compact-height — every phone in
  /// landscape — and the navigation moves to the side.
  static const double compactHeight = 480;

  static const double expandedHeight = 900;

  /// The physical display's shortest side from which a phone-or-tablet
  /// device counts as a tablet. Device type only; layout never reads it.
  static const double tabletShortestSide = 600;
}
