/// Loading skeletons that cannot drift from the widget they stand for.
///
/// The usual way to build a skeleton is to write a second widget that *looks
/// like* the real one. It is wrong within a month: someone adds a line to the
/// card and forgets the skeleton, and the loading state quietly stops matching
/// what loads in.
///
/// Here there is **one layout**. The leaves swap, and [SkeletonWidget] owns
/// the rest:
///
/// ```dart
/// class NewsCard extends SkeletonWidget {
///   const NewsCard.success(NewsEntity this.news, {super.key})
///     : super.success();
///
///   const NewsCard.loading({super.key}) : news = null, super.loading();
///
///   final NewsEntity? news;
///
///   @override
///   Widget buildBody(BuildContext context) {
///     return AppCard(
///       child: Row(
///         children: [
///           SkeletonBox(width: 56, height: 46, child: AppThumbnail(...)),
///           SkeletonText(news?.title, style: context.titleSmall, maxLines: 2),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// Add a line to that `Row` and the skeleton grows a line too, because there is
/// only one `Row`. That is the whole point — a change to the card is a change
/// to its skeleton, always, with no second place to remember.
///
/// How loading looks:
/// - **Synced sweep.** Every block paints its own gradient, but in SCREEN
///   coordinates and from the frame clock, so one band of light crosses the
///   whole screen and every skeleton lights up as it passes — in step.
/// - **Two-tone.** Picture blocks ([SkeletonTone.media]) are darker than text
///   bars ([SkeletonTone.text]); the card's shape reads at a glance.
/// - **300ms delay, 500ms minimum.** A skeleton stays invisible (its space
///   reserved) for [AppDurations.loaderThreshold]; once it has shown, it stays
///   at least [SkeletonScope.minimumVisible], so nothing flashes.
/// - **Leaves rise in.** When data lands, pictures and text fade up 8dp one
///   after another instead of snapping in.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../../utils/constants/design_constants.dart';

/// A widget with two constructors — `.success(...)` and `.loading()` — over
/// ONE layout, written once in [buildBody].
///
/// The base does what every loadable widget used to repeat by hand: it wraps
/// the body in a [SkeletonScope], and while loading it ignores taps and hides
/// the placeholder from screen readers (a skeleton has nothing to say).
///
/// Dart does not inherit constructors, so each subclass declares its two
/// one-line constructors and forwards to `super.success()` /
/// `super.loading()`. Its data fields are nullable and null while loading.
abstract class SkeletonWidget extends StatelessWidget {
  const SkeletonWidget.success({super.key}) : isLoading = false;

  const SkeletonWidget.loading({super.key}) : isLoading = true;

  /// True for the `.loading()` constructor.
  final bool isLoading;

  /// The one layout for both states. Use [SkeletonText], [SkeletonBox],
  /// [SkeletonBar] and [SkeletonShape] for the leaves that carry data.
  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final body = buildBody(context);
    return SkeletonScope(
      isLoading: isLoading,
      // Only while loading: loaded, the body's own render object must be the
      // widget's first, so its semantics node is the card's one sentence.
      child: isLoading
          ? IgnorePointer(child: ExcludeSemantics(child: body))
          : body,
    );
  }
}

