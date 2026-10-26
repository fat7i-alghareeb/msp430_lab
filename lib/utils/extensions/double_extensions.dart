import 'package:flutter/material.dart';

import 'num_spacing_extensions.dart';

extension SliverSpacing on double {
  SliverToBoxAdapter get sliverHorizentalSpace =>
      SliverToBoxAdapter(child: horizontalSpace);

  SliverToBoxAdapter get sliverVerticalSpace =>
      SliverToBoxAdapter(child: verticalSpace);
}

extension SmartNum on double {
  /// Removes .0 if the number is whole, otherwise keeps the decimals.
  String get toSimpleString {
    if (this % 1 == 0) {
      return toInt().toString().padLeft(2, "0");
    }
    return toString();
  }
}
