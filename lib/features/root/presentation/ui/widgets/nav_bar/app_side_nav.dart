import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../../common/widgets/ds/app_count_badge.dart';
import '../../../../../../common/widgets/ds/app_focus_ring.dart';
import '../../../../../../common/widgets/ds/app_icons.dart';
import '../../../../../../common/widgets/ds/app_mark.dart';
import '../../../../../../common/widgets/ds/app_search_field.dart';
import '../../../../../../core/config/app_config.dart';
import '../../../../../../core/injection/injectable.dart';
import '../../../../../../utils/constants/design_constants.dart';
import '../../../../../../utils/extensions/theme_extensions.dart';
import '../../../../../../utils/helpers/app_formats.dart';
import '../../../../../../utils/helpers/app_strings.dart';
import 'app_bottom_nav.dart';
import 'navigation_controller.dart';
import 'side_nav_controller.dart';

/// Which optional parts the side navigation shows (`docs/RESPONSIVE.md`).
@immutable
class AppSideNavConfig {
  const AppSideNavConfig({
    this.showBrand = true,
    this.showSearch = true,
    this.showGroups = true,
    this.showSettings = false,
    this.collapsible = true,
  });

  /// The app mark, and its name when expanded.
  final bool showBrand;

  /// A search field — only when expanded and when no title bar carries one.
  final bool showSearch;

  /// «Browse» / «More» headings between the destinations and Settings.
  final bool showGroups;

  /// Settings pinned at the bottom.
  final bool showSettings;

  /// A button that collapses the sidebar to a rail (and Ctrl/⌘+B).
  final bool collapsible;
}

/// The side navigation: an 80dp rail, or a 256dp sidebar with labels.
///
/// Material 3 Expressive's navigation rail, collapsed and expanded — the
/// expanded rail is what replaced the navigation drawer. Drawn as a
/// floating card, inset from the edges with the capsule's radius and shadow,
/// so the bar a phone shows and the rail a tablet shows read as one family.
///
/// The active destination is marked by the pill AND bold text, never colour
/// alone. On a short window (a phone in landscape) only the destinations
/// stay; everything else would push them off the screen.
class AppSideNav extends StatelessWidget {
  const AppSideNav({
    super.key,
    required this.controller,
    required this.destinations,
    required this.extended,
    this.config = const AppSideNavConfig(),
    this.short = false,
    this.onSearch,
    this.onSettings,
  });

  final NavigationController controller;
  final List<AppNavDestination> destinations;

  /// The sidebar with labels beside the icons; otherwise the rail.
  final bool extended;
  final AppSideNavConfig config;

  /// A compact-height window: destinations only.
  final bool short;

  /// Runs a search typed into the sidebar's field.
  final ValueChanged<String>? onSearch;
  final VoidCallback? onSettings;

  /// The rail's width, the M3 default.
  static const double railWidth = 80;

  /// The sidebar's width, Flutter's `NavigationRail.minExtendedWidth`.
  static const double sidebarWidth = 256;

  /// The inset that makes it float.
  static const double margin = AppSpacing.sm;

  /// The width it takes from the window, margins included.
  static double widthOf({required bool extended}) =>
      (extended ? sidebarWidth : railWidth) + margin * 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDarkTheme;
    final sideNav = getIt.isRegistered<SideNavController>()
        ? getIt<SideNavController>()
        : null;

