import 'dart:math' as math;

import 'package:flutter/material.dart' show Divider;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../utils/constants/design_constants.dart';

/// Fades a list item in, grows it from [ScrollReveal.startScale] and lifts it
/// into place every time it enters the screen — the app's one scroll entrance.
///
/// Why not `.animate()` on the item, as the lists used to: a list builds its
/// items ahead of the viewport (the cache extent), so the entrance played
/// off screen, and by the time the reader scrolled to the item it had long
/// finished. This waits for the item to actually CROSS an edge of its
/// scrollable.
///
/// The rules, so every list behaves the same:
/// - On screen when the list first appears: plays at once, the first few
///   staggered by [AppDurations.listStagger].
/// - Scrolling down, an item crossing the bottom edge rises in from below.
/// - Scrolling up, an item crossing the TOP edge drops in from above — the
///   same entrance, mirrored.
/// - An item that leaves the screen entirely is re-armed, so it enters again
///   the next time it comes back, from whichever side.
/// - Items that arrive in the same frame stagger — unless the list is being
///   flung, when they all arrive together and quicker, so content never
///   trails behind a fast scroll.
/// - Reduced motion: shown as it is.
///
/// Semantics are ALWAYS included, even at opacity zero: a screen reader
/// can reach an item that has not risen yet, and reaching it scrolls it in.
///
/// Wrap the item, never the list, and never nest one inside another. A
/// horizontal rail's cards may each carry one — they are measured against
/// the vertical page they sit in, and stagger as the rail comes in.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// False shows [child] as it is — a skeleton, which has its own shimmer.
  final bool enabled;

  /// How far below (or above) its place the item starts.
  static const double rise = 30;

  /// How small the item starts.
  static const double startScale = 0.92;

  /// How far into the viewport the item's leading edge must come before it
  /// plays — so it rises where the reader can see it, not under the edge
  /// or behind the floating navigation bar.
  static const double edgeInset = 48;

  /// The most items of one batch that wait their turn; the rest play with
  /// the last of them, so a long batch never keeps the reader waiting.
  static const int maxStagger = 5;

  /// Above this scroll speed (logical px per second) the list counts as
  /// flung: no stagger, and a shorter entrance.
  static const double flingVelocity = 1800;

  /// Every block of a plain `ListView(children: …)` page, each rising in
  /// on its own. Gaps (`SizedBox` with no child) and dividers are left as
  /// they are; a keyed child keeps a wrapper keyed after it (see
  /// [ScrollRevealKey]).
  ///
  /// Not for a child that already reveals its own rows — never nest one.
  static List<Widget> each(List<Widget> children) => <Widget>[
    for (final child in children)
      if ((child is SizedBox && child.child == null) || child is Divider)
        child
      else
        ScrollReveal(
          key: child.key == null ? null : ScrollRevealKey(child.key!),
          child: child,
        ),
  ];

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double> _progress = kAlwaysDismissedAnimation;
  ScrollPosition? _position;
  bool _checkScheduled = false;

  /// Shown for good (reduced motion, disabled, not in a scrollable): no more
  /// watching.
  bool _static = false;

  /// Shown, or on its way in.
  bool _visible = false;

  /// Whether the running entrance comes from above.
  bool _fromAbove = false;

  /// The first measurement decides «on screen as the list appears».
  bool _measured = false;

  // Items that start in the same frame share one stagger sequence.
  static int _batchSize = 0;
  static bool _batchResetScheduled = false;

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_static) return;
    if (!widget.enabled || _reducedMotion) {
      _showForGood();
      return;
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled && _static && !_reducedMotion) {
      // A skeleton turning into the real item: the item enters from where it
      // is, as if it had just arrived.
      _static = false;
      _visible = false;
      _measured = false;
      _progress = kAlwaysDismissedAnimation;
      _scheduleCheck();
    } else if (oldWidget.enabled && !widget.enabled) {
      _showForGood();
    }
  }

  @override
  void dispose() {
    _stopWatching();
    _controller?.dispose();
    super.dispose();
  }

  /// Every check runs after layout, when positions are real — never in the
  /// middle of a build or a paint.
  void _scheduleCheck() {
    if (_checkScheduled || _static) return;
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _check() {
    if (!mounted || _static) return;

    // A grid or list that never scrolls — `NeverScrollableScrollPhysics`,
    // one section of a page's own scroll view — is as tall as its content,
    // so measured against it every tile is «on screen». The page that
    // scrolls is the one further up.
    var scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    while (scrollable != null &&
        scrollable.widget.physics is NeverScrollableScrollPhysics) {
      scrollable = Scrollable.maybeOf(scrollable.context, axis: Axis.vertical);
    }
    // Not in a vertical scrollable: nothing to wait for, it is on screen.
    if (scrollable == null) {
      _static = true;
      _play(fromAbove: false, fast: false);
      return;
    }

    final box = context.findRenderObject();
    final viewport = scrollable.context.findRenderObject();
    // Not laid out yet: its first paint asks again.
    if (box is! RenderBox ||
        !box.attached ||
        !box.hasSize ||
        viewport is! RenderBox ||
        !viewport.hasSize) {
      return;
    }

    final position = scrollable.position;
    _watch(position);
    // Measured on every check, so the speed is fresh when an item plays.
    final fast = _isFlung(position);

    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final bottom = top + box.size.height;
    final height = viewport.size.height;
    final inset = ScrollReveal.edgeInset.clamp(0.0, height / 4);
    final firstLook = !_measured;
    _measured = true;

    if (bottom <= 0 || top >= height) {
      // Wholly off screen: re-armed for its next arrival.
      if (_visible) _hide();
      return;
    }
    if (_visible) return;

    if (firstLook) {
      // On screen as the list appears: rises in. Peeking in at the top on
      // the first look (a restored offset) counts as coming from above.
      if (top < height - inset) _play(fromAbove: top < 0, fast: fast);
      return;
    }
    if ((top + bottom) / 2 < height / 2) {
      // Entering across the top edge — the reader is scrolling up.
      if (bottom > math.min(inset, box.size.height / 2)) {
        _play(fromAbove: true, fast: fast);
      }
    } else if (top < height - inset) {
      _play(fromAbove: false, fast: fast);
    }
  }

  /// The page's scroll speed, measured frame to frame and shared by every
  /// item on it: (pixels, frame stamp, speed in px/s).
  static final Expando<(double, Duration, double)> _speed = Expando();

  static bool _isFlung(ScrollPosition position) {
    if (!position.hasPixels) return false;
    final stamp = SchedulerBinding.instance.currentFrameTimeStamp;
    final last = _speed[position];
    var speed = 0.0;
    if (last != null) {
      if (last.$2 == stamp) return last.$3 > ScrollReveal.flingVelocity;
      final seconds = (stamp - last.$2).inMicroseconds / 1e6;
      if (seconds > 0 && seconds < 0.25) {
        speed = (position.pixels - last.$1).abs() / seconds;
      }
    }
    _speed[position] = (position.pixels, stamp, speed);
    return speed > ScrollReveal.flingVelocity;
  }

  void _watch(ScrollPosition position) {
    if (identical(position, _position)) return;
    _stopWatching();
    _position = position..addListener(_scheduleCheck);
  }

  void _stopWatching() {
    _position?.removeListener(_scheduleCheck);
    _position = null;
  }

  void _showForGood() {
    _static = true;
    _visible = true;
    _stopWatching();
    _controller?.stop();
    if (!mounted) return;
    setState(() => _progress = kAlwaysCompleteAnimation);
  }

  void _hide() {
    _visible = false;
    _controller?.stop();
    setState(() => _progress = kAlwaysDismissedAnimation);
  }

  void _play({required bool fromAbove, required bool fast}) {
    _visible = true;
    _fromAbove = fromAbove;

    var slot = 0;
    if (!fast) {
      slot = _batchSize.clamp(0, ScrollReveal.maxStagger);
      _batchSize++;
      if (!_batchResetScheduled) {
        _batchResetScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _batchSize = 0;
          _batchResetScheduled = false;
        });
      }
    }

    final run = fast
        ? AppDurations.scrollReveal * 0.55
        : AppDurations.scrollReveal;
    final delay = AppDurations.listStagger * slot;
    final total = delay + run;
    // One controller for the item's whole life: it re-plays on every arrival.
    final controller = _controller ??= AnimationController(vsync: this);
    controller.duration = total;
    setState(() {
      _progress = CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.inMicroseconds / total.inMicroseconds,
          1,
          curve: AppCurves.reveal,
        ),
      );
    });
    controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return _RevealProbe(
      onPaint: _static || _visible ? null : _scheduleCheck,
      child: FadeTransition(
        // The reveal curve overshoots a hair; opacity must not.
        opacity: _progress.drive(_clampUnit),
        alwaysIncludeSemantics: true,
        child: _Arrive(
          progress: _progress,
          fromAbove: _fromAbove,
          child: widget.child,
        ),
      ),
    );
  }

  static const Animatable<double> _clampUnit = _ClampUnit();
}

