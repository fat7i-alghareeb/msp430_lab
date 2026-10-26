import 'package:flutter/material.dart';

/// Determines [TextDirection] from the first non-whitespace character
/// of a [String], with basic RTL script detection.
///
/// Example:
/// ```dart
/// 'Hello'.textDirection;  // TextDirection.ltr
/// 'مرحبا'.textDirection;  // TextDirection.rtl
/// ```
extension StringTextDirectionExtensions on String? {
  TextDirection get textDirection {
    final value = this;
    if (value == null || value.isEmpty) {
      return TextDirection.ltr;
    }
    final trimmed = value.trimLeft();
    if (trimmed.isEmpty) {
      return TextDirection.ltr;
    }
    final firstChar = trimmed[0];
    final rtlRegex = RegExp(r'[\u0600-\u06FF]');
    return rtlRegex.hasMatch(firstChar) ? TextDirection.rtl : TextDirection.ltr;
  }
}
