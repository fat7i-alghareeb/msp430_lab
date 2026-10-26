import 'package:flutter/material.dart';

import '../../utils/helpers/build_svg_icon.dart';

/// Builder signature used by [IconSource.builder].
///
/// The builder should return a widget that represents the icon.
typedef IconSourceBuilder = Widget Function(BuildContext context);

/// A lightweight abstraction for building icons from different sources.
///
/// This keeps higher-level UI (for example button content or list tiles)
/// flexible: the caller can provide a Material icon, asset image, SVG,
/// or a completely custom widget without changing the consumer API.
///
/// Usage examples:
///
/// ```dart
/// // Material icon
/// final iconSource = IconSource.icon(Icons.add, size: 20);
///
/// // SVG from assets
/// final svgSource = IconSource.svg('assets/icons/search.svg', color: Colors.grey);
///
/// // Build the actual widgets
/// Widget build(BuildContext context) {
///   return Column(
///     children: [
///       iconSource.build(context),
///       svgSource.build(context),
///     ],
///   );
/// }
/// ```
abstract class IconSource {
  const IconSource({this.size, this.color});

  /// Default icon size in logical pixels.
  final double? size;

  /// Default icon color.
  final Color? color;

  /// Builds the icon widget.
  ///
  /// You can override the configured [size] and [color] at call time.
  ///
  /// This is useful when the same [IconSource] instance is reused in multiple
  /// places with slight variations.
  ///
  /// ```dart
  /// final icon = IconSource.icon(Icons.close);
  ///
  /// // Default
  /// icon.build(context);
  ///
  /// // Override size/color
  /// icon.build(context, size: 18, color: Colors.red);
  /// ```
  Widget build(BuildContext context, {double? size, Color? color}) {
    final overrideSize = size ?? this.size;
    final overrideColor = color ?? this.color;

    if (overrideSize == this.size && overrideColor == this.color) {
      return buildWidget(context);
    }

    return copyWith(
      size: overrideSize,
      color: overrideColor,
    ).buildWidget(context);
  }

  /// Builds the icon widget using the instance's current configuration.
  ///
  /// Consumers should typically call [build] instead, so they can override
  /// `size`/`color` when needed.
  Widget buildWidget(BuildContext context);

  /// Returns a new [IconSource] with the provided overrides applied.
  ///
  /// Implementations should preserve all other configuration.
  IconSource copyWith({double? size, Color? color});

  /// Creates an [IconSource] from a Material [IconData].
  ///
  /// ```dart
  /// final icon = IconSource.icon(Icons.home, size: 18, color: Colors.blue);
  ///
  /// // Build the widget:
  /// final built = icon.build(context);
  ///
  /// // Or inline:
  /// IconButton(
  ///   icon: IconSource.icon(Icons.home, size: 18, color: Colors.blue)
  ///       .build(context),
  ///   onPressed: () {},
  /// );
  /// ```
  factory IconSource.icon(IconData icon, {double? size, Color? color}) {
    return _IconButtonIconSource(icon, size: size, color: color);
  }

