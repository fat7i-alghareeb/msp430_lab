import 'package:injectable/injectable.dart';

import '../../../../core/error/global_error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/repositories/topics_repository.dart';
import '../datasources/topics_local_datasource.dart';
import '../mappers/topic_model_mapper.dart';

@LazySingleton(as: TopicsRepository)
class TopicsRepositoryImpl implements TopicsRepository {
  const TopicsRepositoryImpl(this._local);

  final TopicsLocalDataSource _local;

  @override
  Future<Result<List<TopicEntity>>> getAllTopics() {
    return runAsResult(() async {
      final parts = (await _local.getParts()).map((p) => p.toEntity).toList();
      final topics = await _local.getTopics();
      return topics.map((t) => t.toEntity(parts)).toList();
    });
  }
}
