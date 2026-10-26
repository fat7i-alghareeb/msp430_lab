import '../../../../core/utils/result.dart';
import '../entities/root_entity.dart';

abstract class RootRepository {
  Future<Result<List<RootEntity>>> getAllRoots();
}
