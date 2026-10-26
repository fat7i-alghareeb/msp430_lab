import 'package:flutter/material.dart';

import '../helpers/app_strings.dart';
import 'num_spacing_extensions.dart';

/// Localization helpers for [int] values that represent calendar parts.
extension AppIntMonthNameExtensions on int {
  /// Returns the localized short month name for the month index (1..12).
  String get monthNameShort {
    return switch (this) {
      DateTime.january => AppStrings.jan,
      DateTime.february => AppStrings.feb,
      DateTime.march => AppStrings.mar,
      DateTime.april => AppStrings.apr,
      DateTime.may => AppStrings.may,
      DateTime.june => AppStrings.jun,
      DateTime.july => AppStrings.jul,
      DateTime.august => AppStrings.aug,
      DateTime.september => AppStrings.sep,
      DateTime.october => AppStrings.oct,
      DateTime.november => AppStrings.nov,
      DateTime.december => AppStrings.dec,
      _ => '',
    };
  }

  /// Returns the localized full month name for the month index (1..12).
  String get monthNameFull {
    return switch (this) {
      DateTime.january => AppStrings.january,
      DateTime.february => AppStrings.february,
      DateTime.march => AppStrings.march,
      DateTime.april => AppStrings.april,
      DateTime.may => AppStrings.may,
      DateTime.june => AppStrings.june,
      DateTime.july => AppStrings.july,
      DateTime.august => AppStrings.august,
      DateTime.september => AppStrings.september,
      DateTime.october => AppStrings.october,
      DateTime.november => AppStrings.november,
      DateTime.december => AppStrings.december,
      _ => '',
    };
  }
}

extension AppIntWeekdayNameExtensions on int {
  /// Returns the localized short weekday name.
  ///
  /// Uses [DateTime.weekday] (1..7 where 1 is Monday).
  String get weekdayNameShort {
    return switch (this) {
      DateTime.monday => AppStrings.mon,
      DateTime.tuesday => AppStrings.tue,
      DateTime.wednesday => AppStrings.wed,
      DateTime.thursday => AppStrings.thu,
      DateTime.friday => AppStrings.fri,
      DateTime.saturday => AppStrings.sat,
      DateTime.sunday => AppStrings.sun,
      _ => '',
    };
  }

  /// Returns the localized full weekday name.
  ///
  /// Uses [DateTime.weekday] (1..7 where 1 is Monday).
  String get weekdayNameFull {
    return switch (this) {
      DateTime.monday => AppStrings.monday,
      DateTime.tuesday => AppStrings.tuesday,
      DateTime.wednesday => AppStrings.wednesday,
      DateTime.thursday => AppStrings.thursday,
      DateTime.friday => AppStrings.friday,
      DateTime.saturday => AppStrings.saturday,
      DateTime.sunday => AppStrings.sunday,
      _ => '',
    };
  }
}

extension SliverSpacing on int {
  SliverToBoxAdapter get sliverHorizentalSpace =>
      SliverToBoxAdapter(child: horizontalSpace);

  SliverToBoxAdapter get sliverVerticalSpace =>
      SliverToBoxAdapter(child: verticalSpace);
}
