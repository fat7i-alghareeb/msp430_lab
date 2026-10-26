/// Short id helper for enums.
///
/// Example:
/// ```dart
/// enum Status { loading, success }
/// Status.loading.id; // 'loading'
/// ```
extension EnumIdExtension on Enum {
  String get id => toString().split('.').last;
}
