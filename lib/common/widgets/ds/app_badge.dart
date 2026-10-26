import 'package:flutter/material.dart';

import 'app_skeleton.dart';

import '../../../core/theme/app_colors.dart';
import '../../../utils/constants/design_constants.dart';

/// The tone a badge carries — `DESIGN_SYSTEM.md`.
///
/// Tones map to a background/foreground pair, never to a color alone: the
/// system forbids signalling by color, so every badge also carries text.
enum AppBadgeTone {
  /// Solid `primary` — «Official», «New».
  primary,

  /// `urgent` from [AppSemanticColors] — «Urgent», «-20%».
  urgent,

  /// `tertiary` — a quiet category label.
  subtle,

  /// Quiet, with a hairline border — «Used», a source name.
  neutral,

  /// A positive state, still quiet — «Available».
  positive,

  /// Transparent with a DASHED border — «Sponsored».
  dashed,
}

/// A small text label — `DESIGN_SYSTEM.md`.
///
/// `labelSmall` (11/700), padding `2×7`, radius [AppRadii.xs].
///
/// **Every badge carries text.** There is no color-only badge in this system;
/// an icon may be added beside the text but never instead of it.
class AppBadge extends StatelessWidget {
  const AppBadge(
    this.label, {
    super.key,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  }) : skeletonWidth = null;

  const AppBadge.primary(this.label, {super.key, this.icon})
    : tone = AppBadgeTone.primary,
      skeletonWidth = null;

  const AppBadge.urgent(this.label, {super.key, this.icon})
    : tone = AppBadgeTone.urgent,
      skeletonWidth = null;

  const AppBadge.subtle(this.label, {super.key, this.icon})
    : tone = AppBadgeTone.subtle,
      skeletonWidth = null;

  const AppBadge.positive(this.label, {super.key, this.icon})
    : tone = AppBadgeTone.positive,
      skeletonWidth = null;

  const AppBadge.dashed(this.label, {super.key, this.icon})
    : tone = AppBadgeTone.dashed,
      skeletonWidth = null;

  /// The badge as a loading bar — the SAME box, with the word taken out.
  ///
  /// A card that swapped its badge for a hand-sized `SkeletonBar` would be a
  /// few dp shorter while loading and would jump when the data arrived. Here
  /// the padding, the border and the text metrics are the badge's own, so the
  /// box cannot drift from the real one.
  const AppBadge.skeleton({super.key, this.skeletonWidth = 52})
    : label = '',
      tone = AppBadgeTone.neutral,
      icon = null;

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  /// How wide the bar is while loading. Null in every real badge.
  final double? skeletonWidth;

  /// Horizontal room the box adds around its text: `7 + 7` of padding and a
  /// hairline border on each side. For callers that measure whether a label
  /// fits before choosing it.
  static const double horizontalExtent = 7 * 2 + AppBorders.hairline * 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    late final Color background;
    late final Color foreground;
    BoxBorder? border;

    switch (tone) {
      case AppBadgeTone.primary:
        background = colors.primary;
        foreground = colors.onPrimary;
      case AppBadgeTone.urgent:
        background = semantic.urgent;
        foreground = semantic.onUrgent;
      case AppBadgeTone.subtle:
        background = colors.tertiary;
        foreground = colors.onTertiary;
      case AppBadgeTone.positive:
        background = colors.secondaryContainer;
        foreground = colors.onSecondaryContainer;
      case AppBadgeTone.neutral:
        background = colors.surfaceContainerHighest;
        foreground = colors.onSurfaceVariant;
        border = Border.all(color: colors.outline);
      case AppBadgeTone.dashed:
        background = Colors.transparent;
        foreground = colors.onSurfaceVariant;
        border = _DashedBorder(color: colors.outlineVariant);
    }

    // A zero-width space carries the full line height with no glyph, so the
    // loading box measures exactly as the real one does — at any text scale.
    final text = Text(
      skeletonWidth == null ? label : '\u200B',
      style: theme.textTheme.labelSmall?.copyWith(color: foreground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final content = skeletonWidth == null
        ? text
        : SizedBox(width: skeletonWidth, child: text);

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: border,
      ),
      child: icon == null
          ? content
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 11, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Flexible(child: text),
              ],
            ),
    );

    // The skeleton badge is one block the size of a real badge, so the card
    // measures the same loading and loaded.
    if (skeletonWidth == null) return badge;
    return SkeletonShape(child: badge);
  }
}

/// Dashed outline for [AppBadgeTone.dashed].
///
/// Material has no dashed [BoxBorder], so the dashes are stroked by hand.
class _DashedBorder extends BoxBorder {
  const _DashedBorder({required this.color, this.dash = 3, this.gap = 2.5});

  final Color color;
  final double dash;
  final double gap;

  @override
  BorderSide get bottom => BorderSide(color: color);

  @override
  BorderSide get top => BorderSide(color: color);

  @override
  bool get isUniform => true;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.xs);
    final path = Path()..addRRect(radius.toRRect(rect.deflate(0.5)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppBorders.hairline;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  ShapeBorder scale(double t) =>
      _DashedBorder(color: color, dash: dash * t, gap: gap * t);
}
