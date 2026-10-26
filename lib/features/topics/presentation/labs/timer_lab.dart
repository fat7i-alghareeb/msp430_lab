import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

/// 2.4 · Timer_A counting up to TACCR0, its output set back at TACCR1
/// (OUTMOD 7), and a motor whose speed follows the duty cycle.
class TimerLab extends TopicLab {
  static const double _height = 10;
  static const int _top = 100;

  int _tar = 0;
  bool _out = true;
  int _duty = 40;
  double _avg = 0.4;
  double _acc = 0;
  double _fan = 0;

  @override
  CameraPose get home =>
      const CameraPose(theta: -0.35, phi: 1.05, radius: 34, target: Vec3(0, 4, 0));

  @override
  void tick(double dt) {
    _acc += dt * 60;
    while (_acc >= 1) {
      _acc -= 1;
      _tar++;
      if (_tar > _top) {
        _tar = 0;
        _out = _duty > 0;
      }
      if (_tar == _duty && _duty < 100) _out = false;
    }
    _avg += (_duty / 100 - _avg) * math.min(1, dt * 1.5);
    _fan += dt * _avg * 25;
  }

  @override
  void build(SceneBuilder b) {
    buildFloor(b, 30, 18);
    b.box(3.2, _height, 3.2, const Color(0xFF9AA3A0), -8, _height / 2, 0, opacity: 0.18);
    final h = math.max(0.02, _tar / _top * _height);
    b.box(2.8, h, 2.8, SceneColors.blue, -8, h / 2, 0, id: 'tar');
    b.box(6, 0.08, 6, SceneColors.copperDark, -8, _height, 0, opacity: 0.45);
    final ccr1 = _duty / 100 * _height;
    b.box(6, 0.08, 6, SceneColors.board, -8, ccr1, 0, opacity: 0.45);
    b.label(const Vec3(-4.6, _height, 0), 'TACCR0 · نهاية الدورة', LabelStyle.small);
    b.label(Vec3(-4.6, ccr1, 0), 'TACCR1 = ${_duty * 10}', LabelStyle.small);
    b.label(Vec3(-8, h + 0.6, 0), 'TAR = ${_tar * 10}', LabelStyle.darkMono);

    buildChip(b, scale: 0.45, pickPins: false);
    b.tube(const <Vec3>[Vec3(2.6, 0.3, 0), Vec3(7, 0.3, 0)], 0.15, SceneColors.copper,
        glow: _out ? const Color(0xFFFF5040) : null);
    b.sphere(0.5, _out ? SceneColors.ledOn : const Color(0xFF7A2A20), const Vec3(4.8, 1.1, 0),
        glow: _out ? SceneColors.ledOn : null);
    b.label(const Vec3(4.8, 2, 0), 'خرج TA1', LabelStyle.small);

    b.cylinder(1.8, 3.4, const Color(0xFF6F7880), 9.5, 1.8, 0, axis: Vec3.unitX, id: 'motor');
    b.cylinder(0.4, 0.4, const Color(0xFF333333), 11.6, 1.8, 0, axis: Vec3.unitX);
    for (var i = 0; i < 4; i++) {
      b.boxRotX(0.15, 3.4, 0.9, SceneColors.copperDark, 11.6, 1.8, 0, _fan + i * math.pi / 2,
          offset: const Vec3(0, 1.7, 0));
    }
  }

  @override
  String? describe(String id) => switch (id) {
    'tar' => 'TAR\nالعداد يصعد مع كل نبضة ساعة',
    'motor' => 'محرك\nسرعته تتبع نسبة التشغيل',
    _ => null,
  };

  void _setDuty(int d) {
    _duty = d.clamp(0, 100);
    changed();
  }

  @override
  void runAction(String action) {
    if (action.startsWith('duty:')) _setDuty(int.parse(action.substring(5)));
  }

  @override
  Vec3? focusOf(String id) => switch (id) {
    'bar' => const Vec3(-8, 4, 0),
    'motor' => const Vec3(10, 1, 0),
    _ => null,
  };

  @override
  List<LabControl> get controls => <LabControl>[
    LabSlider(
      label: 'نسبة التشغيل',
      min: 0,
      max: 100,
      divisions: 100,
      value: _duty.toDouble(),
      onChanged: (v) {
        userDid();
        _setDuty(v.round());
      },
    ),
  ];

  @override
  List<String> get values => <String>[
    'نسبة التشغيل $_duty% · TACCR1 = ${_duty * 10}',
    'TACCR0 = 1000 · OUTMOD 7',
    'المؤقت يولّد الإشارة دون تدخل المعالج',
  ];
}
