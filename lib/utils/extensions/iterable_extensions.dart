/// Convenience utilities for working with non-null iterables.
///
/// Example:
/// ```dart
/// final items = <int>[1, 2, 3];
/// items.firstOrNull;                   // 1
/// items.whereNot((x) => x.isEven);     // [1, 3]
/// items.toMap((x) => MapEntry(x, x));  // {1: 1, 2: 2, 3: 3}
/// ```
extension IterableExtensions<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;

  Iterable<T> whereNot(bool Function(T element) test) {
    return where((element) => !test(element));
  }

  Map<K, V> toMap<K, V>(MapEntry<K, V> Function(T element) transform) {
    final result = <K, V>{};
    for (final element in this) {
      final entry = transform(element);
      result[entry.key] = entry.value;
    }
    return result;
  }
}

/// Null-aware helpers for [Iterable] values.
///
/// Example:
/// ```dart
/// List<int>? items;
/// items.isNullOrEmpty;     // true
/// items.orEmpty().length;  // 0
/// ```
extension NullableIterableExtensions<T> on Iterable<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  bool get isNotNullOrEmpty => !isNullOrEmpty;

  Iterable<T> orEmpty() => this ?? <T>[];
}
