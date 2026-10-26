import 'package:flutter/material.dart';

/// Utilities for nullable [String] values.
///
/// Example:
/// ```dart
/// String? name;
/// name.orEmpty;        // ''
/// name.isNullOrEmpty;  // true
/// '  '.isNullOrBlank;  // true
/// ```
extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  String get orEmpty => this ?? '';
}

/// Common text transformations for non-null [String] values.
///
/// Example:
/// ```dart
/// 'hello world'.capitalizeFirst(); // 'Hello world'
/// 'hello world'.capitalizeWords(); // 'Hello World'
/// 'very long text'.ellipsis(7);    // 'very...'
/// ```
extension StringExtensions on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String capitalizeWords() {
    if (isEmpty) return this;
    final parts = split(RegExp(r'\s+'));
    return parts
        .where((p) => p.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  String ellipsis(int maxLength, {String overflow = '...'}) {
    if (length <= maxLength) return this;
    if (maxLength <= overflow.length) return substring(0, maxLength);
    return substring(0, maxLength - overflow.length) + overflow;
  }
}

/// Parsing hexadecimal color strings into [Color] instances.
///
/// Example:
/// ```dart
/// '#1565C0'.toColor();      // opaque color
/// '1565C0'.toColor();       // also works without '#'
/// '#801565C0'.toColor();    // with alpha channel
/// ```
extension HexColorString on String {
  Color toColor({Color? fallback}) {
    var hex = replaceAll('#', '').toUpperCase();
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      if (fallback != null) return fallback;
      throw FormatException('Invalid hex color: $this');
    }
    final value = int.parse(hex, radix: 16);
    return Color(value);
  }
}
