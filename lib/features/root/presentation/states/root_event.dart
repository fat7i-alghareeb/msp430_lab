part of 'root_bloc.dart';

@freezed
class RootEvent with _$RootEvent {
  const factory RootEvent.started() = _Started;
  const factory RootEvent.getAllRequested() = _GetAllRequested;
}