  /// Creates an [IconSource] from an image asset (png/jpg/etc).
  ///
  /// If [applyColor] is true, the image is tinted using [color].
  ///
  /// ```dart
  /// final logo = IconSource.asset('assets/icons/logo.png', size: 24);
  /// final builtLogo = logo.build(context);
  ///
  /// final tinted = IconSource.asset(
  ///   'assets/icons/close.png',
  ///   applyColor: true,
  ///   color: Colors.black,
  /// );
  /// final builtTinted = tinted.build(context);
  /// ```
  factory IconSource.asset(
    String assetPath, {
    double? size,
    bool applyColor = false,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return _AssetIconSource(
      assetPath,
      size: size,
      applyColor: applyColor,
      fit: fit,
      color: color,
    );
  }

  /// Creates an [IconSource] from an SVG asset.
  ///
  /// ```dart
  /// final svg = IconSource.svg(
  ///   'assets/icons/search.svg',
  ///   size: 20,
  ///   color: Colors.grey,
  /// );
  /// final builtSvg = svg.build(context);
  /// ```
  factory IconSource.svg(
    String assetName, {
    double? size,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return _SvgIconSource(assetName, size: size, fit: fit, color: color);
  }

  /// Creates an [IconSource] from a custom widget.
  ///
  /// Use this when you already have a widget instance and it does not need
  /// access to a [BuildContext] at creation time.
  ///
  /// The child will be fit into a square box of [size] (if provided).
  ///
  /// Difference vs [IconSource.builder]:
  /// - Use [IconSource.widget] for a static widget you already have.
  /// - Use [IconSource.builder] when the icon must be created using
  ///   [BuildContext] (theme, localization, inherited widgets) or needs to
  ///   react to the current `IconTheme`.
  ///
  /// ```dart
  /// final icon = IconSource.widget(
  ///   const CircularProgressIndicator(strokeWidth: 2),
  ///   size: 16,
  /// );
  ///
  /// // Later in build:
  /// final builtIcon = icon.build(context);
  /// IconButton(icon: builtIcon, onPressed: () {});
  /// ```
  factory IconSource.widget(Widget child, {double? size, Color? color}) {
    return _WidgetIconSource(child, size: size, color: color);
  }

  /// Creates an [IconSource] from a builder.
  ///
  /// Use this when the icon needs to be created using a [BuildContext]
  /// (theme, localization, inherited widgets) or when you want the widget to
  /// react to the current `IconTheme` (size/color).
  ///
  /// Difference vs [IconSource.widget]:
  /// - Use [IconSource.builder] for context-dependent icons.
  /// - Use [IconSource.widget] when you already have a ready widget.
  ///
  /// ```dart
  /// final icon = IconSource.builder(
  ///   (context) => const Icon(Icons.search),
  ///   color: Colors.grey,
  ///   size: 18,
  /// );
  ///
  /// // Later in build:
  /// final builtIcon = icon.build(context);
  /// IconButton(icon: builtIcon, onPressed: () {});
  /// ```
  factory IconSource.builder(
    IconSourceBuilder builder, {
    double? size,
    Color? color,
  }) {
    return _BuilderIconSource(builder, size: size, color: color);
  }
}

class _IconButtonIconSource extends IconSource {
  const _IconButtonIconSource(this.icon, {super.size, super.color});

  final IconData icon;

  @override
  Widget buildWidget(BuildContext context) {
    return Icon(icon, size: size, color: color);
  }

  @override
  IconSource copyWith({double? size, Color? color}) {
    return _IconButtonIconSource(
      icon,
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }
}

class _AssetIconSource extends IconSource {
  const _AssetIconSource(
    this.assetPath, {
    super.size,
    this.applyColor = false,
    this.fit = BoxFit.contain,
    super.color,
  });

  final String assetPath;
  final bool applyColor;
  final BoxFit fit;

  @override
  Widget buildWidget(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      color: applyColor ? color : null,
    );
  }

  @override
  IconSource copyWith({double? size, Color? color}) {
    return _AssetIconSource(
      assetPath,
      size: size ?? this.size,
      applyColor: applyColor,
      fit: fit,
      color: color ?? this.color,
    );
  }
}

class _SvgIconSource extends IconSource {
  const _SvgIconSource(
    this.assetName, {
    super.size,
    this.fit = BoxFit.contain,
    super.color,
  });

  final String assetName;
  final BoxFit fit;

  @override
  Widget buildWidget(BuildContext context) {
    return buildSvgIcon(
      assetName: assetName,
      color: color,
      width: size,
      height: size,
      fit: fit,
    );
  }

  @override
  IconSource copyWith({double? size, Color? color}) {
    return _SvgIconSource(
      assetName,
      size: size ?? this.size,
      fit: fit,
      color: color ?? this.color,
    );
  }
}

class _WidgetIconSource extends IconSource {
  const _WidgetIconSource(this.child, {super.size, super.color});

  final Widget child;

  @override
  Widget buildWidget(BuildContext context) {
    final s = size;
    Widget result = SizedBox(
      width: s,
      height: s,
      child: FittedBox(child: child),
    );

    if (color != null || size != null) {
      result = IconTheme(
        data: IconThemeData(color: color, size: size),
        child: result,
      );
    }

    return result;
  }

  @override
  IconSource copyWith({double? size, Color? color}) {
    return _WidgetIconSource(
      child,
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }
}

class _BuilderIconSource extends IconSource {
  const _BuilderIconSource(this.builder, {super.size, super.color});

  final IconSourceBuilder builder;

  @override
  Widget buildWidget(BuildContext context) {
    Widget result = builder(context);

    if (color != null || size != null) {
      result = IconTheme(
        data: IconThemeData(color: color, size: size),
        child: result,
      );
    }

    return result;
  }

  @override
  IconSource copyWith({double? size, Color? color}) {
    return _BuilderIconSource(
      builder,
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }
}
