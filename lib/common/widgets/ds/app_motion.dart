/// Small, reusable motion pieces, used wherever the same element appears
/// across the app.
///
/// Every one of them is FINITE (it plays and stops), so a screen never keeps
/// a ticker running once it has settled, and every one of them shows its
/// final state at once under reduced motion.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/constants/design_constants.dart';
import '../../../utils/helpers/app_formats.dart';
import '../nav_bar_visibility.dart';
import 'app_icons.dart';

bool _reduced(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// A number that counts up from zero the first time it is shown — the
/// «الكل · 24» count on a section header.
class AppCountUp extends StatelessWidget {
  const AppCountUp({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  static const Duration duration = Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    if (_reduced(context)) {
      return Text(AppFormats.number(context, value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        AppFormats.number(context, v.round()),
        style: style?.copyWith(
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
        semanticsLabel: AppFormats.number(context, value),
      ),
    );
  }
}

/// The short accent bar under a section title, drawn in from the reading
/// start the first time it appears.
class AppAccentLine extends StatefulWidget {
  const AppAccentLine({
    super.key,
    this.color,
    this.width = 26,
    this.height = 3.5,
  });

  final Color? color;
  final double width;
  final double height;

  @override
  State<AppAccentLine> createState() => _AppAccentLineState();
}

class _AppAccentLineState extends State<AppAccentLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draw.isAnimating || _draw.isCompleted) return;
    if (_reduced(context)) {
      _draw.value = 1;
    } else {
      _draw.forward();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _draw,
          builder: (context, _) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: Curves.easeOutCubic.transform(
                _draw.value.clamp(0.0, 1.0),
              ),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.height),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A band of light that crosses its child ONCE, shortly after it first
/// appears — discount badges.
class AppGlint extends StatefulWidget {
  const AppGlint({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration delay;

  @override
  State<AppGlint> createState() => _AppGlintState();
}

class _AppGlintState extends State<AppGlint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _start;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_start != null || _sweep.isAnimating || _sweep.isCompleted) return;
    if (_reduced(context)) {
      _sweep.value = 1;
      return;
    }
    _start = Timer(widget.delay, () {
      if (mounted) _sweep.forward();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweep,
      child: widget.child,
      builder: (context, child) {
        final t = _sweep.value;
        // Before and after its one pass the glint draws nothing, and a
        // `ShaderMask` left in place is an offscreen layer on every frame
        // for every badge on screen.
        if (t <= 0 || t >= 1) return child!;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final x = -bounds.width + t * bounds.width * 3;
            return LinearGradient(
              colors: <Color>[
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const <double>[0.3, 0.5, 0.7],
            ).createShader(
              Rect.fromLTWH(
                x - bounds.width,
                0,
                bounds.width * 2,
                bounds.height,
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}

/// A photo that zooms very slowly while it is the one being looked at — the
/// pinned news slide, detail-page heroes. One slow pass, then rest.
class AppKenBurns extends StatefulWidget {
  const AppKenBurns({super.key, required this.child, this.active = true});

  final Widget child;

  /// Only the slide on screen zooms; the others wait at 1×.
  final bool active;

  static const Duration duration = Duration(seconds: 12);
  static const double endScale = 1.08;

  @override
  State<AppKenBurns> createState() => _AppKenBurnsState();
}

class _AppKenBurnsState extends State<AppKenBurns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: AppKenBurns.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AppKenBurns oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    if (_reduced(context)) {
      _zoom.value = 0;
      return;
    }
    if (widget.active) {
      if (!_zoom.isAnimating && !_zoom.isCompleted) _zoom.forward();
    } else {
      _zoom.value = 0;
    }
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _zoom,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale:
              1 +
              (AppKenBurns.endScale - 1) *
                  Curves.easeInOut.transform(_zoom.value),
          child: child,
        ),
      ),
    );
  }
}

/// A picture that moves slower than the page as it scrolls — the
/// Flutter cookbook's parallax, measured against the nearest VERTICAL
/// scrollable so it also works inside a horizontal carousel.
///
/// The child is drawn [overscan] taller than the box and shifted within it.
class AppParallax extends StatelessWidget {
  const AppParallax({
    super.key,
    required this.child,
    this.factor = 0.5,
    this.overscan = 0.25,
  });

  final Widget child;

  /// 0.5: the picture travels at half the page's speed.
  final double factor;

  /// How much taller than the box the picture is drawn, as a fraction.
  final double overscan;

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (scrollable == null || _reduced(context)) return child;
    return ClipRect(
      child: Flow(
        delegate: _ParallaxDelegate(
          position: scrollable.position,
          scrollable: scrollable,
          item: context,
          factor: factor,
          overscan: overscan,
        ),
        children: <Widget>[child],
      ),
    );
  }
}

class _ParallaxDelegate extends FlowDelegate {
  _ParallaxDelegate({
    required this.position,
    required this.scrollable,
    required this.item,
    required this.factor,
    required this.overscan,
  }) : super(repaint: position);

  final ScrollPosition position;
  final ScrollableState scrollable;
  final BuildContext item;
  final double factor;
  final double overscan;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    final h = constraints.maxHeight;
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      height: h.isFinite ? h * (1 + overscan) : null,
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final viewport = scrollable.context.findRenderObject();
    final box = item.findRenderObject();
    if (viewport is! RenderBox || box is! RenderBox || !box.hasSize) {
      context.paintChild(0);
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final extra = context.size.height * overscan;
    // At the top of the page the picture is centred in its overscan; as the
    // box scrolls up by d, the picture moves down by d × factor, clamped.
    final shift = (-top * factor).clamp(-extra / 2, extra / 2);
    context.paintChild(
      0,
      transform: Matrix4.translationValues(0, -extra / 2 + shift, 0),
    );
  }

  @override
  bool shouldRepaint(_ParallaxDelegate old) =>
      position != old.position || factor != old.factor;
}

/// Springs a tile in, [index] × 45ms after the first — section tiles, the
/// store category grid. Once, when first built.
class AppPopIn extends StatefulWidget {
  const AppPopIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<AppPopIn> createState() => _AppPopInState();
}

class _AppPopInState extends State<AppPopIn>
    with SingleTickerProviderStateMixin {
  static const Duration _each = Duration(milliseconds: 460);
  late final AnimationController _pop = AnimationController(vsync: this);
  late Animation<double> _t = kAlwaysCompleteAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pop.isAnimating || _pop.isCompleted) return;
    if (_reduced(context)) {
      _pop.value = 1;
      _t = kAlwaysCompleteAnimation;
      return;
    }
    final delay = AppDurations.listStagger * math.min(widget.index, 8);
    final total = delay + _each;
    _pop.duration = total;
    _t = CurvedAnimation(
      parent: _pop,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppCurves.spring,
      ),
    );
    _pop.forward();
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.6 + 0.4 * v, child: child),
        );
      },
    );
  }
}

