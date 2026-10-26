part of 'root_bloc.dart';

@freezed
abstract class RootState with _$RootState {
  const factory RootState({
    @Default(BlocStatus<List<RootEntity>>.initial())
    BlocStatus<List<RootEntity>> getAllState,
  }) = _RootState;
}
