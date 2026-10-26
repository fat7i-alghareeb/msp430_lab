import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../utils/constants/design_constants.dart';

import '../app_icon_source.dart';
import '../../../utils/extensions/num_spacing_extensions.dart';

/// Describes the content shown inside an [AppButton].
///
/// This keeps the button chrome (background, shadow, press animation) separate
/// from the child composition (label/icon/padding).
abstract class AppButtonChild {
  const AppButtonChild();

  Widget build(BuildContext context, {required Color foreground});

  EdgeInsetsGeometry defaultPadding(BuildContext context);

  /// Text-only content.
  factory AppButtonChild.label(
    String label, {
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return _LabelButtonChild(
      label,
      textAlign: textAlign,
      maxLines: maxLines,
      textStyle: textStyle,
      padding: padding,
    );
  }

  /// Icon-only content.
  factory AppButtonChild.icon(
    IconSource icon, {
    double size = 20,
    EdgeInsetsGeometry? padding,
  }) {
    return _IconOnlyButtonChild(icon, padding: padding);
  }

  /// Combined label + icon content.
  factory AppButtonChild.labelIcon({
    required String label,
    required IconSource icon,
    AppButtonIconPosition position = AppButtonIconPosition.leading,
    double iconSize = 18,
    double spacing = AppSpacing.sm,
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return _LabelIconButtonChild(
      label: label,
      icon: icon,
      position: position,
      spacing: spacing,
      textAlign: textAlign,
      maxLines: maxLines,
      textStyle: textStyle,
      padding: padding,
    );
  }
}

enum AppButtonIconPosition { leading, trailing }

class _LabelButtonChild extends AppButtonChild {
  const _LabelButtonChild(
    this.label, {
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.textStyle,
    this.padding,
  });

  final String label;
  final TextAlign textAlign;
  final int? maxLines;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, {required Color foreground}) {
    final base = textStyle ?? AppTextStyles.s12w400;

    return Text(
      label,
      maxLines: maxLines ?? 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: base.copyWith(color: foreground),
    );
  }

  @override
  EdgeInsetsGeometry defaultPadding(BuildContext context) {
    return padding ??
        const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12);
  }
}

class _IconOnlyButtonChild extends AppButtonChild {
  const _IconOnlyButtonChild(this.icon, {this.padding});

  final IconSource icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, {required Color foreground}) {
    return icon.build(context, color: foreground);
  }

  @override
  EdgeInsetsGeometry defaultPadding(BuildContext context) {
    return padding ?? const EdgeInsets.all(12);
  }
}

class _LabelIconButtonChild extends AppButtonChild {
  const _LabelIconButtonChild({
    required this.label,
    required this.icon,
    this.position = AppButtonIconPosition.leading,
    this.spacing = AppSpacing.sm,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.textStyle,
    this.padding,
  });

  final String label;
  final IconSource icon;
  final AppButtonIconPosition position;
  final double spacing;
  final TextAlign textAlign;
  final int? maxLines;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, {required Color foreground}) {
    final iconWidget = icon.build(context, color: foreground);
    final base = (textStyle ?? AppTextStyles.s12w400).copyWith(
      color: foreground,
    );

    final textWidget = Text(
      label,
      maxLines: maxLines ?? 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: base,
    );

    final children = <Widget>[
      if (position == AppButtonIconPosition.leading) ...[
        iconWidget,
        spacing.horizontalSpace,
        Flexible(child: textWidget),
      ] else ...[
        Flexible(child: textWidget),
        spacing.horizontalSpace,
        iconWidget,
      ],
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  @override
  EdgeInsetsGeometry defaultPadding(BuildContext context) {
    return padding ??
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12);
  }
}