/// Marks a subtree as loading and drives its shimmer and its arrival.
///
/// Wrap the OUTERMOST widget of the thing being loaded, not each leaf.
/// [SkeletonWidget] does this for you.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  /// Once a skeleton has become visible, it stays at least this long.
  static const Duration minimumVisible = Duration(milliseconds: 500);

  /// How long the skeleton takes to fade in after the delay.
  static const Duration fadeIn = Duration(milliseconds: 180);

  /// The arrival of the real content: each leaf rises over [leafDuration],
  /// [leafStagger] after the previous one, at most [maxLeafSlots] deep.
  static const Duration leafDuration = Duration(milliseconds: 320);
  static const Duration leafStagger = Duration(milliseconds: 45);
  static const int maxLeafSlots = 5;
  static const double leafRise = 8;

  /// Whether the nearest enclosing scope is loading. False when there is none,
  /// so a leaf used outside a scope simply renders its content.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_SkeletonMarker>()
          ?.isLoading ??
      false;

  static _SkeletonMarker? _markerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonMarker>();

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with TickerProviderStateMixin {
  /// Only drives repaints; the sweep's position comes from the frame clock,
  /// which is what keeps every skeleton on screen in step.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  );

  /// 0 while the skeleton waits out the delay, 1 once it shows.
  late final AnimationController _visibility = AnimationController(
    vsync: this,
    duration: SkeletonScope.fadeIn,
  );

  /// The leaves' arrival, 0 → 1. Complete when nothing is arriving.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration:
        SkeletonScope.leafDuration +
        SkeletonScope.leafStagger * SkeletonScope.maxLeafSlots,
    value: 1,
  );

  late bool _loading = widget.isLoading;
  Timer? _delay;
  Timer? _hold;
  Duration? _shownAt;
  int _generation = 0;
  int _nextSlot = 0;

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    if (_loading) _startLoading();
  }

  @override
  void didUpdateWidget(SkeletonScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading == oldWidget.isLoading) return;
    if (widget.isLoading) {
      _hold?.cancel();
      if (!_loading) {
        setState(() => _loading = true);
        _startLoading();
      }
    } else {
      _finishLoading();
    }
  }

  void _startLoading() {
    _shownAt = null;
    _visibility.value = 0;
    _delay?.cancel();
    _delay = Timer(AppDurations.loaderThreshold, () {
      if (!mounted || !_loading) return;
      _shownAt = _now;
      _visibility.forward();
      if (!_reducedMotion) _sweep.repeat();
    });
  }

  void _finishLoading() {
    _delay?.cancel();
    final shownAt = _shownAt;
    if (shownAt != null) {
      final left = SkeletonScope.minimumVisible - (_now - shownAt);
      if (left > Duration.zero) {
        _hold?.cancel();
        _hold = Timer(left, () {
          if (mounted && !widget.isLoading) _arrive();
        });
        return;
      }
    }
    _arrive();
  }

  void _arrive() {
    _sweep.stop();
    _shownAt = null;
    setState(() {
      _loading = false;
      _generation++;
      _nextSlot = 0;
    });
    if (_reducedMotion) {
      _reveal.value = 1;
    } else {
      _reveal.forward(from: 0);
    }
  }

  Duration get _now => Duration(microseconds: _clock.elapsedMicroseconds);
  static final Stopwatch _clock = Stopwatch()..start();

  int _claimSlot() => math.min(_nextSlot++, SkeletonScope.maxLeafSlots);

  @override
  void dispose() {
    _delay?.cancel();
    _hold?.cancel();
    _sweep.dispose();
    _visibility.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SkeletonMarker(
      isLoading: _loading,
      generation: _generation,
      sweep: _sweep,
      visibility: _visibility,
      reveal: _reveal,
      claimSlot: _claimSlot,
      child: widget.child,
    );
  }
}

class _SkeletonMarker extends InheritedWidget {
  const _SkeletonMarker({
    required this.isLoading,
    required this.generation,
    required this.sweep,
    required this.visibility,
    required this.reveal,
    required this.claimSlot,
    required super.child,
  });

  final bool isLoading;
  final int generation;
  final Animation<double> sweep;
  final Animation<double> visibility;
  final Animation<double> reveal;
  final int Function() claimSlot;

  @override
  bool updateShouldNotify(_SkeletonMarker oldWidget) =>
      oldWidget.isLoading != isLoading || oldWidget.generation != generation;
}

/// Fades a loaded leaf up into place when its scope's data has just landed.
/// Outside an arrival it is a no-op wrapper (opacity 1, no offset).
class _LeafReveal extends StatefulWidget {
  const _LeafReveal({required this.child});

  final Widget child;

  @override
  State<_LeafReveal> createState() => _LeafRevealState();
}

