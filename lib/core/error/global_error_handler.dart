import 'dart:async';

import '../../utils/helpers/colored_print.dart';
import '../utils/result.dart';
import 'app_exception.dart';

/// Runs [action] and wraps the result into a [Result].
///
/// Usage in repositories:
/// ```dart
/// Future<Result<User>> login(...) {
///   return runAsResult(() => _remote.login(...));
/// }
/// ```
Future<Result<T>> runAsResult<T>(FutureOr<T> Function() action) async {
  try {
    final value = await action();
    return Result.success(value);
  } on AppException catch (e) {
    return Result.failure(e.message);
  } catch (e, s) {
    printR('runAsResult unexpected error: $e');
    return Result.failure(
      AppException.unknown(cause: e, stackTrace: s).message,
    );
  }
}

/// Runs [action] and rethrows errors as [AppException].
///
/// Intended for data sources which want to bubble errors up to
/// repositories, where they will be converted into [Result] via
/// [runAsResult].
Future<T> rethrowAsAppException<T>(FutureOr<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } catch (e, s) {
    throw AppException.unknown(cause: e, stackTrace: s);
  }
}

/// Runs [action] and returns an [AppException] instead of throwing.
///
/// Usage example:
/// ```dart
/// final error = await runAndReturnError(() => _remoteCall());
/// if (error != null) {
///   // show error.message in UI
/// }
/// ```
Future<AppException?> runAndReturnError<T>(
  FutureOr<T> Function() action,
) async {
  try {
    await action();
    return null;
  } on AppException catch (e) {
    return e;
  } catch (e, s) {
    printR('runAndReturnError unexpected error: $e');
    return AppException.unknown(cause: e, stackTrace: s);
  }
}
