part of 'app_scaffold.dart';

/// Configuration for the custom app bar section in [AppScaffold].
///
/// Notes:
/// - Set [showLeading] to `false` to completely remove the leading widget.
/// - If [leading] is `null`, a default back icon is used.
/// - If [onLeadingTap] is `null`, it defaults to `context.pop()`.
/// - [enableDrawer] only has an effect if the scaffold also enables
///   [ScaffoldFeature.appBar]. When enabled, a drawer action button is injected
///   automatically.
final class AppScaffoldAppBarConfig {
  const AppScaffoldAppBarConfig({
    this.height,
    this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.titleAlignment = AppScaffoldTitleAlignment.centered,
    this.actions = const <Widget>[],
    this.showLeading = true,
    this.leading,
    this.onLeadingTap,
    this.leadingPadding = const EdgeInsets.all(11),
    this.enableDrawer = false,
    this.drawerIcon,
    this.drawerActionPadding = const EdgeInsets.all(11),
  });

  final double? height;

  /// Main title (optional).
  final String? title;

  /// Optional subtitle shown under [title].
  final String? subtitle;

  /// Optional override for the title text style.
  final TextStyle? titleStyle;

  /// Optional override for the subtitle text style.
  final TextStyle? subtitleStyle;

  /// Controls how the title/subtitle block is aligned.
  final AppScaffoldTitleAlignment titleAlignment;

  /// App bar trailing actions.
  ///
  /// A drawer action may be appended automatically when [enableDrawer] is true.
  final List<Widget> actions;

  /// Whether a leading widget should be shown.
  final bool showLeading;

  /// Custom leading widget.
  ///
  /// When `null`, a default back icon is used.
  final Widget? leading;

  /// Callback invoked when the leading widget is tapped.
  ///
  /// When `null`, defaults to `context.pop()`.
  final VoidCallback? onLeadingTap;

  final EdgeInsetsGeometry leadingPadding;

  /// Enables an end drawer.
  ///
  /// This does two things:
  /// - adds the `Scaffold.endDrawer`
  /// - injects a drawer action into the app bar
  final bool enableDrawer;

  /// Optional icon for the drawer action.
  final IconSource? drawerIcon;

  final EdgeInsetsGeometry drawerActionPadding;
}

/// Internal app bar implementation for [AppScaffold].
///
/// This file intentionally avoids using Flutter's [AppBar].
class _AppScaffoldAppBar extends StatelessWidget {
  const _AppScaffoldAppBar({required this.config, required this.drawerEnabled});

  final AppScaffoldAppBarConfig config;

  /// Whether the end drawer is enabled for this scaffold.
  ///
  /// When true, a drawer action button is injected at the end of the actions.
  final bool drawerEnabled;

