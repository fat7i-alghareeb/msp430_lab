import 'package:flutter/widgets.dart';

import '../constants/design_constants.dart';

/// Layout helpers for widgets referenced by a [GlobalKey].
///
/// Example:
/// ```dart
/// final key = GlobalKey();
/// Container(key: key);
/// final size = key.size;
/// final position = key.globalPosition;
/// ```
extension GlobalKeyLayoutExtensions on GlobalKey {
  /// Example:
  /// ```dart
  /// final box = myKey.renderBox;
  /// ```
  RenderBox? get renderBox {
    final context = currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject;
    }
    return null;
  }

  /// Example:
  /// ```dart
  /// final widgetSize = myKey.size;
  /// ```
  Size? get size => renderBox?.size;

  /// Example:
  /// ```dart
  /// final w = myKey.width;
  /// ```
  double? get width => size?.width;

  /// Example:
  /// ```dart
  /// final h = myKey.height;
  /// ```
  double? get height => size?.height;

  /// Example:
  /// ```dart
  /// final offset = myKey.globalPosition;
  /// ```
  Offset? get globalPosition => renderBox?.localToGlobal(Offset.zero);
}

extension WidgetX on Widget {
  /// Example:
  /// ```dart
  /// Text('Hello').standardHorizontalPadding;
  /// ```
  Widget get standardHorizontalPadding =>
      Padding(padding: AppSpacing.horizontal, child: this);

  /// Example:
  /// ```dart
  /// Text('Hello').standardVerticalPadding;
  /// ```
  Widget get standardVerticalPadding =>
      Padding(padding: AppSpacing.vertical, child: this);

  /// Example:
  /// ```dart
  /// Text('Hello').standardPadding;
  /// ```
  Widget get standardPadding =>
      Padding(padding: AppSpacing.standardPadding, child: this);

  /// Example:
  /// ```dart
  /// Text('Hello').paddingAll(16);
  /// ```
  Widget paddingAll(double v) =>
      Padding(padding: EdgeInsets.all(v), child: this);

  /// Example:
  /// ```dart
  /// Text('Hello').symmetricPadding(h: 16, v: 8);
  /// ```
  Widget symmetricPadding({double? v, double? h}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: h ?? 0, vertical: v ?? 0),
    child: this,
  );

  /// Example:
  /// ```dart
  /// Text('Hello').center();
  /// ```
  Widget center() => Center(child: this);
}

extension WidgetGestureX on Widget {
  /// Example:
  /// ```dart
  /// Icon(Icons.add).onTap(() => print('Tapped'));
  /// ```
  Widget onTap(VoidCallback onTap) =>
      GestureDetector(onTap: onTap, child: this);
}

extension WidgetBoxX on Widget {
  /// Example:
  /// ```dart
  /// Text('Hello').sized(w: 120, h: 48);
  /// ```
  Widget sized({double? w, double? h}) =>
      SizedBox(width: w, height: h, child: this);
}

extension ToSliverToBoxAdapter on Widget {
  SliverToBoxAdapter get toSliverToBoxAdapter =>
      SliverToBoxAdapter(child: this);
}
