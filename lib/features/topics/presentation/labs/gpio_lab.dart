import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

/// 2.2 · An LED on P1.0 and a button on P1.1, driven by P1DIR, P1OUT, P1IN.
class GpioLab extends TopicLab {
  int _dir = 0;
  int _out = 0;
  bool _pressed = false;

  static const Color _trace = Color(0xFFB5893F);
  static const Color _hot = Color(0xFFFF5040);

  double get _ledZ => pinXZ(12).z;
  double get _btnZ => pinXZ(13).z;

  bool get _ledOn => _dir == 1 && _out == 1;
  int get _in => (_ledOn ? 1 : 0) | (_pressed ? 2 : 0);

  @override
  CameraPose get home =>
      const CameraPose(theta: -0.55, phi: 0.9, radius: 30, target: Vec3(-3, 0, 1));

  String _hex(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(2, '0')}';

  @override
  void build(SceneBuilder b) {
    buildBoard(b, 34, 30);
    buildChip(b, pickPins: false);
    final lz = _ledZ, bz = _btnZ;
    b.box(5, 0.05, 0.25, _trace, -8.6, 0.03, lz, glow: _ledOn ? _hot : null);
    b.cylinder(0.7, 0.4, const Color(0xFFDDDDDD), -11.6, 0.2, lz);
    b.sphere(0.65, _ledOn ? SceneColors.ledOn : SceneColors.ledOff, Vec3(-11.6, 0.85, lz),
        id: 'led', glow: _ledOn ? SceneColors.ledOn : null);
    b.box(4, 0.05, 0.25, _trace, -8.1, 0.03, bz, glow: _pressed ? _hot : null);
    b.box(0.25, 0.05, 2.5, _trace, -10.1, 0.03, bz + 1.2, glow: _pressed ? _hot : null);
    b.box(2, 0.6, 2, const Color(0xFF2A2E31), -10.1, 0.3, bz + 3.2, id: 'btn');
    b.cylinder(0.55, 0.4, const Color(0xFF8A9095), -10.1, _pressed ? 0.55 : 0.75, bz + 3.2, id: 'btn');
    b.label(Vec3(-11.6, 1.8, lz), 'LED · P1.0', LabelStyle.small);
    b.label(Vec3(-10.1, 1.4, bz + 3.2), 'زر · P1.1', LabelStyle.small);
  }

  @override
  String? describe(String id) => switch (id) {
    'led' => 'LED\nعلى الطرف P1.0',
    'btn' => 'زر\nعلى الطرف P1.1 (دخل)',
    'chip' => 'MSP430F149',
    _ => null,
  };

  @override
  bool onPress(String id) {
    if (id != 'btn') return false;
    userDid();
    _pressed = true;
    changed();
    return true;
  }

  @override
  void onRelease() {
    if (!_pressed) return;
    _pressed = false;
    changed();
  }

  Future<void> _pressBriefly() async {
    _pressed = true;
    changed();
    if (!await wait(1600)) return;
    _pressed = false;
    changed();
  }

  @override
  void runAction(String action) {
    if (action == 'press') {
      _pressBriefly();
    } else if (action.startsWith('set:')) {
      final p = action.split(':');
      _dir = int.parse(p[1]);
      _out = int.parse(p[2]);
      changed();
    }
  }

  @override
  Vec3? focusOf(String id) => switch (id) {
    'led' => Vec3(-11.6, 0, _ledZ),
    'btn' => Vec3(-10.1, 0, _btnZ + 3.2),
    _ => null,
  };

  @override
  List<LabControl> get controls => <LabControl>[
    LabChoice(
      label: 'P1DIR.0',
      options: const <(String, String)>[('0', '0 · دخل'), ('1', '1 · خرج')],
      value: '$_dir',
      onChanged: (v) {
        userDid();
        _dir = int.parse(v);
        changed();
      },
    ),
    LabChoice(
      label: 'P1OUT.0',
      options: const <(String, String)>[('0', '0'), ('1', '1')],
      value: '$_out',
      onChanged: (v) {
        userDid();
        _out = int.parse(v);
        changed();
      },
    ),
  ];

  @override
  List<String> get values => <String>[
    'P1DIR = ${_hex(_dir)} · P1OUT = ${_hex(_out)} · P1IN = ${_hex(_in)}',
    if (_dir == 0)
      'الطرف دخل، فقيمة P1OUT لا تصل إليه'
    else if (_out == 1)
      'الطرف خرج وقيمته 1، فالـ LED مضاء'
    else
      'الطرف خرج وقيمته 0',
    'اضغط الزر على اللوحة واستمر لتغيّر P1IN',
  ];
}