  @override
  Widget build(BuildContext context) {
    final leading = _buildLeading(context);

    final resolvedHeight = _resolveHeight(context);

    /// Start with user-provided actions, then optionally inject a drawer action.
    final actions = <Widget>[
      ...config.actions,
      if (drawerEnabled)
        _AppScaffoldDrawerAction(
          icon: config.drawerIcon ?? IconSource.svg(AppIcons.menu),
          padding: config.drawerActionPadding,
        ),
    ];

    final titleWidget = _AppScaffoldTitle(
      title: config.title,
      subtitle: config.subtitle,
      titleStyle: config.titleStyle,
      subtitleStyle: config.subtitleStyle,
      alignment: config.titleAlignment,
    );

    final body = switch (config.titleAlignment) {
      /// Centered title must stay visually centered regardless of how wide the
      /// leading/actions are. A [Stack] achieves that by letting the title be
      /// centered independently from the horizontal chrome row.
      AppScaffoldTitleAlignment.centered => Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              ...?(leading == null ? null : <Widget>[leading]),
              const Spacer(),
              if (actions.isNotEmpty) ...[for (final w in actions) w],
            ],
          ),
          Align(heightFactor: 1, child: titleWidget),
        ],
      ),
      AppScaffoldTitleAlignment.start => Row(
        children: <Widget>[
          ...?(leading == null ? null : <Widget>[leading]),
          Expanded(
            child: Align(
              // Directional: `start` is the right edge in Arabic.
              alignment: AlignmentDirectional.centerStart,
              heightFactor: 1,
              child: titleWidget,
            ),
          ),
          if (actions.isNotEmpty) ...[for (final w in actions) w],
        ],
      ),
      AppScaffoldTitleAlignment.end => Row(
        children: <Widget>[
          ...?(leading == null ? null : <Widget>[leading]),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              heightFactor: 1,
              child: titleWidget,
            ),
          ),
          if (actions.isNotEmpty) ...[for (final w in actions) w],
        ],
      ),
    };

    final fullWidth = DecoratedBox(
      decoration: const BoxDecoration(),
      child: SizedBox(width: double.infinity, child: body),
    );

    if (resolvedHeight == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kToolbarHeight),
        child: fullWidth,
      );
    }

    return SizedBox(height: resolvedHeight, child: fullWidth);
  }

  double? _resolveHeight(BuildContext context) {
    final raw = config.height;
    if (raw == null || raw <= 0) return null;
    if (raw <= 1) return context.screenHeight * raw;
    return raw;
  }

  Widget? _buildLeading(BuildContext context) {
    if (!config.showLeading) return null;

    /// If no custom leading widget is provided, we default to a standard back icon.
    final icon =
        config.leading ??
        AppIcon(context.chevronStart, size: 22, color: context.onSurface);

    /// If no leading callback is provided, default behavior is route pop.
    final onTap = config.onLeadingTap ?? () => context.pop();

    return _TapArea(
      onTap: onTap,
      child: Padding(padding: config.leadingPadding, child: icon),
    );
  }
}

class _AppScaffoldDrawerAction extends StatelessWidget {
  const _AppScaffoldDrawerAction({required this.icon, required this.padding});

  final IconSource icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return _TapArea(
      onTap: () {
        /// Uses the closest Scaffold to open the end drawer.
        /// We use maybeOf to avoid throwing if no Scaffold is found.
        final state = Scaffold.maybeOf(context);
        if (state == null) return;

        // Open whichever drawer is actually configured.
        // This avoids relying on Directionality rules and ensures RTL/LTR
        // always opens from the intended side.
        if (state.hasEndDrawer) {
          state.openEndDrawer();
          return;
        }
        if (state.hasDrawer) {
          state.openDrawer();
        }
      },
      child: Padding(
        padding: padding,
        child: icon.build(context, color: context.onSurface, size: 22),
      ),
    );
  }
}

class _AppScaffoldTitle extends StatelessWidget {
  const _AppScaffoldTitle({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.alignment,
  });

  final String? title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final AppScaffoldTitleAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final t = title?.trim();
    final st = subtitle?.trim();
    final hasTitle = t != null && t.isNotEmpty;
    final hasSubtitle = st != null && st.isNotEmpty;

    /// If both are empty, render nothing to avoid reserving vertical space.
    if (!hasTitle && !hasSubtitle) return const SizedBox.shrink();

    final align = switch (alignment) {
      AppScaffoldTitleAlignment.centered => TextAlign.center,
      AppScaffoldTitleAlignment.start => TextAlign.start,
      AppScaffoldTitleAlignment.end => TextAlign.end,
    };

    Widget switcher({required Widget child, required Key key}) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide =
              Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(key: key, child: child),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasTitle)
          switcher(
            key: ValueKey('title:$t'),
            child: Text(
              t,
              textAlign: align,
              style:
                  titleStyle ??
                  AppTextStyles.s16w600.copyWith(color: context.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (hasSubtitle) ...[
          2.verticalSpace,
          switcher(
            key: ValueKey('subtitle:$st'),
            child: Text(
              st,
              textAlign: align,
              style:
                  subtitleStyle ??
                  AppTextStyles.s12w400.copyWith(
                    color: context.onSurface.withValues(alpha: 0.65),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
