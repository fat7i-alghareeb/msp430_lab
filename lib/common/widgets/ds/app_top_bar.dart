/// Top bars that react to scrolling: a hairline rule and a soft shadow
/// fade in once the page is under the bar,
/// and list screens carry a LARGE title that collapses into the bar.
///
/// No tint fill: a bar keeps the screen's own ground colour while scrolled.
///
/// ```text
///  at rest                      scrolled
///  ┌──────────────────────┐     ┌──────────────────────┐
///  │ ‹              🔍 🔖 │     │ ‹       News    🔍 🔖 │  small title fades in
///  │ News                 │     ├──────────────────────┤  rule + soft shadow
///  └──────────────────────┘     │                      │
/// ```
library;

import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import '../../../utils/extensions/theme_extensions.dart';

/// The bar's ground: the screen's background, with the rule and the shadow
/// fading in while [isScrolled].
class AppTopBarFrame extends StatelessWidget {
  const AppTopBarFrame({
    super.key,
    required this.isScrolled,
    required this.child,
  });

  final bool isScrolled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: AppCurves.toggle,
      decoration: BoxDecoration(
        // `background`, not `surface` — the bar is the screen's own ground.
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isScrolled
                ? colors.outline
                : colors.outline.withValues(alpha: 0),
          ),
        ),
        boxShadow: isScrolled && !context.isDarkTheme
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0F141510),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: child,
    );
  }
}

/// The bar's own small title: absent at rest (the large title says it),
/// fading in once the large title has collapsed.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({
    super.key,
    required this.title,
    required this.visible,
    this.textAlign,
    this.style,
  });

  final String title;
  final bool visible;
  final TextAlign? textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: AppCurves.enter,
      switchOutCurve: AppCurves.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: textAlign == TextAlign.center
            ? Alignment.center
            : AlignmentDirectional.centerStart,
        children: <Widget>[...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: visible
          ? Text(
              title,
              key: const ValueKey<bool>(true),
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style ?? theme.textTheme.titleLarge,
            )
          : const SizedBox(key: ValueKey<bool>(false), width: double.infinity),
    );
  }
}

/// The large title under the bar. It collapses — height and words — once
/// the list scrolls, and comes back at the top.
class AppLargeTitle extends StatelessWidget {
  const AppLargeTitle({
    super.key,
    required this.title,
    required this.collapsed,
  });

  final String title;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: AppCurves.enter,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: collapsed
            ? const SizedBox(key: ValueKey<bool>(true), width: double.infinity)
            : Padding(
                key: const ValueKey<bool>(false),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screenMargin,
                  0,
                  AppSpacing.screenMargin,
                  AppSpacing.md,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Knows whether the screen's own list has scrolled, for a bar that has no
/// scroll controller of its own. Wrap the Column that holds the bar and the
/// list; the bar reads [AppScrollAware.isScrolledOf].
class AppScrollAware extends StatefulWidget {
  const AppScrollAware({super.key, required this.child});

  final Widget child;

  /// False when there is no [AppScrollAware] above.
  static bool isScrolledOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ScrolledMarker>()
          ?.isScrolled ??
      false;

  @override
  State<AppScrollAware> createState() => _AppScrollAwareState();
}

class _AppScrollAwareState extends State<AppScrollAware> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    // The page's own vertical list, not a rail or a carousel inside it.
    if (n.metrics.axis != Axis.vertical) return false;
    final scrolled = n.metrics.pixels > n.metrics.minScrollExtent;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: _ScrolledMarker(isScrolled: _scrolled, child: widget.child),
    );
  }
}

class _ScrolledMarker extends InheritedWidget {
  const _ScrolledMarker({required this.isScrolled, required super.child});

  final bool isScrolled;

  @override
  bool updateShouldNotify(_ScrolledMarker old) => old.isScrolled != isScrolled;
}
