import 'package:flutter/widgets.dart';

import '../../../core/layout/app_layout_scope.dart';

import '../../../utils/constants/design_constants.dart';
import '../scroll_reveal.dart';
import 'app_motion.dart';
import 'app_pointer_arrows.dart';

/// A horizontally scrolling rail of cards.
///
/// A `Row` inside a horizontal scroll view rather than a `ListView`: a list
/// must be told its height, and a height computed from font metrics is wrong
/// the day a title wraps or the system font grows. A `Row` is as tall as its
/// tallest card, whatever the card contains. Keep rails short (≤ 10 cards,
/// ending in «See all»), so nothing is lost by building them all.
///
/// The first card lines up with the screen margin, and the rail runs from the
/// start edge, so it flips with the language on its own.
class AppRail extends StatefulWidget {
  const AppRail({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
    this.revealItems = true,
    this.nudgeId,
  });

  final List<Widget> children;
  final double spacing;

  /// Each card rises in after the one before it as the rail enters.
  /// False when the whole rail already sits inside a [ScrollReveal] — never
  /// nest one inside another.
  final bool revealItems;

  /// Set on the first rail of a page: it slides once per app run to show it
  /// scrolls sideways ([AppRailNudge]).
  final String? nudgeId;

  @override
  State<AppRail> createState() => _AppRailState();
}

class _AppRailState extends State<AppRail> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// One arrow click moves most of a screenful, keeping a card in view so
  /// the reader does not lose their place.
  void _page(int direction) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target =
        (position.pixels + direction * position.viewportDimension * 0.8).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    _scroll.animateTo(
      target,
      duration: AppDurations.slow,
      curve: AppCurves.enter,
    );
  }

  bool get _hasMoreBefore => _scroll.hasClients && _scroll.position.pixels > 0;

  bool get _hasMoreAfter =>
      !_scroll.hasClients ||
      _scroll.position.pixels < _scroll.position.maxScrollExtent;

  @override
  Widget build(BuildContext context) {
    final children = widget.children;
    Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: widget.spacing),
          if (widget.revealItems)
            ScrollReveal(
              key: children[i].key == null
                  ? null
                  : ScrollRevealKey(children[i].key!),
              child: children[i],
            )
          else
            children[i],
        ],
      ],
    );
    if (widget.nudgeId != null) {
      row = AppRailNudge(id: widget.nudgeId!, child: row);
    }

    // The first card lines up with the page's gutter, which widens with the
    // window (`AppLayout.gutter`).
    final gutter =
        AppLayoutScope.maybeOf(context)?.gutter ?? AppSpacing.screenMargin;

    return AppPointerArrows(
      // Scroll offsets grow towards the END edge in both directions, so
      // «next» is always +1.
      onPrevious: () => _page(-1),
      onNext: () => _page(1),
      canPrevious: () => _hasMoreBefore,
      canNext: () => _hasMoreAfter,
      child: AppDragScroll(
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          // Cards and chips cast shadows past the rail's own height; clipped,
          // they would be cut flat along the top and bottom.
          clipBehavior: Clip.none,
          padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
          child: row,
        ),
      ),
    );
  }
}
