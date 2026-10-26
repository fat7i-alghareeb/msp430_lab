import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import 'app_count_badge.dart';
import 'app_focus_ring.dart';
import 'app_icons.dart';

/// A 44×44 target around a 20dp glyph — the size `DESIGN_SYSTEM.md` sets for
/// an app-bar action, whatever the glyph measures.
///
/// Was the stores tab's own until the marketplace tab needed the same bar;
/// used by two features, so it lives here.
class AppBarAction extends StatelessWidget {
  const AppBarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  /// A count over the glyph. Zero draws nothing.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // The label shows on hover with a pointer and on a long press on touch —
    // Flutter's own Tooltip behaviour. Screen readers already hear [label].
    return AppFocusRing(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: SizedBox(
                width: AppIconSizes.minTouchTarget,
                height: AppIconSizes.minTouchTarget,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    AppIcon(icon, color: colors.onSurfaceVariant),
                    if (badgeCount > 0)
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        end: AppSpacing.sm,
                        child: AppCountBadge(
                          count: badgeCount,
                          color: colors.primary,
                          onColor: colors.onPrimary,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
