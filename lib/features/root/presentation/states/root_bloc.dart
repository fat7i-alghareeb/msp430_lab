import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/bloc_status.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/root_entity.dart';
import '../../domain/facade/root_facade.dart';

part 'root_event.dart';
part 'root_state.dart';
part 'root_bloc.freezed.dart';

@injectable
class RootBloc extends Bloc<RootEvent, RootState> {
  RootBloc(this._facade) : super(const RootState()) {
    on<_Started>(_onStarted);
    on<_GetAllRequested>(_onGetAllRequested);
  }

  final RootFacade _facade;

  Future<void> _onStarted(_Started event, Emitter<RootState> emit) {
    return _onGetAllRequested(const _GetAllRequested(), emit);
  }

  Future<void> _onGetAllRequested(
    _GetAllRequested event,
    Emitter<RootState> emit,
  ) async {
    emit(state.copyWith(getAllState: const BlocStatus.loading()));

    final result = await _facade.getAllRoots();
    result.when(
      success: (data) =>
          emit(state.copyWith(getAllState: BlocStatus.success(data))),
      failure: (message) =>
          emit(state.copyWith(getAllState: BlocStatus.failure(message))),
    );
  }
}
