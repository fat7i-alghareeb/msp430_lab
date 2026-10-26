import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../utils/constants/design_constants.dart';
import 'app_icons.dart';

/// How loud a banner is.
enum AppBannerTone {
  /// A section description, a neutral explanation.
  info,

  /// «This item has expired», «Sold».
  muted,

  /// Something the reader must not miss.
  urgent,
}

/// A banner that explains a state in words — `DESIGN_SYSTEM.md`.
///
/// Used for the section description at the top of a content list, for the
/// «expired» notice on an item reached through a shared link, and for a
/// «sold» notice.
///
/// The state is always spelled out. Dimming an expired item to 55% opacity and
/// leaving it at that would signal by appearance alone, which the system bans.
class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.message,
    this.detail,
    this.tone = AppBannerTone.info,
    this.icon,
    this.announce = false,
  });

  final String message;

  /// A second line under [message]. Hidden when null.
  final String? detail;

  final AppBannerTone tone;
  final String? icon;

  /// Marks the banner as a live region so a screen reader announces it when it
  /// appears — use it for a state the reader did not ask for, such as an item
  /// turning out to be expired.
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    late final Color background;
    late final Color foreground;

    switch (tone) {
      case AppBannerTone.info:
        background = colors.primaryContainer;
        foreground = colors.onPrimaryContainer;
      case AppBannerTone.muted:
        background = colors.surfaceContainerHighest;
        foreground = colors.onSurfaceVariant;
      case AppBannerTone.urgent:
        background = semantic.urgent;
        foreground = semantic.onUrgent;
    }

    return Semantics(
      liveRegion: announce,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              // The glyph on its own disc — the banner reads as a card with
              // something to say, as the app's state screens do.
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(icon!, size: 18, color: foreground),
              ),
              const SizedBox(width: AppSpacing.sm2),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A circular avatar that falls back to the first letter of [name].
///
/// Sign-in is Google-only and the profile photo comes from the Google account,
/// so «no photo» is a normal state, not an error: an account without one is
/// common and must look deliberate.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;

    // Decorative, as the logo tile is: the name is always beside it, and
    // A screen reader would read the initial before the name beside it.
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: imageUrl == null
            ? Text(
                initial,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontSize: size * 0.4,
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, _, _) => Text(
                  initial,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontSize: size * 0.4,
                  ),
                ),
              ),
      ),
    );
  }
}