/// Slides a horizontal rail a little toward its hidden end and back, ONCE per
/// [id] per app run — the hint that it scrolls sideways.
class AppRailNudge extends StatefulWidget {
  const AppRailNudge({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  static final Set<String> _played = <String>{};

  /// Tests start every app run fresh.
  @visibleForTesting
  static void reset() => _played.clear();

  @override
  State<AppRailNudge> createState() => _AppRailNudgeState();
}

class _AppRailNudgeState extends State<AppRailNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _start;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_start != null || AppRailNudge._played.contains(widget.id)) return;
    if (_reduced(context)) return;
    AppRailNudge._played.add(widget.id);
    _start = Timer(const Duration(milliseconds: 900), () {
      if (mounted) _nudge.forward();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The hidden cards lie toward the END edge: left in Arabic. Showing a
    // peek of them means moving the row toward the START edge… and back.
    final toStart = Directionality.of(context) == TextDirection.rtl ? 1 : -1;
    return AnimatedBuilder(
      animation: _nudge,
      child: widget.child,
      builder: (context, child) {
        final t = _nudge.value;
        final out = t < 0.45
            ? Curves.easeOut.transform(t / 0.45)
            : 1 - Curves.easeInOut.transform((t - 0.45) / 0.55);
        return Transform.translate(
          offset: Offset(-toStart * 32 * out, 0),
          child: child,
        );
      },
    );
  }
}

/// A round «back to top» button that springs in after the list has scrolled
/// two screens, and scrolls it back up. Put it in a [Stack] over the
/// list, above the floating navigation bar.
class AppBackToTop extends StatefulWidget {
  const AppBackToTop({
    super.key,
    required this.controller,
    required this.label,
    this.bottom = 0,
  });

  final ScrollController controller;

  /// What a screen reader hears — «العودة إلى الأعلى».
  final String label;

  /// Distance from the bottom of the stack (clear of the navigation bar).
  final double bottom;

  /// How far the button drops while the bar is tucked into its dock.
  static const double barDrop = 20;

