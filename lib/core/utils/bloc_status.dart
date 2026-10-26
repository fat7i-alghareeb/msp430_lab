import 'package:freezed_annotation/freezed_annotation.dart';

part 'bloc_status.freezed.dart';

@freezed
sealed class BlocStatus<T> with _$BlocStatus<T> {
  const factory BlocStatus.initial() = _Initial<T>;
  const factory BlocStatus.loading() = _Loading<T>;
  const factory BlocStatus.success(T data) = _Success<T>;
  const factory BlocStatus.failure(String message) = _Failure<T>;
}

extension ResultExtension<T> on BlocStatus<T> {
  bool get isLoading => maybeWhen(orElse: () => false, loading: () => true);

  bool get isSuccess => maybeWhen(orElse: () => false, success: (data) => true);

  bool get isInit => maybeWhen(orElse: () => false, initial: () => true);

  bool get isFailed => maybeWhen(orElse: () => false, failure: (error) => true);

  String? get errorMessage =>
      maybeWhen(orElse: () => null, failure: (message) => message);

  T? get getDataWhenSuccess =>
      maybeWhen(orElse: () => null, success: (data) => data);
}
