import 'package:get_it/get_it.dart' show GetIt;
import 'package:injectable/injectable.dart';

import 'injectable.config.dart';

/// Global GetIt instance used across the app.
final GetIt getIt = GetIt.instance;

/// Configures dependency injection using Injectable + GetIt.
///
/// This function delegates all app wiring to the generated
/// `GetItInjectableX.init()` extension.
@InjectableInit()
void configureDependencies() {
  getIt.init();
}
