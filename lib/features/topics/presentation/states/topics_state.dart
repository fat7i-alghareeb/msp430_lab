part of 'topics_bloc.dart';

@freezed
abstract class TopicsState with _$TopicsState {
  const factory TopicsState({
    @Default(BlocStatus<List<TopicEntity>>.initial())
    BlocStatus<List<TopicEntity>> topicsState,
  }) = _TopicsState;
}

extension TopicsStateX on TopicsState {
  List<TopicEntity> get topics =>
      topicsState.getDataWhenSuccess ?? const <TopicEntity>[];

  TopicEntity? byId(int id) {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }
}
