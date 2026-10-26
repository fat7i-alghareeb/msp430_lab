import 'package:injectable/injectable.dart';

import '../../../../core/error/global_error_handler.dart';
import '../models/root_model.dart';

/// Where the root feature reads its data from: content that ships with the
/// app, so there is no network and nothing to fail.
///
/// A new feature copies this shape: the data source returns models, the
/// repository maps them to entities, the facade is what a bloc talks to.
@lazySingleton
class RootLocalDataSource {
  const RootLocalDataSource();

  Future<List<RootModel>> getAllRoots() {
    return rethrowAsAppException(() async {
      return const <RootModel>[
        RootModel(id: 'home'),
        RootModel(id: 'topics'),
        RootModel(id: 'about'),
      ];
    });
  }
}