class _LeafRevealState extends State<_LeafReveal> {
  int _generation = -1;
  int _slot = 0;

  @override
  Widget build(BuildContext context) {
    final marker = SkeletonScope._markerOf(context);
    if (marker == null || marker.generation == 0) return widget.child;
    if (marker.generation != _generation) {
      _generation = marker.generation;
      _slot = marker.claimSlot();
    }

    final total =
        SkeletonScope.leafDuration +
        SkeletonScope.leafStagger * SkeletonScope.maxLeafSlots;
    final start =
        (SkeletonScope.leafStagger * _slot).inMicroseconds /
        total.inMicroseconds;
    final end =
        start +
        SkeletonScope.leafDuration.inMicroseconds / total.inMicroseconds;
    final progress = CurvedAnimation(
      parent: marker.reveal,
      curve: Interval(start, math.min(1, end), curve: AppCurves.enter),
    );

    return AnimatedBuilder(
      animation: progress,
      child: widget.child,
      // Always the same two wrappers, even at rest: swapping them out when the
      // arrival ends would remount the child — a picture would reload.
      builder: (context, child) {
        final t = progress.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * SkeletonScope.leafRise),
            child: child,
          ),
        );
      },
    );
  }
}

/// Which of the two skeleton tones a block takes.
enum SkeletonTone {
  /// Pictures, avatars, icon tiles — the darker tone.
  media,

  /// Text bars, chips, badges — the lighter tone.
  text,
}

/// Text that becomes shimmer bars of the SAME height while loading.
///
/// The bars are measured from the resolved [TextStyle], so a skeleton line
/// occupies exactly the space its sentence will occupy. Guessing a height here
/// is what makes a card jump when the data arrives.
class SkeletonText extends StatelessWidget {
  const SkeletonText(
    this.data, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.loadingWidthFactor = 1,
    this.lastLineFactor = 0.62,
    this.highlight,
    this.shrinkToFit = false,
  });

  /// The real text. May be null while loading.
  final String? data;

  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final TextOverflow overflow;

  /// How much of the available width a skeleton line fills.
  final double loadingWidthFactor;

  /// The last line is shorter, the way a real paragraph ends mid-line. A block
  /// of equal-length bars reads as a table, not as prose.
  final double lastLineFactor;

  /// The run of [data] to mark, as `(start, length)`.
  ///
  /// This is search's query highlight, and it lives
  /// here rather than in each result component because `Q5B` wants it
  /// applied to every native one **through one shared text handler** — five
  /// copies of a span-splitting routine is five places for RTL to go wrong.
  ///
  /// A range that does not fit the text is ignored rather than clipped: the
  /// server computed it against the title it sent, and a mismatch means the
  /// two have drifted, not that the reader should see a half-marked word.
  final (int, int)? highlight;

  /// One line that scales down to the width instead of losing its end.
  ///
  /// For text whose end is the point — a price, where «4,500,000 US…» hides
  /// the currency. The line keeps the height one
  /// line of [style] takes, so the widget is as tall as its skeleton and as
  /// every other card in the rail; only the glyphs get smaller.
  final bool shrinkToFit;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DefaultTextStyle.of(context).style;

    if (!SkeletonScope.of(context)) {
      return _LeafReveal(child: _text(context));
    }

    final fontSize = resolved.fontSize ?? 14;
    final lineHeight = fontSize * (resolved.height ?? 1.4);
    // Glyphs occupy roughly three quarters of their line box; a bar the full
    // line height reads as a solid block rather than as text.
    final barHeight = fontSize * 0.72;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var line = 0; line < maxLines; line++)
          SizedBox(
            height: lineHeight,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: line == maxLines - 1 && maxLines > 1
                    ? lastLineFactor
                    : loadingWidthFactor,
                child: _SkeletonFill(height: barHeight),
              ),
            ),
          ),
      ],
    );
  }
}

