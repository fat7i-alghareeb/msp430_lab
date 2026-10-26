import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/layout/app_layout_scope.dart';

import '../../../utils/constants/design_constants.dart';
import '../../../utils/extensions/context_extensions.dart';
import '../../../utils/helpers/app_strings.dart';
import 'app_icons.dart';

/// A detail page that opens on a photo with a content sheet rising over it.
///
/// ```text
/// ┌──────────────────────────────┐
/// │ (←)                     (⋮)  │  fixed at the TOP, under the status bar
/// │      [edge-to-edge image]    │  as the sheet rises it sinks at half
/// │                              │  speed, shrinks, rounds and dims
/// │  ╭────────── ▬ ─────────────╮│  the sheet rises [overlap] over it
/// │  │ title · meta · body …     ││
/// │  ╰──────────────────────────╯│
/// ├──────────────────────────────┤
/// │   (floating action capsule)  │  [actions], tucks away on scroll
/// └──────────────────────────────┘
/// ```
///
/// - Pulled down past the top, the picture stretches from its bottom edge.
/// - The sheet rises into place once as the page opens.
/// - Once the picture has scrolled away the top bar turns solid and
///   [title] fades in; the round translucent controls stay legible over any
///   photograph, in both themes.
/// - **With no picture** ([image] null) there is no empty hole: the controls
///   become an ordinary app bar and the sheet starts at the top.
/// - Reduced motion: no parallax, no rise — the same layout, still.
///
/// The picture and the sheet are ONE sliver on purpose: a viewport paints its
/// slivers last-first, so a sheet risen over the picture from a second sliver
/// would be painted UNDER it.
class AppHeroDetailLayout extends StatefulWidget {
  const AppHeroDetailLayout({
    super.key,
    required this.body,
    this.image,
    this.title,
    this.menu,
    this.actions,
    this.imageHeight = 260,
    this.wideImageHeight = 320,
    this.overlap = 26,
  });

  /// The content of the sheet.
  final Widget body;

  /// The header picture (put a `Hero` and `AppKenBurns` inside it if you
  /// want them). Null: no picture, a plain app bar.
  final Widget? image;

  /// Shown in the bar once the picture has scrolled away.
  final String? title;

  /// The `⋮` control; null hides it.
  final VoidCallback? menu;

  /// The floating action capsule, given the page's scroll controller so it
  /// can tuck away while the page is read (`AppActionCapsule`).
  final Widget Function(ScrollController controller)? actions;

  final double imageHeight;

  /// From 600dp up: a picture that keeps its phone height on a tablet reads
  /// as a strip.
  final double wideImageHeight;

  /// How far the sheet rises over the picture.
  final double overlap;

  @override
  State<AppHeroDetailLayout> createState() => _AppHeroDetailLayoutState();
}

class _AppHeroDetailLayoutState extends State<AppHeroDetailLayout> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _imageHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600
      ? widget.wideImageHeight
      : widget.imageHeight;

  /// Expanded windows (840dp and wider): the picture beside the text rather
  /// than above it. Stretched across a desktop window, a header photo would
  /// be a thin strip and the text lines far too long (`docs/RESPONSIVE.md`).
  Widget _buildSideBySide(BuildContext context, AppLayout layout) {
    final gutter = layout.gutter;
    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _PlainBar(menu: widget.menu),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.contentMaxWidth,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            gutter,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            gutter,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                child: widget.image,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: CustomScrollView(
                          controller: _scroll,
                          slivers: <Widget>[
                            SliverPadding(
                              padding: EdgeInsetsDirectional.only(end: gutter),
                              sliver: SliverToBoxAdapter(
                                child: Align(
                                  alignment: AlignmentDirectional.topStart,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: AppLayout.readableMaxWidth,
                                    ),
                                    child: widget.body,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.actions != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: widget.actions!(_scroll),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.image != null;
    final layout = AppLayoutScope.maybeOf(context);
    if (hasImage && layout != null && layout.isExpandedUp) {
      return _buildSideBySide(context, layout);
    }
    final imageHeight = _imageHeight(context);
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: <Widget>[
        CustomScrollView(
          controller: _scroll,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (hasImage)
                    _HeaderImage(
                      controller: _scroll,
                      height: imageHeight,
                      child: widget.image!,
                    )
                  else
                    _PlainBar(menu: widget.menu),
                  Transform.translate(
                    offset: Offset(0, hasImage ? -widget.overlap : 0),
                    child: _RisingSheet(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadii.sheet),
                          ),
                        ),
                        child: widget.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasImage)
          _TopBar(
            controller: _scroll,
            imageHeight: imageHeight,
            title: widget.title,
            menu: widget.menu,
          ),
        if (widget.actions != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: widget.actions!(_scroll),
          ),
      ],
    );
  }
}

/// The sheet rises into place once, as the page opens.
class _RisingSheet extends StatelessWidget {
  const _RisingSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: AppCurves.reveal,
      builder: (context, t, child) =>
          Transform.translate(offset: Offset(0, 48 * (1 - t)), child: child),
      child: child,
    );
  }
}