    final top = <Widget>[
      if (config.showBrand && !short) _Brand(extended: extended),
      if (extended && !short && config.showSearch && onSearch != null)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: AppSearchField(
            hintText: AppStrings.searchPlaceholder,
            onSubmitted: onSearch,
          ),
        ),
      if (extended && !short && config.showGroups)
        _GroupLabel(AppStrings.navGroupBrowse),
    ];

    final items = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final active = controller.barIndex.clamp(0, destinations.length - 1);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < destinations.length; i++)
              _SideNavItem(
                icon: destinations[i].icon,
                label: destinations[i].label,
                badge: destinations[i].badge,
                selected: i == active,
                extended: extended,
                short: short,
                onTap: () => controller.setIndex(i),
              ),
          ],
        );
      },
    );

    final bottom = <Widget>[
      if (extended && !short && config.showGroups && config.showSettings)
        _GroupLabel(AppStrings.actionMore),
      if (config.showSettings && !short)
        _SideNavItem(
          icon: AppIcons.settings,
          label: AppStrings.settingsTitle,
          selected: false,
          extended: extended,
          onTap: onSettings,
        ),
      if (config.collapsible && !short && sideNav != null)
        _SideNavItem(
          icon: AppIcons.panelLeft,
          label: extended ? AppStrings.navCollapse : AppStrings.navExpand,
          selected: false,
          extended: extended,
          quiet: true,
          showLabelInRail: false,
          onTap: sideNav.toggle,
        ),
    ];

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        // Shadow in light, hairline border in dark — never both.
        boxShadow: context.shadows.nav,
        border: isDark ? Border.all(color: colors.outline) : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: short ? AppSpacing.xs : AppSpacing.sm,
          horizontal: extended ? AppSpacing.sm : 0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[...top, items, const Spacer(), ...bottom],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.all(margin),
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: AppCurves.toggle,
          width: extended ? sidebarWidth : railWidth,
          child: card,
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = const AppMark();
    if (!extended) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Center(child: mark),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          mark,
          const SizedBox(width: AppSpacing.sm2),
          Expanded(
            child: Text(
              AppConfig.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs2,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.onTap,
    this.badge,
    this.short = false,
    this.quiet = false,
    this.showLabelInRail = true,
  });

  final String icon;
  final String label;
  final bool selected;
  final bool extended;
  final VoidCallback? onTap;
  final ValueListenable<int>? badge;
  final bool short;

  /// Secondary chrome (collapse): smaller text, never «selected».
  final bool quiet;
  final bool showLabelInRail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dense = theme.visualDensity.vertical < 0;
    final fg = selected ? colors.onPrimaryContainer : colors.onSurfaceVariant;
    final iconColor = selected ? colors.primary : colors.onSurfaceVariant;
    final textStyle =
        (quiet ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
            ?.copyWith(
              color: selected ? fg : colors.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );

    final badgeWidget = badge == null
        ? null
        : ValueListenableBuilder<int>(
            valueListenable: badge!,
            builder: (context, count, _) =>
                count <= 0 ? const SizedBox.shrink() : _Badge(count: count),
          );

    Widget content;
    if (extended) {
      content = SizedBox(
        height: dense ? 40 : AppIconSizes.navTouchTarget,
        child: AnimatedContainer(
          duration: AppDurations.toggle,
          curve: AppCurves.toggle,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Row(
            children: <Widget>[
              AppIcon(icon, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              ?badgeWidget,
            ],
          ),
        ),
      );
    } else {
      content = Padding(
        padding: EdgeInsets.symmetric(vertical: short ? 2 : AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                AnimatedContainer(
                  duration: AppDurations.toggle,
                  curve: AppCurves.toggle,
                  width: 56,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: AppIcon(
                    icon,
                    size: AppIconSizes.bar,
                    color: iconColor,
                  ),
                ),
                if (badgeWidget != null)
                  PositionedDirectional(top: -4, end: 4, child: badgeWidget),
              ],
            ),
            if (showLabelInRail) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? fg : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget item = Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: extended
              ? const StadiumBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
          child: content,
        ),
      ),
    );
    // Keyboard focus: the app's ring, never the overlay alone.
    item = AppFocusRing(
      borderRadius: BorderRadius.circular(
        extended ? AppRadii.full : AppRadii.md,
      ),
      child: item,
    );
    if (!extended && !showLabelInRail) {
      item = Tooltip(message: label, child: item);
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 1,
        horizontal: extended ? 0 : AppSpacing.xs,
      ),
      child: item,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final text = AppFormats.number(context, count > 99 ? 99 : count);
    return Semantics(
      label: AppStrings.navUnread(text),
      excludeSemantics: true,
      child: AppCountBadge(
        count: count,
        color: semantic.urgent,
        onColor: semantic.onUrgent,
      ),
    );
  }
}
