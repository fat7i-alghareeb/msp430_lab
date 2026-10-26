import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/layout/app_layout.dart';
import '../../../../../../core/layout/app_layout_scope.dart';
import '../../../../../../utils/helpers/app_strings.dart';

import '../../../../../../common/widgets/ds/app_icons.dart';
import '../../../../../../utils/constants/design_constants.dart';
import '../../../../../../utils/helpers/app_formats.dart';
import '../../../../../../utils/extensions/theme_extensions.dart';
import '../../../../../../common/widgets/nav_bar_visibility.dart';
import 'navigation_controller.dart';

/// One destination in [AppBottomNav] and the side navigation.
@immutable
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.label,
    this.badge,
  });

  /// A constant from [AppIcons].
  final String icon;

  final String label;

  /// An unread count, shown as text on the rail and the sidebar — never
  /// colour alone. Zero or null shows nothing.
  final ValueListenable<int>? badge;
}

/// The floating navigation capsule.
///
/// Equal destinations (up to five), in reading order — they flip with the
/// language on their own. Every item carries an icon AND a label.
///
/// The active item is marked by **colour and weight together**, never colour
/// alone.
///
/// **On scroll** the capsule MORPHS into a
/// small dock — the current tab's icon and a dot for each other tab — and
/// grows back out of it. A tap or a swipe up on the dock brings the bar back.
/// Driven by a [NavBarVisibility]; with none, the bar never hides.
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    super.key,
    required this.controller,
    required this.destinations,
    this.visibility,
  });

  final NavigationController controller;
  final List<AppNavDestination> destinations;

  /// Hides the bar into the dock while the tabs scroll down.
  final NavBarVisibility? visibility;

  /// 64, raised from 52 with the sliding pill: the pill
  /// holds the icon AND its word with room around them.
  static const double barHeight = 64;

  /// 44 on a short (landscape) screen, where the glyph and its word sit
  /// side by side — raised from 38 for the same reason.
  static const double shortBarHeight = 44;

  static const double sideMargin = AppSpacing.sm2;
  static const double bottomMargin = 9;

  static const double maxWidth = 520;

  /// The dock the bar becomes: wide enough for an icon and three dots, and
  /// tall enough to be tapped.
  static const double dockWidth = 104;
  static const double dockHeight = 44;

  /// 320ms — the app's usual pace.
  static const Duration morphDuration = Duration(milliseconds: 320);

  /// Where the pill sits inside a tab's slot — and so where a tab's ripple
  /// is drawn, so a press lights up exactly the pill's shape.
  static EdgeInsets pillInsets({required bool isCompact}) =>
      EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: isCompact ? AppSpacing.xs : AppSpacing.xs2,
      );

  static bool isShort(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 500;

  static double heightOf(BuildContext context) =>
      isShort(context) ? shortBarHeight : barHeight;

  /// What the last row of a tab's list must leave free at the bottom.
  ///
  /// The floating capsule only exists in compact windows; with the rail or
  /// the sidebar the list just keeps clear of the home indicator.
  static double listBottomPadding(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final layout = AppLayoutScope.maybeOf(context);
    if (layout != null && layout.nav != NavLayout.bar) {
      return AppSpacing.lg + inset;
    }
    return AppSpacing.lg + heightOf(context) + bottomMargin + inset;
  }

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: AppBottomNav.morphDuration,
    value: widget.visibility?.hidden ?? false ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    widget.visibility?.addListener(_sync);
  }

  @override
  void didUpdateWidget(AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.visibility, widget.visibility)) {
      oldWidget.visibility?.removeListener(_sync);
      widget.visibility?.addListener(_sync);
      _sync();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _morph.duration = reduced
        ? const Duration(milliseconds: 1)
        : AppBottomNav.morphDuration;
  }

  void _sync() {
    final hidden = widget.visibility?.hidden ?? false;
    if (hidden) {
      _morph.forward();
    } else {
      _morph.reverse();
    }
  }

  @override
  void dispose() {
    widget.visibility?.removeListener(_sync);
    _morph.dispose();
    super.dispose();
  }

  void _showBar() => widget.visibility?.show();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDarkTheme;
    final isCompact = AppBottomNav.isShort(context);
    final barHeight = AppBottomNav.heightOf(context);

    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final count = widget.destinations.length;

    final items = ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final active = widget.controller.barIndex.clamp(0, count - 1);
        return Stack(
          children: <Widget>[
            // The pill behind the active tab, sliding to the next one: the
            // bar is what says «another
            // tab», while the page only cross-fades. Directional, so it
            // follows the reading order on its own.
            Positioned.fill(
              child: AnimatedAlign(
                alignment: AlignmentDirectional(
                  count == 1 ? 0 : -1 + 2 * active / (count - 1),
                  0,
                ),
                duration: reduced ? Duration.zero : AppDurations.tabPill,
                curve: AppCurves.spring,
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: Padding(
                    padding: AppBottomNav.pillInsets(isCompact: isCompact),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              // Each tab fills the bar's height, like the pill behind it.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: _NavItem(
                      destination: widget.destinations[i],
                      // The bar may run ahead of the page.
                      isActive: active == i,
                      position: i + 1,
                      total: widget.destinations.length,
                      isCompact: isCompact,
                      onTap: () => widget.controller.setIndex(i),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppBottomNav.sideMargin,
        end: AppBottomNav.sideMargin,
        bottom:
            AppBottomNav.bottomMargin +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      // Centred and capped: across a landscape phone or a tablet the four
      // items would sit in the middle of an otherwise empty bar, their touch
      // targets a hand's width apart.
      child: Center(
        // `heightFactor: 1` so the capsule keeps its own height: a bare
        // `Center` takes every pixel the bar slot offers and floats the
        // capsule in the middle of the screen.
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBottomNav.maxWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final full = constraints.maxWidth;
              // The slot keeps the bar's full height while it morphs, so the
              // page underneath never re-lays itself out frame by frame.
              return SizedBox(
                height: barHeight,
                child: AnimatedBuilder(
                  animation: _morph,
                  builder: (context, _) {
                    final t = Curves.easeInOutCubic.transform(_morph.value);
                    final hidden = _morph.value > 0.5;
                    final width = _lerp(full, AppBottomNav.dockWidth, t);
                    final height = _lerp(
                      barHeight,
                      AppBottomNav.dockHeight.clamp(0, barHeight),
                      t,
                    );
                    final radius = BorderRadius.circular(
                      _lerp(AppRadii.xl, height / 2, t),
                    );
                    // The words leave first; the dock arrives after them.
                    final itemsOpacity = 1 - _interval(t, 0, 0.45);
                    final dockOpacity = _interval(t, 0.5, 1);

                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: radius,
                            // Shadow in light, hairline border in dark —
                            // never both.
                            boxShadow: context.shadows.nav,
                            border: isDark
                                ? Border.all(color: colors.outline)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: radius,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                // The row keeps its full width and is clipped
                                // as the capsule narrows, rather than being
                                // squeezed into overflowing words.
                                // Built only while it can be seen, so a
                                // tucked bar leaves no words behind.
                                if (_morph.value < 1)
                                  ExcludeSemantics(
                                    excluding: hidden,
                                    child: IgnorePointer(
                                      ignoring: t > 0,
                                      child: Opacity(
                                        opacity: itemsOpacity,
                                        child: OverflowBox(
                                          minWidth: full,
                                          maxWidth: full,
                                          minHeight: barHeight,
                                          maxHeight: barHeight,
                                          child: items,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_morph.value > 0)
                                  ExcludeSemantics(
                                    excluding: !hidden,
                                    child: IgnorePointer(
                                      ignoring: !hidden,
                                      child: Opacity(
                                        opacity: dockOpacity,
                                        child: _Dock(
                                          controller: widget.controller,
                                          destinations: widget.destinations,
                                          onShow: _showBar,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _interval(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);
}

/// The bar, tucked away: the current tab's icon and a dot for each other
/// tab. A tap or a swipe up brings the bar back.
class _Dock extends StatelessWidget {
  const _Dock({
    required this.controller,
    required this.destinations,
    required this.onShow,
  });

  final NavigationController controller;
  final List<AppNavDestination> destinations;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Semantics(
      button: true,
      label: AppStrings.navShow,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onShow,
        onVerticalDragUpdate: (d) {
          if (d.delta.dy < -4) onShow();
        },
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final active = controller.barIndex.clamp(
              0,
              destinations.length - 1,
            );
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AppIcon(destinations[active].icon, color: colors.primary),
                const SizedBox(width: AppSpacing.sm2),
                for (var i = 0; i < destinations.length; i++)
                  if (i != active)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsetsDirectional.symmetric(
                        horizontal: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isActive,
    required this.position,
    required this.total,
    required this.onTap,
    this.isCompact = false,
  });

  final AppNavDestination destination;
  final bool isActive;
  final int position;
  final int total;
  final VoidCallback onTap;

  /// On a short screen the glyph and its word sit side by side, so the bar
  /// costs 38dp of height instead of 52.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // On the pill the active tab takes the pill's own ink.
    final color = isActive
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isActive,
      label: destination.label,
      // A screen reader should hear «2 من 4», which a plain Row does not give.
      // Through `AppFormats`, never the raw ints: a template takes the numerals
      // it is handed, and Latin ones inside an Arabic sentence are what a
      // reader would hear.
      value: AppStrings.a11yPositionOf(
        AppFormats.number(context, position),
        AppFormats.number(context, total),
      ),
      excludeSemantics: true,
      // Its own `Material`, so the ink has a sheet wherever the bar is put —
      // a screen with no scaffold of its own, a sheet, a test. The rule the
      // rest of the app follows; the bar was the one place still relying on
      // an ancestor it does not own.
      // The ripple takes the pill's shape and place.
      child: Padding(
        padding: AppBottomNav.pillInsets(isCompact: isCompact),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              // The glyph is 20dp; the target must still reach 48 wide. Its
              // HEIGHT is the bar's on a short screen — 38 there, and the bar is
              // the last thing that should take height from a landscape page.
              constraints: BoxConstraints(
                minHeight: isCompact
                    ? AppBottomNav.shortBarHeight
                    : AppIconSizes.navTouchTarget,
                minWidth: AppIconSizes.navTouchTarget,
              ),
              child: _NavItemContent(
                isCompact: isCompact,
                icon: AnimatedScale(
                  scale: isActive ? 1.06 : 1,
                  duration: AppDurations.toggle,
                  curve: AppCurves.toggle,
                  child: AppIcon(destination.icon, color: color),
                ),
                label: AnimatedDefaultTextStyle(
                  duration: AppDurations.toggle,
                  curve: AppCurves.toggle,
                  style: (theme.textTheme.labelSmall ?? const TextStyle())
                      .copyWith(
                        color: color,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The glyph over its word, or beside it on a short screen.
///
/// Both carry icon AND label — no icon-only bar — and the active item is
/// still marked by colour and weight together.
class _NavItemContent extends StatelessWidget {
  const _NavItemContent({
    required this.isCompact,
    required this.icon,
    required this.label,
  });

  final bool isCompact;
  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    if (!isCompact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          icon,
          const SizedBox(height: 3),
          // Flexible, not fixed: at a large text scale the word is taller
          // than the capsule leaves for it, and a `Column` with no give
          // overflows rather than letting the line settle.
          Flexible(child: label),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        icon,
        const SizedBox(width: AppSpacing.xs2),
        // The word gives way before the row overflows: four labels side by
        // side on a narrow landscape screen are tighter than four stacked.
        Flexible(child: label),
      ],
    );
  }
}
