import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/bloc_status.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/facade/topics_facade.dart';

part 'topics_event.dart';
part 'topics_state.dart';
part 'topics_bloc.freezed.dart';

/// The twelve topics, loaded once and shared by the home, the topic list and
/// every topic page (provided above `MaterialApp`).
@injectable
class TopicsBloc extends Bloc<TopicsEvent, TopicsState> {
  TopicsBloc(this._facade) : super(const TopicsState()) {
    on<_Started>(_onStarted);
  }

  final TopicsFacade _facade;

  Future<void> _onStarted(_Started event, Emitter<TopicsState> emit) async {
    emit(state.copyWith(topicsState: const BlocStatus.loading()));
    final result = await _facade.getAllTopics();
    result.when(
      success: (data) =>
          emit(state.copyWith(topicsState: BlocStatus.success(data))),
      failure: (message) =>
          emit(state.copyWith(topicsState: BlocStatus.failure(message))),
    );
  }
}
