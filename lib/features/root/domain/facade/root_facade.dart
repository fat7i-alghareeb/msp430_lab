import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../entities/root_entity.dart';
import '../repositories/root_repository.dart';

@lazySingleton
class RootFacade {
  const RootFacade(this._repository);

  final RootRepository _repository;

  Future<Result<List<RootEntity>>> getAllRoots() {
    return _repository.getAllRoots();
  }
}