extension on SkeletonText {
  Widget _text(BuildContext context) {
    final text = data ?? '';
    if (shrinkToFit) return _shrunk(context, text);
    final marked = _marked(context, text);
    if (marked == null) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow,
      );
    }
    return Text.rich(
      marked,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
      // The mark is decoration: a screen reader hears the sentence, not
      // the three pieces it is drawn in.
      semanticsLabel: text,
    );
  }

  /// [text] on one line, scaled down inside the height of one line.
  Widget _shrunk(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();

    return SizedBox(
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: style, maxLines: 1, textAlign: textAlign),
      ),
    );
  }

  /// The three spans a highlight splits the text into, or null when there is
  /// nothing to mark.
  ///
  /// `primaryContainer` behind `onPrimaryContainer`, which is the pair the
  /// chips already use. A padded, rounded mark would look nicer, but a
  /// `TextSpan` background can carry neither,
  /// and a `WidgetSpan` that could would break the line-breaking of the
  /// title it sits inside.
  InlineSpan? _marked(BuildContext context, String text) {
    final range = highlight;
    if (range == null || text.isEmpty) return null;
    final (start, length) = range;
    if (start < 0 || length <= 0 || start + length > text.length) return null;

    final colors = Theme.of(context).colorScheme;
    return TextSpan(
      children: <InlineSpan>[
        TextSpan(text: text.substring(0, start)),
        TextSpan(
          text: text.substring(start, start + length),
          style: TextStyle(
            backgroundColor: colors.primaryContainer,
            color: colors.onPrimaryContainer,
          ),
        ),
        TextSpan(text: text.substring(start + length)),
      ],
    );
  }
}

/// A box — image, avatar, icon tile — that becomes a shimmer block.
///
/// [width] and [height] are the box's real size, so the block reserves exactly
/// the space the picture will take and nothing shifts when it arrives.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.radius = AppRadii.md,
    this.shape = BoxShape.rectangle,
    this.tone = SkeletonTone.media,
  });

  /// A circular block — avatars, icon discs.
  const SkeletonBox.circle({
    super.key,
    required this.child,
    required double size,
    this.tone = SkeletonTone.media,
  }) : width = size,
       height = size,
       radius = 0,
       shape = BoxShape.circle;

  final Widget child;
  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;
  final SkeletonTone tone;

  @override
  Widget build(BuildContext context) {
    if (!SkeletonScope.of(context)) {
      return SizedBox(
        width: width,
        height: height,
        child: _LeafReveal(child: child),
      );
    }

    return _SkeletonFill(
      width: width,
      height: height,
      radius: radius,
      shape: shape,
      tone: tone,
    );
  }
}

/// A child that keeps its own size while loading but is painted as one block —
/// a badge, a button, a chip whose size comes from its content.
///
/// The child is laid out invisibly, so the block is exactly as big as the
/// real thing will be.
class SkeletonShape extends StatelessWidget {
  const SkeletonShape({
    super.key,
    required this.child,
    this.radius = AppRadii.xs,
    this.tone = SkeletonTone.text,
  });

  final Widget child;
  final double radius;
  final SkeletonTone tone;

  @override
  Widget build(BuildContext context) {
    if (!SkeletonScope.of(context)) return _LeafReveal(child: child);
    return Stack(
      children: <Widget>[
        Opacity(opacity: 0, child: child),
        Positioned.fill(
          child: _SkeletonFill(radius: radius, tone: tone),
        ),
      ],
    );
  }
}

/// A bar with no real counterpart — a chip, a divider, a badge.
///
/// Renders nothing when not loading, so it never leaves a gap in the real card.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadii.full,
    this.tone = SkeletonTone.text,
  });

  final double width;
  final double height;
  final double radius;
  final SkeletonTone tone;

  @override
  Widget build(BuildContext context) {
    if (!SkeletonScope.of(context)) return const SizedBox.shrink();
    return _SkeletonFill(
      width: width,
      height: height,
      radius: radius,
      tone: tone,
    );
  }
}