  @override
  State<AppBackToTop> createState() => _AppBackToTopState();
}

class _AppBackToTopState extends State<AppBackToTop> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AppBackToTop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final c = widget.controller;
    if (!c.hasClients || c.positions.length != 1) return;
    final pos = c.position;
    final shown = pos.pixels > pos.viewportDimension * 2;
    if (shown != _shown) setState(() => _shown = shown);
  }

  void _toTop() {
    final c = widget.controller;
    if (!c.hasClients) return;
    unawaited(HapticFeedback.selectionClick());
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      c.jumpTo(0);
      return;
    }
    unawaited(
      c.animateTo(
        0,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // When the bottom bar tucks into its dock, the button rides down with it
    // into the space it left.
    final barHidden = NavBarVisibilityScope.maybeOf(context)?.hidden ?? false;
    return AnimatedPositionedDirectional(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      start: AppSpacing.screenMargin,
      bottom:
          widget.bottom +
          AppSpacing.md -
          (barHidden ? AppBackToTop.barDrop : 0),
      child: IgnorePointer(
        ignoring: !_shown,
        child: AnimatedScale(
          scale: _shown ? 1 : 0,
          duration: _shown
              ? const Duration(milliseconds: 320)
              : const Duration(milliseconds: 160),
          curve: _shown ? AppCurves.spring : AppCurves.exit,
          child: Semantics(
            button: true,
            label: widget.label,
            excludeSemantics: true,
            // A circle's shadow drawn directly; Material's elevation blurs
            // the shape offscreen on every frame of a scroll.
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: colors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toTop,
                  child: SizedBox.square(
                    dimension: AppIconSizes.navTouchTarget,
                    child: Center(
                      child: AppIcon(
                        AppIcons.arrowUp,
                        color: colors.onPrimary,
                        size: AppIconSizes.bar,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's pull-to-refresh: the `primary` ring on a raised surface disc,
/// pulled a little further than Material's default, with a tick of haptics
/// the moment it lets go. Every refreshable list uses this, not
/// [RefreshIndicator] directly.
class AppRefresh extends StatelessWidget {
  const AppRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
    this.displacement = 56,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final double edgeOffset;
  final double displacement;
  final ScrollNotificationPredicate notificationPredicate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () {
        unawaited(HapticFeedback.mediumImpact());
        return onRefresh();
      },
      color: colors.primary,
      backgroundColor: colors.surface,
      strokeWidth: 2.8,
      elevation: 3,
      edgeOffset: edgeOffset,
      displacement: displacement,
      notificationPredicate: notificationPredicate,
      child: child,
    );
  }
}

/// One part of an opening choreography: fades in over [start]–[end] of
/// [animation] (0 → 1) while travelling [dy] and growing from [scale].
///
/// Drive several slots from ONE controller with staggered intervals — a
/// header, then a search field, then a hero — and play it once per app run
/// ([AppIntro]).
class AppIntroSlot extends StatelessWidget {
  const AppIntroSlot({
    super.key,
    required this.animation,
    required this.child,
    this.start = 0,
    this.end = 1,
    this.dy = 0,
    this.scale = 1,
    this.curve = AppCurves.enter,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final double dy;
  final double scale;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: curve),
    );
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => Opacity(
        opacity: t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t.value) * dy),
          child: Transform.scale(
            scale: scale + (1 - scale) * t.value,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Plays an opening choreography once per app run per [id].
///
/// ```dart
/// late final _intro = AnimationController(vsync: this, duration: AppIntro.duration);
///
/// @override
/// void didChangeDependencies() {
///   super.didChangeDependencies();
///   AppIntro.play(context, _intro, id: 'feed');
/// }
/// ```
///
/// Coming back to a tab is not an opening: the second call shows the end
/// state at once. Reduced motion always shows the end state.
class AppIntro {
  AppIntro._();

  static const Duration duration = Duration(milliseconds: 1100);

  static final Set<String> _played = <String>{};

  /// Tests start every app run fresh.
  @visibleForTesting
  static void reset() => _played.clear();

  static void play(
    BuildContext context,
    AnimationController controller, {
    required String id,
  }) {
    if (controller.isAnimating || controller.isCompleted) return;
    if (_played.contains(id) || _reduced(context)) {
      controller.value = 1;
      return;
    }
    _played.add(id);
    controller.forward();
  }
}

/// A hint whose last word rotates — «Search for *news*…», then *places*,
/// then *people* — so it teaches what a search covers.
///
/// The timer rests while the widget is hidden (another tab, a page pushed
/// over it: `TickerMode` off) and under reduced motion, so an unseen hint
/// never rebuilds.
class AppRotatingHint extends StatefulWidget {
  const AppRotatingHint({
    super.key,
    required this.prefix,
    required this.words,
    this.style,
    this.interval = const Duration(milliseconds: 2600),
  });

  final String prefix;
  final List<String> words;
  final TextStyle? style;
  final Duration interval;

  @override
  State<AppRotatingHint> createState() => _AppRotatingHintState();
}

class _AppRotatingHintState extends State<AppRotatingHint> {
  Timer? _timer;
  int _word = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    _timer?.cancel();
    _timer = _reduced(context) || !visible || widget.words.length < 2
        ? null
        : Timer.periodic(widget.interval, (_) {
            if (mounted) setState(() => _word++);
          });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final word = words.isEmpty ? '' : words[_word % words.length];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            '${widget.prefix} ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: AppCurves.enter,
          switchOutCurve: AppCurves.exit,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            '$word…',
            key: ValueKey<String>(word),
            maxLines: 1,
            style: widget.style,
          ),
        ),
      ],
    );
  }
}
