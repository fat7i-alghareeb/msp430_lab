import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../entities/topic_entity.dart';
import '../repositories/topics_repository.dart';

/// What the presentation layer asks for topics.
@lazySingleton
class TopicsFacade {
  const TopicsFacade(this._repository);

  final TopicsRepository _repository;

  Future<Result<List<TopicEntity>>> getAllTopics() {
    return _repository.getAllTopics();
  }
}