/// Repeats a loading item to fill a list.
///
/// Uses the SAME widget the list uses, through its `.loading()` constructor —
/// so a list skeleton is the list, not a drawing of it.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 6,
    this.separator = AppSpacing.cardGap,
    this.padding,
  });

  final WidgetBuilder itemBuilder;
  final int itemCount;
  final double separator;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      // A skeleton must never be scrollable: dragging a placeholder feels
      // broken, and the list is replaced the moment data lands anyway.
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: separator),
      itemBuilder: (context, _) => itemBuilder(context),
    );
  }
}

/// The next page arriving at the end of a list: two `.loading()` rows of the
/// list's own row, where a spinner used to sit.
///
/// The same pattern as the first load, and no jump when the rows land.
class SkeletonMore extends StatelessWidget {
  const SkeletonMore({
    super.key,
    required this.itemBuilder,
    this.count = 2,
    this.separator = AppSpacing.cardGap,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.screenMargin,
    ),
  });

  final WidgetBuilder itemBuilder;
  final int count;
  final double separator;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < count; i++) ...<Widget>[
            if (i > 0) SizedBox(height: separator),
            itemBuilder(context),
          ],
        ],
      ),
    );
  }
}

/// The two tones and their highlight, from the theme — so the skeleton follows
/// light and dark without a colour of its own.
@immutable
class _SkeletonColors {
  const _SkeletonColors(this.base, this.highlight);

  final Color base;
  final Color highlight;

  static _SkeletonColors of(BuildContext context, SkeletonTone tone) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final ink = tone == SkeletonTone.media
        ? (dark ? 0.12 : 0.085)
        : (dark ? 0.075 : 0.05);
    final base = Color.alphaBlend(
      colors.onSurface.withValues(alpha: ink),
      colors.surface,
    );
    final highlight = dark
        ? Color.lerp(base, colors.onSurface, 0.1)!
        : Color.lerp(base, Colors.white, 0.75)!;
    return _SkeletonColors(base, highlight);
  }
}

/// One skeleton block. Paints its own sweep, placed in screen space from the
/// frame clock, so every block on screen shows the same band of light.
class _SkeletonFill extends LeafRenderObjectWidget {
  const _SkeletonFill({
    this.width,
    this.height,
    this.radius = AppRadii.xs,
    this.shape = BoxShape.rectangle,
    this.tone = SkeletonTone.text,
  });

  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;
  final SkeletonTone tone;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final marker = SkeletonScope._markerOf(context);
    final colors = _SkeletonColors.of(context, tone);
    return _RenderSkeletonFill(
      width: width,
      height: height,
      radius: radius,
      shape: shape,
      base: colors.base,
      highlight: colors.highlight,
      rtl: Directionality.of(context) == TextDirection.rtl,
      screen: MediaQuery.sizeOf(context),
      sweep: marker?.sweep,
      visibility: marker?.visibility,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSkeletonFill renderObject,
  ) {
    final marker = SkeletonScope._markerOf(context);
    final colors = _SkeletonColors.of(context, tone);
    renderObject
      ..width = width
      ..height = height
      ..radius = radius
      ..shape = shape
      ..base = colors.base
      ..highlight = colors.highlight
      ..rtl = Directionality.of(context) == TextDirection.rtl
      ..screen = MediaQuery.sizeOf(context)
      ..setAnimations(marker?.sweep, marker?.visibility);
  }
}

class _RenderSkeletonFill extends RenderBox {
  _RenderSkeletonFill({
    required double? width,
    required double? height,
    required double radius,
    required BoxShape shape,
    required Color base,
    required Color highlight,
    required bool rtl,
    required Size screen,
    required Animation<double>? sweep,
    required Animation<double>? visibility,
  }) : _width = width,
       _height = height,
       _radius = radius,
       _shape = shape,
       _base = base,
       _highlight = highlight,
       _rtl = rtl,
       _screen = screen,
       _sweep = sweep,
       _visibility = visibility;

  double? _width;
  set width(double? v) {
    if (v == _width) return;
    _width = v;
    markNeedsLayout();
  }

