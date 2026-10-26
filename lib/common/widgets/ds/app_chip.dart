import 'package:flutter/material.dart';

import '../../../utils/helpers/app_formats.dart';

import '../../../utils/extensions/context_extensions.dart';
import '../../../utils/constants/design_constants.dart';
import 'app_icons.dart';
import 'app_motion.dart';

/// A filter chip — `DESIGN_SYSTEM.md`.
///
/// Inactive: `surfaceVariant` with `onSurfaceVariant` text.
/// Active: `primary` with `onPrimary` text **at weight 700** — the active
/// state is carried by color *and* weight, never by color alone.
///
/// Height 32, full radius, padding `5×11`.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.count,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Appended to the label as `الكل 12`. Hidden when null.
  ///
  /// A **formatted** string, not a number: a chip is exactly where a raw
  /// `int` interpolated into an Arabic label would print Latin digits and
  /// never be noticed, because no golden holds one and `pumpApp` sets no
  /// locale. The caller passes
  /// `AppFormats.number(context, n)`.
  final String? count;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Primary when active; otherwise the surface with a hairline.
    final background = selected ? colors.primary : colors.surface;
    final foreground = selected ? colors.onPrimary : colors.onSurface;

    // «News · 4» — a middle dot between the word and its count.
    final text = count == null ? label : '$label · $count';

    return Semantics(
      button: true,
      selected: selected,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: selected ? BorderSide.none : BorderSide(color: colors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.full),
          // No `alignment` on this container: with one, a `Container` under
          // BOUNDED constraints expands to fill them, and a chip inside a
          // `Wrap` — the no-results categories, the empty-list suggestions
          // — stretched to the full width of the screen. The `Row` centres
          // its children on the cross axis by itself.
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: AppSpacing.xs2),
                ],
                Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of [AppChip] — `DESIGN_SYSTEM.md`.
///
/// The first chip is usually «All», added by the caller and not expected from the
/// server, so a section that defines no statuses simply renders no rail.
class AppChipRail extends StatelessWidget {
  const AppChipRail({
    super.key,
    required this.children,
    this.padding,
    this.spacing = AppSpacing.xs2,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final insets =
        padding ??
        const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.screenMargin,
        );

    return SizedBox(
      // The chips are 32; any vertical padding the caller asks for is ADDED
      // to that, not taken out of it. At a fixed 32 the notifications row's
      // 8dp above and below crushed every chip to 16.
      height: 32 + insets.vertical,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Cards and chips cast shadows past the rail's own height; clipped,
        // they were cut flat along the top and bottom.
        clipBehavior: Clip.none,
        padding: insets,
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

/// Section header — a title with an optional trailing action.
///
/// `DESIGN_SYSTEM.md`: the gap to the content below is 12dp, and 24dp
/// separates one section from the next.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.count,
    this.accent,
    this.newLabel,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  /// How many items «See all» leads to — shown in the pill, counting up
  /// the first time the header appears.
  final int? count;

  /// The accent bar's colour — `primary` when null.
  final Color? accent;

  /// «2 new» beside a dot when the section has items newer than the last
  /// visit (`LastVisit`).
  final String? newLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = this.accent ?? colors.primary;

    // Title over a short accent bar that draws itself in; the action is a
    // pill against the end edge.
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (newLabel != null) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          newLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppAccentLine(color: accent),
                ],
              ),
            ),
            if (actionLabel != null)
              // Never more than half the row, its label flexible inside it:
              // at a large text scale an unbounded action overflows.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: _SectionPill(
                  label: actionLabel!,
                  count: count,
                  onTap: onActionTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionPill extends StatelessWidget {
  const _SectionPill({required this.label, this.count, this.onTap});

  final String label;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: colors.onPrimaryContainer,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      button: true,
      label: count == null
          ? label
          : '$label ${AppFormats.number(context, count!)}',
      excludeSemantics: true,
      child: Material(
        color: colors.primaryContainer,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            // The pill is drawn 32 tall; its tap area is the full 44.
            constraints: const BoxConstraints(
              minHeight: AppIconSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.md,
                end: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                  if (count != null) ...<Widget>[
                    Text(' · ', style: style),
                    AppCountUp(value: count!, style: style),
                  ],
                  const SizedBox(width: AppSpacing.xxs),
                  // Points to the END edge, so it flips with the language
                  AppIcon(
                    context.chevronEnd,
                    size: 16,
                    color: colors.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «Filter · 2» — the filter pill beside a tab's search: filled with
/// `primary` while filters are on, counting them.
class AppFilterPill extends StatelessWidget {
  const AppFilterPill({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.activeCount,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final on = activeCount > 0;
    final fg = on ? colors.onPrimary : colors.onSurface;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: on ? colors.primary : colors.surface,
        shape: StadiumBorder(
          side: on ? BorderSide.none : BorderSide(color: colors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppIcon(AppIcons.filter, size: 18, color: fg),
                  const SizedBox(width: AppSpacing.xs2),
                  Text(
                    on
                        ? '$label · ${AppFormats.number(context, activeCount)}'
                        : label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
