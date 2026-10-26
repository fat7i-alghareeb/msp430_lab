import 'dart:async';

import 'package:vibration/vibration.dart';

import '../../platform/app_platform.dart';

/// A short buzz under the finger on press and on tap.
///
/// One interface, one implementation per platform family, chosen once at
/// registration (`RegisterModule.haptics`): `vibration` ships Android and
/// iOS code only, so desktop gets [NoHaptics] instead of a call that would
/// throw `MissingPluginException` (`docs/DESKTOP_SETUP.md`).
abstract class HapticsService {
  /// The service for the platform the app runs on.
  factory HapticsService.forPlatform() =>
      AppPlatform.supportsVibration ? VibrationHaptics() : const NoHaptics();

  /// The finger lands.
  void press();

  /// The tap completes.
  void tap();
}

/// Android and iOS: the `vibration` package, if the device has a motor.
class VibrationHaptics implements HapticsService {
  VibrationHaptics();

  bool? _hasVibrator;
  Future<bool>? _checking;

  @override
  void press() => _buzz(duration: 10, amplitude: 40);

  @override
  void tap() => _buzz(duration: 15, amplitude: 70);

  void _buzz({required int duration, required int amplitude}) {
    unawaited(() async {
      try {
        if (!await _canVibrate()) return;
        await Vibration.vibrate(duration: duration, amplitude: amplitude);
      } catch (_) {
        // Haptics are a nicety; a failure is never the user's problem.
      }
    }());
  }

  Future<bool> _canVibrate() {
    final cached = _hasVibrator;
    if (cached != null) return Future<bool>.value(cached);
    return _checking ??= () async {
      try {
        return _hasVibrator = await Vibration.hasVibrator();
      } catch (_) {
        return _hasVibrator = false;
      } finally {
        _checking = null;
      }
    }();
  }
}

/// Desktop: nothing to vibrate.
class NoHaptics implements HapticsService {
  const NoHaptics();

  @override
  void press() {}

  @override
  void tap() {}
}
