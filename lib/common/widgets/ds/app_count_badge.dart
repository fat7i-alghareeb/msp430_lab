import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import '../../../utils/helpers/app_formats.dart';

/// A count in a coloured dot: an unread number on a tab, a cart's items.
///
/// **One digit is a circle**, two or more a pill with the same height. The
/// dot grows with the reader's text size — a number never outgrows its dot —
/// and it is as tall as it needs to be and no taller: it measures itself, so
/// a row or a `Positioned` around it cannot stretch it.
///
/// More than [maxCount] reads «99+». Zero or less draws nothing; hide the
/// widget instead if the space should collapse too.
///
/// Pair it with a [Semantics] label that says what is being counted — «3
/// unread» — because the number alone says nothing to a screen reader.
class AppCountBadge extends StatelessWidget {
  const AppCountBadge({
    super.key,
    required this.count,
    required this.color,
    required this.onColor,
    this.size = 20,
    this.maxCount = 99,
  });

  final int count;

  /// The dot's colour and the number's.
  final Color color;
  final Color onColor;

  /// The dot's diameter at the default text size.
  final double size;

  final int maxCount;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final number = AppFormats.number(context, math.min(count, maxCount));
    final label = count > maxCount ? '$number+' : number;
    final single = label.length == 1;

    // The diameter follows the text size, so the digit always fits its circle.
    final side = MediaQuery.textScalerOf(context).scale(size);

    return Container(
      constraints: BoxConstraints(minWidth: side, minHeight: side),
      padding: EdgeInsets.symmetric(horizontal: single ? 0 : size * 0.3),
      // No `alignment` here. A Container that centres its child grows to the
      // full size its parent allows — a 48dp row made it a 48dp stripe. A
      // Center that shrinks to its child keeps the dot as small as it can be
      // and still centres the number.
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: onColor,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
