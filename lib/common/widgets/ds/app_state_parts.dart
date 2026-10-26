import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import 'app_icons.dart';

/// The large round icon every empty and error state leads with:
/// `primaryContainer` for «nothing here yet», a soft `error` tint for
/// «couldn't load».
class AppStateDisc extends StatelessWidget {
  const AppStateDisc({super.key, required this.child, this.isError = false});

  final Widget child;
  final bool isError;

  static const double size = 84;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isError
              ? colors.error.withValues(alpha: 0.12)
              : colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  /// The icon colour that belongs on the disc.
  static Color iconColor(BuildContext context, {bool isError = false}) {
    final colors = Theme.of(context).colorScheme;
    return isError ? colors.error : colors.onPrimaryContainer;
  }
}

/// A filled `primary` pill — the one action of an empty or error state, and
/// the «Sign in» of the session banner.
class AppActionPill extends StatelessWidget {
  const AppActionPill({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: const StadiumBorder(),
        minimumSize: const Size(0, AppIconSizes.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[icon!, const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// A confirmation's words, led by a check —
/// the content of every [SnackBar]; the theme makes it a dark floating pill.
class AppSnackContent extends StatelessWidget {
  const AppSnackContent(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        AppIcon(AppIcons.check, size: 18, color: colors.primaryContainer),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
