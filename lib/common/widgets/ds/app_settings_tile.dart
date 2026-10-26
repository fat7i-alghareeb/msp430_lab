import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import '../../../utils/extensions/context_extensions.dart';
import 'app_card.dart';
import 'app_icons.dart';

/// A titled group of settings rows inside one card; each row leads with its
/// glyph on a soft `primaryContainer` disc.
///
/// The heading sits OUTSIDE the card, and the card holds the rows with a
/// hairline between them and none after the last.
class AppSettingsGroup extends StatelessWidget {
  const AppSettingsGroup({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;

  /// The line under the rows that explains them — e.g. why some rows cannot
  /// be switched off.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xs,
            bottom: AppSpacing.xs2,
          ),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var index = 0; index < children.length; index++) ...<Widget>[
                children[index],
                if (index != children.length - 1)
                  Divider(
                    height: AppBorders.hairline,
                    thickness: AppBorders.hairline,
                    // Under the words, not under the disc.
                    indent:
                        AppSpacing.md +
                        AppSettingsTile.discSize +
                        AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: colors.outline,
                  ),
              ],
              if (footer != null)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One row: an icon, a word, and whatever the row is for on the end side —
/// a value and a chevron, a switch, or nothing at all.
///
/// A row with [isDisabled] is **not interactive** — a setting that is shown
/// but cannot be changed: it is drawn at [AppStates.dimmedRow] opacity, and
/// a tap does nothing.
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.label,
    this.icon,
    this.value,
    this.onTap,
    this.trailing,
    this.showChevron = false,
    this.isDestructive = false,
    this.isDisabled = false,
    this.semanticLabel,
  });

  /// A row whose end side is a switch.
  AppSettingsTile.toggle({
    super.key,
    required this.label,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    this.icon,
    this.semanticLabel,
  }) : value = null,
       onTap = null,
       showChevron = false,
       isDestructive = false,
       isDisabled = false,
       trailing = _Toggle(enabled: enabled, onChanged: onChanged);

  final String label;
  final String? icon;

  /// «English» · «System» · «1.0.0» — shown before the chevron.
  final String? value;

  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  /// Signing out, deleting the account: `error` colours.
  final bool isDestructive;

  /// Visible, dimmed, and inert.
  final bool isDisabled;

  final String? semanticLabel;

  static const double minHeight = 56;

  /// The soft disc the row's glyph sits on.
  static const double discSize = 36;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final foreground = isDestructive ? colors.error : colors.onSurface;
    final iconColor = isDestructive ? colors.error : colors.onPrimaryContainer;
    final discColor = isDestructive
        ? colors.error.withValues(alpha: 0.12)
        : colors.primaryContainer;

    Widget row = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: discSize,
              height: discSize,
              decoration: BoxDecoration(
                color: discColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AppIcon(icon!, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
          if (showChevron) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            AppIcon(
              // Points AT the destination, which is the end side — a fixed
              // left chevron points backwards in one of the two languages.
              context.chevronEnd,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: row,
    );

    if (isDisabled) {
      return Semantics(
        enabled: false,
        label: semanticLabel,
        excludeSemantics: semanticLabel != null,
        child: Opacity(opacity: AppStates.dimmedRow, child: row),
      );
    }

    if (onTap == null) {
      return semanticLabel == null
          ? row
          : Semantics(label: semanticLabel, excludeSemantics: true, child: row);
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }
}

/// The switch itself, so the row does not have to know how one is built.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppIconSizes.navTouchTarget,
      height: AppIconSizes.navTouchTarget,
      child: Center(
        child: Switch(value: enabled, onChanged: onChanged),
      ),
    );
  }
}
