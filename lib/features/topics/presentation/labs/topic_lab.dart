import 'package:flutter/foundation.dart';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene3d_view.dart';
import '../../../../core/scene3d/vec3.dart';

/// A control a lab offers under «try it yourself». The topic screen draws
/// them the same way on the phone and on Windows (`LabControlsView`).
sealed class LabControl {
  const LabControl();
}

/// A row of buttons.
class LabButtons extends LabControl {
  const LabButtons(this.buttons);

  final List<LabButton> buttons;
}

class LabButton {
  const LabButton(this.label, this.onTap, {this.primary = true, this.warm = false});

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool warm;
}

/// One choice among a few.
class LabChoice extends LabControl {
  const LabChoice({
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final String? label;

  /// (value, label) pairs.
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
}

/// A value along a range.
class LabSlider extends LabControl {
  const LabSlider({
    required this.label,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double min;
  final double max;
  final double value;
  final int? divisions;
  final ValueChanged<double> onChanged;
}

/// A single character to send.
class LabCharField extends LabControl {
  const LabCharField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;
}

/// A strip of bit cells; [current] lights up, those before it are done.
class LabBits extends LabControl {
  const LabBits({required this.bits, required this.current});

  final List<String> bits;
  final int current;
}

/// One interactive topic: its scene, its controls, its values, and the
/// actions its tour can run.
///
/// The scene is drawn from the lab's state every frame ([build]). The lab
/// notifies when its controls or values change, so the panels rebuild.
abstract class TopicLab extends ChangeNotifier implements SceneSource {
  bool _disposed = false;

  /// True once the topic page has gone: timers and sequences stop.
  bool get disposed => _disposed;

  /// Called whenever the reader touches a control, so the tour stops.
  VoidCallback? onUserAction;

  /// Runs a tour step's action by the lab's own name for it.
  void runAction(String action);

  /// Where the camera goes for a tour step's `focus`. Null: stay.
  Vec3? focusOf(String id) => null;

  /// How far in the camera comes for a focus, as a part of the home distance.
  double get focusCloseness => 0.62;

  /// The controls under «try it yourself», built from the current state.
  List<LabControl> get controls;

  /// The values card, one line each. The first line is the phone's strip.
  List<String> get values;

  /// Call from a control's handler before changing state.
  void userDid() => onUserAction?.call();

  /// Rebuilds the panels.
  void changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  CameraPose get home;

  @override
  String? describe(String id) => null;

  @override
  void onTap(String id) {}

  @override
  bool onPress(String id) => false;

  @override
  void onRelease() {}

  @override
  void tick(double dt) {}

  /// Waits [ms] milliseconds; false once the page has gone.
  Future<bool> wait(int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    return !_disposed;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
