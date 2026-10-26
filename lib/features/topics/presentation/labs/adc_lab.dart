import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

/// 3.2 · A potentiometer on A0, and the 12-bit result as a column that
/// fills to 4095 at VREF+.
class AdcLab extends TopicLab {
  static const double _height = 11;

  double _vin = 1.8;
  double _ref = 2.5;
  double _shown = 0;

  @override
  CameraPose get home =>
      const CameraPose(theta: -0.3, phi: 1.05, radius: 32, target: Vec3(0, 4, 0));

  int get _n => math.min(4095, (4095 * _vin / _ref).round());
  bool get _saturated => _vin > _ref;

  @override
  void tick(double dt) {
    _shown += (_n - _shown) * math.min(1, dt * 6);
  }

  @override
  void build(SceneBuilder b) {
    buildFloor(b, 30, 18);
    b.box(4, 1.4, 4, SceneColors.blue, -10, 0.7, 0, id: 'pot');
    b.cylinder(1.3, 1.6, const Color(0xFF3A3F44), -10, 2.2, 0, id: 'pot');
    // The knob's pointer turns with the voltage.
    final ang = -_vin / 3.3 * 4.7;
    final dir = Vec3(math.sin(ang), 0, math.cos(ang));
    final tip = const Vec3(-10, 3.05, 0) + dir * 1.1;
    b.tube(<Vec3>[const Vec3(-10, 3.05, 0), tip], 0.15, const Color(0xFFF2F2F2));

    buildChip(b, scale: 0.45, pickPins: false);
    b.tube(const <Vec3>[Vec3(-8, 0.3, 0), Vec3(-2.6, 0.3, 0)], 0.15, SceneColors.copper);
    b.label(const Vec3(-5, 0.9, 0), 'A0 · P6.0', LabelStyle.smallMono);

    b.box(3.4, _height, 3.4, const Color(0xFF9AA3A0), 8, _height / 2, 0, opacity: 0.16);
    final h = math.max(0.02, _shown / 4095 * _height);
    b.box(3, h, 3, _saturated ? const Color(0xFFB2392F) : SceneColors.board, 8, h / 2, 0, id: 'mem');
    for (var i = 1; i < 4; i++) {
      b.box(3.6, 0.05, 3.6, SceneColors.pinDim, 8, _height * i / 4, 0);
    }
    b.box(4.2, 0.06, 4.2, SceneColors.copperDark, 8, _height, 0, opacity: 0.5);
    b.label(const Vec3(10.6, _height, 0), '4095 = VREF+', LabelStyle.smallMono);
    b.label(const Vec3(10.2, _height / 2, 0), '2048', LabelStyle.smallMono);
    b.label(const Vec3(10.2, 0.2, 0), '0', LabelStyle.smallMono);
    b.label(Vec3(8, h + 0.8, 0), '${_shown.round()}', LabelStyle.hot);
  }

  @override
  String? describe(String id) => switch (id) {
    'pot' => 'مقاومة متغيرة\nتعطي جهداً من 0 إلى 3.3 V',
    'mem' => 'ADC12MEM0\nنتيجة التحويل من 0 إلى 4095',
    _ => null,
  };

  void _set(double v, double ref) {
    _vin = v;
    _ref = ref;
    changed();
  }

  @override
  void runAction(String action) {
    if (!action.startsWith('set:')) return;
    final p = action.split(':');
    _set(double.parse(p[1]), double.parse(p[2]));
  }

  @override
  List<LabControl> get controls => <LabControl>[
    LabSlider(
      label: 'أدر المقاومة (V)',
      min: 0,
      max: 3.3,
      divisions: 66,
      value: _vin,
      onChanged: (v) {
        userDid();
        _set(v, _ref);
      },
    ),
    LabChoice(
      label: 'VREF+',
      options: const <(String, String)>[('1.5', '1.5 V'), ('2.5', '2.5 V')],
      value: _ref == 1.5 ? '1.5' : '2.5',
      onChanged: (v) {
        userDid();
        _set(_vin, double.parse(v));
      },
    ),
  ];

  @override
  List<String> get values => <String>[
    'ADC12MEM0 = $_n · Vin = ${_vin.toStringAsFixed(2)} V',
    'N = 4095 × ${_vin.toStringAsFixed(2)} / $_ref',
    if (_saturated) 'الجهد أكبر من VREF+: تشبّع عند 4095',
  ];
}