  double? _height;
  set height(double? v) {
    if (v == _height) return;
    _height = v;
    markNeedsLayout();
  }

  double _radius;
  set radius(double v) {
    if (v == _radius) return;
    _radius = v;
    markNeedsPaint();
  }

  BoxShape _shape;
  set shape(BoxShape v) {
    if (v == _shape) return;
    _shape = v;
    markNeedsPaint();
  }

  Color _base;
  set base(Color v) {
    if (v == _base) return;
    _base = v;
    markNeedsPaint();
  }

  Color _highlight;
  set highlight(Color v) {
    if (v == _highlight) return;
    _highlight = v;
    markNeedsPaint();
  }

  bool _rtl;
  set rtl(bool v) {
    if (v == _rtl) return;
    _rtl = v;
    markNeedsPaint();
  }

  Size _screen;
  set screen(Size v) {
    if (v == _screen) return;
    _screen = v;
    markNeedsPaint();
  }

  Animation<double>? _sweep;
  Animation<double>? _visibility;

  void setAnimations(Animation<double>? sweep, Animation<double>? visibility) {
    if (identical(sweep, _sweep) && identical(visibility, _visibility)) return;
    if (attached) {
      _sweep?.removeListener(markNeedsPaint);
      _visibility?.removeListener(markNeedsPaint);
    }
    _sweep = sweep;
    _visibility = visibility;
    if (attached) {
      _sweep?.addListener(markNeedsPaint);
      _visibility?.addListener(markNeedsPaint);
    }
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _sweep?.addListener(markNeedsPaint);
    _visibility?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _sweep?.removeListener(markNeedsPaint);
    _visibility?.removeListener(markNeedsPaint);
    super.detach();
  }

  // Each block repaints every frame while it sweeps; its own layer keeps that
  // from repainting the card around it.
  @override
  bool get isRepaintBoundary => true;

  @override
  void performLayout() {
    size = constraints.constrain(
      Size(_width ?? constraints.maxWidth, _height ?? constraints.maxHeight),
    );
  }

  @override
  bool hitTestSelf(Offset position) => false;

  /// Where the band is, 0 → 1, from the frame clock: the same value for
  /// every block painted in this frame, whichever scope it belongs to.
  double get _phase {
    final period = AppDurations.shimmer.inMicroseconds;
    final stamp = SchedulerBinding.instance.currentFrameTimeStamp;
    return (stamp.inMicroseconds % period) / period;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    final alpha = _visibility?.value ?? 1;
    if (alpha <= 0) return;

    final rect = offset & size;
    final paint = Paint();
    final sweeping = _sweep?.isAnimating ?? false;

    if (sweeping) {
      // The band crosses a strip three screens wide, so between passes it is
      // off screen for a moment — a breath, not a strobe. It runs with the
      // reading direction: right-to-left in Arabic.
      final global = localToGlobal(Offset.zero);
      final w = _screen.width <= 0 ? 400.0 : _screen.width;
      final travel = _rtl ? 1 - _phase : _phase;
      final bandCenter = -w + travel * 3 * w;
      final gradientRect = Rect.fromLTWH(
        offset.dx - global.dx + bandCenter - w * 0.35,
        offset.dy - global.dy,
        w * 0.7,
        math.max(1, _screen.height),
      );
      paint.shader = LinearGradient(
        begin: const Alignment(-1, -0.3),
        end: const Alignment(1, 0.3),
        colors: <Color>[
          _fade(_base, alpha),
          _fade(_highlight, alpha),
          _fade(_base, alpha),
        ],
        stops: const <double>[0.2, 0.5, 0.8],
      ).createShader(gradientRect);
    } else {
      paint.color = _fade(_base, alpha);
    }

    final canvas = context.canvas;
    if (_shape == BoxShape.circle) {
      canvas.drawOval(rect, paint);
    } else {
      final r = math.min(_radius, math.min(size.width, size.height) / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r)),
        paint,
      );
    }
  }

  static Color _fade(Color c, double a) => c.withValues(alpha: c.a * a);
}
