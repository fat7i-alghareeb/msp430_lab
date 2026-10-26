import '../../domain/entities/root_entity.dart';
import '../models/root_model.dart';

extension RootModelMapper on RootModel {
  RootEntity get toEntity => RootEntity(id: id);
}