/// The edge-to-edge picture: as the sheet rises over it the picture sinks at
/// half the page's speed, shrinks a little, rounds its corners and dims.
/// Pulled down past the top, it stretches instead.
class _HeaderImage extends StatelessWidget {
  const _HeaderImage({
    required this.controller,
    required this.height,
    required this.child,
  });

  final ScrollController controller;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget picture = child;
    if (!MediaQuery.disableAnimationsOf(context)) {
      picture = AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          final offset = controller.hasClients ? controller.offset : 0.0;
          if (offset < 0) {
            return Transform.scale(
              scale: 1 + (-offset / height),
              alignment: Alignment.bottomCenter,
              child: child,
            );
          }
          final t = (offset / height).clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, offset * 0.5),
            child: Transform.scale(
              scale: 1 - 0.14 * t,
              child: Opacity(
                opacity: 1 - 0.55 * t,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sheet * t),
                  child: child,
                ),
              ),
            ),
          );
        },
      );
    }
    return SizedBox(height: height, width: double.infinity, child: picture);
  }
}

/// The two controls, FIXED at the top under the status bar. Once the picture
/// has scrolled away the bar turns solid and the title fades in.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.imageHeight,
    required this.title,
    required this.menu,
  });

  final ScrollController controller;
  final double imageHeight;
  final String? title;
  final VoidCallback? menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final solidAt = imageHeight - top - 56;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final offset = controller.hasClients ? controller.offset : 0.0;
          final t = ((offset - solidAt * 0.6) / (solidAt * 0.4)).clamp(
            0.0,
            1.0,
          );
          return DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: t),
              border: Border(
                bottom: BorderSide(color: colors.outline.withValues(alpha: t)),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.sm + context.leadingWindowControlsInset,
                top + AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  _FloatingControl(
                    icon: context.chevronStart,
                    label: AppStrings.actionBack,
                    solid: t,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Opacity(
                      opacity: t,
                      child: ExcludeSemantics(
                        excluding: t < 0.5,
                        child: Text(
                          title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (menu != null)
                    _FloatingControl(
                      icon: AppIcons.more,
                      label: AppStrings.actionMore,
                      solid: t,
                      onTap: menu!,
                    )
                  else
                    const SizedBox(width: _FloatingControl.size),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A round 40dp control on a translucent ground, so it stays legible over any
/// photograph. [solid] (0–1) fades the disc away as the bar behind it turns
/// solid.
class _FloatingControl extends StatelessWidget {
  const _FloatingControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.solid = 0,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final double solid;

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.surface.withValues(
          alpha: (isDark ? 0.85 : 0.88) * (1 - solid),
        ),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: AppIcon(icon, color: colors.onSurface)),
          ),
        ),
      ),
    );
  }
}

/// The app bar a page with no picture gets instead of floating controls.
class _PlainBar extends StatelessWidget {
  const _PlainBar({required this.menu});

  final VoidCallback? menu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.sm + context.leadingWindowControlsInset,
            end: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              _FloatingControl(
                icon: context.chevronStart,
                label: AppStrings.actionBack,
                solid: 1,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              if (menu != null)
                _FloatingControl(
                  icon: AppIcons.more,
                  label: AppStrings.actionMore,
                  solid: 1,
                  onTap: menu!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