/// Keeps an overshooting value inside 0–1.
class _ClampUnit extends Animatable<double> {
  const _ClampUnit();

  @override
  double transform(double t) => t.clamp(0.0, 1.0);
}

/// The movement half of the entrance: grow from [ScrollReveal.startScale]
/// while travelling [ScrollReveal.rise] from below — or from above.
class _Arrive extends AnimatedWidget {
  const _Arrive({
    required Animation<double> progress,
    required this.fromAbove,
    required this.child,
  }) : super(listenable: progress);

  final bool fromAbove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final value = (listenable as Animation<double>).value;
    final scale =
        ScrollReveal.startScale + (1 - ScrollReveal.startScale) * value;
    return Transform(
      alignment: fromAbove ? Alignment.topCenter : Alignment.bottomCenter,
      transform: Matrix4.translationValues(
        0,
        (1 - value) * ScrollReveal.rise * (fromAbove ? -1 : 1),
        0,
      )..scaleByDouble(scale, scale, 1, 1),
      child: child,
    );
  }
}

/// Tells the item it has been painted.
///
/// A list does not paint the items it builds ahead of the viewport, so a
/// first paint means «on screen now» — and it arrives even when nothing
/// scrolled: a viewport that grew (a header collapsing, a rotation) paints
/// items the scroll listener would never have heard about.
class _RevealProbe extends SingleChildRenderObjectWidget {
  const _RevealProbe({required this.onPaint, required super.child});

  final VoidCallback? onPaint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRevealProbe(onPaint);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRevealProbe renderObject,
  ) {
    renderObject.onPaint = onPaint;
  }
}

class _RenderRevealProbe extends RenderProxyBox {
  _RenderRevealProbe(this.onPaint);

  VoidCallback? onPaint;

  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint?.call();
    super.paint(context, offset);
  }
}

/// `child.revealOnScroll()` — the same as wrapping it in [ScrollReveal].
///
/// Pass [id] when the row is keyed — a row that animates out on a swipe,
/// a list that reorders. The wrapper then carries a key of its own, so a
/// row that leaves takes its wrapper with it instead of handing the next
/// row an element under a mismatched key (which would rebuild that row
/// from scratch).
extension ScrollRevealExtension on Widget {
  Widget revealOnScroll({bool enabled = true, Object? id}) => ScrollReveal(
    key: id == null ? null : ScrollRevealKey(id),
    enabled: enabled,
    child: this,
  );
}

/// The key of a [ScrollReveal] around a keyed row — a type of its own, so
/// it never equals the row's own `ValueKey` and `find.byKey` still finds
/// exactly one widget.
class ScrollRevealKey extends ValueKey<Object> {
  const ScrollRevealKey(super.value);
}
