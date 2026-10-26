import 'package:injectable/injectable.dart';

import '../services/haptics/haptics_service.dart';

import '../services/storage/storage_service.dart';

/// Third-party and platform objects the container cannot build itself.
@module
abstract class RegisterModule {
  @lazySingleton
  StorageService get storageService => StorageService.createDefault();

  /// Vibration on phones, nothing on desktop.
  @lazySingleton
  HapticsService get haptics => HapticsService.forPlatform();
}
