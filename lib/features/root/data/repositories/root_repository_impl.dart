import 'package:injectable/injectable.dart';

import '../../../../core/error/global_error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/root_entity.dart';
import '../../domain/repositories/root_repository.dart';
import '../datasources/root_local_datasource.dart';
import '../mappers/root_model_mapper.dart';

@LazySingleton(as: RootRepository)
class RootRepositoryImpl implements RootRepository {
  const RootRepositoryImpl(this._local);

  final RootLocalDataSource _local;

  @override
  Future<Result<List<RootEntity>>> getAllRoots() {
    return runAsResult(() async {
      final models = await _local.getAllRoots();
      return models.map((e) => e.toEntity).toList();
    });
  }
}
