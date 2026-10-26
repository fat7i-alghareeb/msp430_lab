/// Lightweight application-level exception used across the network layer
/// and repositories.
class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  /// Human-readable, already-localized message safe to show to the user.
  final String message;

  /// Optional underlying error for logging / debugging.
  final Object? cause;

  /// Optional stack trace of the original failure.
  final StackTrace? stackTrace;

  /// Unknown / unexpected error with a generic message.
  factory AppException.unknown({Object? cause, StackTrace? stackTrace}) {
    return AppException('Unknown error', cause: cause, stackTrace: stackTrace);
  }

  /// Convenience factory for mapping known cases.
  factory AppException.known(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppException(message, cause: cause, stackTrace: stackTrace);
  }

  @override
  String toString() => 'AppException(message: $message, cause: $cause)';
}
