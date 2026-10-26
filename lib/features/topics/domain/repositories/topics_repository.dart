import '../../../../core/utils/result.dart';
import '../entities/topic_entity.dart';

abstract class TopicsRepository {
  Future<Result<List<TopicEntity>>> getAllTopics();
}
