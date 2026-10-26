import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/layout/app_layout_scope.dart';
import '../../../utils/constants/design_constants.dart';
import 'app_pointer_arrows.dart';
import 'app_skeleton.dart';

/// A peek carousel: the current slide fills most of the width, the next one
/// peeks in at the edge, slides away from the centre shrink a little.
///
/// ```text
///   ┌───────────────────────────┐┌──
///   │                           ││
///   │        current slide      ││ next slide peeks in, smaller
///   │                           ││
///   └───────────────────────────┘└──
///              ━ ○ ○
/// ```
///
/// Swipe only — **no auto-advance**: a moving carousel needs pause controls
/// and a position announcement, and with a handful of items earns nothing.
///
/// `.loading()` reserves the exact height (the dots included), so nothing on
/// the page jumps when the data lands.
class AppPeekCarousel<T> extends StatefulWidget {
  const AppPeekCarousel({
    super.key,
    required List<T> this.items,
    required this.itemBuilder,
    this.aspectRatio = 5 / 4,
    this.semanticLabelOf,
  }) : isLoading = false;

  const AppPeekCarousel.loading({super.key, this.aspectRatio = 5 / 4})
    : items = null,
      itemBuilder = null,
      semanticLabelOf = null,
      isLoading = true;

  final List<T>? items;

  /// Builds one slide. `isActive` is true for the slide on screen — use it to
  /// start a slow zoom (`AppKenBurns(active: isActive)`), for instance.
  final Widget Function(BuildContext context, T item, bool isActive)?
  itemBuilder;

  /// Width / height of one slide.
  final double aspectRatio;

  /// What a screen reader hears for a slide. The one on screen speaks; the
  /// one peeking in is reached by swiping, like any page.
  final String Function(T item)? semanticLabelOf;

  final bool isLoading;

  /// Each slide takes this much of the width in a compact window; the next
  /// one peeks in.
  static const double viewportFraction = 0.86;

  /// How much of the width one slide takes in a window of [size]: wider
  /// windows show two or three slides instead of one stretched one.
  static double viewportFractionFor(WindowSize size) => switch (size) {
    WindowSize.compact => viewportFraction,
    WindowSize.medium => 0.6,
    _ => 0.42,
  };

  /// How small a slide that is not the current one is drawn.
  static const double sideScale = 0.92;

  static const double _dotsHeight = 5;

  /// The slide height for a carousel [width] wide in a window of [size].
  double heightFor(double width, WindowSize size) =>
      width * viewportFractionFor(size) / aspectRatio;

  @override
  State<AppPeekCarousel<T>> createState() => _AppPeekCarouselState<T>();
}

class _AppPeekCarouselState<T> extends State<AppPeekCarousel<T>> {
  PageController _controller = PageController(
    viewportFraction: AppPeekCarousel.viewportFraction,
  );
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = AppLayoutScope.maybeOf(context) == null
        ? WindowSize.compact
        : AppLayoutScope.windowSizeOf(context);
    final fraction = AppPeekCarousel.viewportFractionFor(size);
    if (fraction == _controller.viewportFraction) return;
    // The fraction is fixed per controller: a window crossing a size class
    // gets a new one, opened on the slide that was showing.
    final old = _controller;
    _controller = PageController(
      viewportFraction: fraction,
      initialPage: _index,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items ?? <T>[];
    final size = AppLayoutScope.maybeOf(context) == null
        ? WindowSize.compact
        : AppLayoutScope.windowSizeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return _build(context, items, widget.heightFor(width, size), size);
      },
    );
  }

  void _go(int delta) {
    final items = widget.items ?? <T>[];
    final target = (_index + delta).clamp(
      0,
      items.isEmpty ? 0 : items.length - 1,
    );
    _controller.animateToPage(
      target,
      duration: AppDurations.slow,
      curve: AppCurves.enter,
    );
  }

  Widget _build(
    BuildContext context,
    List<T> items,
    double height,
    WindowSize size,
  ) {
    return SkeletonScope(
      isLoading: widget.isLoading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: height,
            child: widget.isLoading
                ? const Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.screenMargin,
                    ),
                    child: SkeletonBox(
                      radius: AppRadii.xl,
                      child: SizedBox.expand(),
                    ),
                  )
                : AppPointerArrows(
                    onPrevious: () => _go(-1),
                    onNext: () => _go(1),
                    canPrevious: () => _index > 0,
                    canNext: () => _index < items.length - 1,
                    child: AppDragScroll(
                      child: PageView.builder(
                        controller: _controller,
                        // Every slide starts at the start edge in a wide window,
                        // so two or three sit side by side.
                        padEnds: size == WindowSize.compact,
                        // Shadows and the side slides' edges must not be cut.
                        clipBehavior: Clip.none,
                        itemCount: items.length,
                        onPageChanged: (index) =>
                            setState(() => _index = index),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final label = widget.semanticLabelOf?.call(item);
                          Widget slide = widget.itemBuilder!(
                            context,
                            item,
                            index == _index,
                          );
                          if (label != null) {
                            slide = Semantics(
                              label: label,
                              button: true,
                              excludeSemantics: true,
                              child: slide,
                            );
                          }
                          return ExcludeSemantics(
                            excluding: index != _index,
                            child: _PeekSlide(
                              controller: _controller,
                              index: index,
                              child: slide,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
          // The dots are reserved while loading too: a skeleton 13dp short
          // would shift the whole page the moment the data arrived.
          if (widget.isLoading) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const SkeletonBar(width: 28, height: AppPeekCarousel._dotsHeight),
          ] else if (items.length > 1) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _Dots(count: items.length, active: _index),
          ],
        ],
      ),
    );
  }
}

/// Scales a slide by its distance from the centre of the carousel.
class _PeekSlide extends StatelessWidget {
  const _PeekSlide({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xs2,
        ),
        child: child,
      ),
      builder: (context, child) {
        var page = index.toDouble();
        if (controller.hasClients && controller.position.haveDimensions) {
          page = controller.page ?? page;
        }
        final distance = (page - index).abs().clamp(0.0, 1.0);
        final scale =
            1 -
            (1 - AppPeekCarousel.sideScale) *
                Curves.easeOut.transform(distance);
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

/// The page indicator: the active dot stretches into a bar, so the position
/// reads without relying on colour alone.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppDurations.toggle,
              curve: AppCurves.toggle,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == active ? 20 : 6,
              height: AppPeekCarousel._dotsHeight,
              decoration: BoxDecoration(
                color: i == active ? colors.primary : colors.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
        ],
      ),
    );
  }
}
