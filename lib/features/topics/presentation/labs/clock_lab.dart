import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

class _Mode {
  const _Mode(this.name, this.mclk, this.smclk, this.aclk, this.dco, this.microAmps);

  final String name;
  final bool mclk;
  final bool smclk;
  final bool aclk;
  final bool dco;
  final double microAmps;
}

/// 2.3 · Three clock sources, three clocks, and the low-power modes that
/// stop them (the book's Table 12.1).
class ClockLab extends TopicLab {
  static const Map<String, _Mode> _modes = <String, _Mode>{
    'am': _Mode('نشط', true, true, true, true, 280),
    'lpm0': _Mode('LPM0', false, true, true, true, 35),
    'lpm3': _Mode('LPM3', false, false, true, false, 1.6),
    'lpm4': _Mode('LPM4', false, false, false, false, 0.1),
  };

  static const List<Color> _colors = <Color>[
    Color(0xFF2F8A5E),
    Color(0xFF3E68A8),
    Color(0xFF7A6AA8),
  ];
  static const List<Color> _pulse = <Color>[
    Color(0xFF7CF0A8),
    Color(0xFF9CC0FF),
    Color(0xFFD9C6FF),
  ];

  static final List<Path3> _wires = <Path3>[
    Path3(const <Vec3>[Vec3(-10.3, 0.5, -0.6), Vec3(-2, 0.5, -0.6), Vec3(-2, 0.5, -7), Vec3(8, 0.5, -7)]),
    Path3(const <Vec3>[Vec3(-10.3, 0.5, 0.4), Vec3(8, 0.5, 0.4)]),
    Path3(const <Vec3>[Vec3(-9.9, 0.5, -7.3), Vec3(-6, 0.5, -7.3), Vec3(-6, 0.5, 7), Vec3(8, 0.5, 7)]),
  ];

  String _mode = 'am';
  double _t = 0;

  @override
  CameraPose get home => const CameraPose(theta: 0, phi: 0.95, radius: 38);

  _Mode get _m => _modes[_mode]!;

  @override
  void tick(double dt) => _t += dt;

  @override
  void build(SceneBuilder b) {
    buildFloor(b, 34, 24);
    final m = _m;
    const off = SceneColors.grey;
    b.cylinder(1.1, 4, m.aclk ? const Color(0xFFD3D8DB) : const Color(0xFF8E9693), -12, 1.1, -7,
        axis: Vec3.unitX, id: 'lfxt1');
    b.box(3.4, 1.6, 3, m.dco ? const Color(0xFFB9506E) : off, -12, 0.8, 0, id: 'dco');
    b.cylinder(1.1, 4, const Color(0xFFBFC4C6), -12, 1.1, 7, axis: Vec3.unitX, id: 'xt2');
    final on = <bool>[m.mclk, m.smclk, m.aclk];
    final targets = <(Vec3, Vec3, String)>[
      (const Vec3(11, 1, -7), const Vec3(6, 2, 4), 'cpu'),
      (const Vec3(11, 0.8, 0), const Vec3(6, 1.6, 4), 'fast'),
      (const Vec3(11, 0.8, 7), const Vec3(6, 1.6, 4), 'slow'),
    ];
    for (var i = 0; i < 3; i++) {
      final (at, size, id) = targets[i];
      b.box(size.x, size.y, size.z, on[i] ? _colors[i] : off, at.x, at.y, at.z, id: id);
      b.tube(_wires[i].points, 0.18, on[i] ? _colors[i] : const Color(0xFFB9BFBA));
      if (on[i]) {
        final count = i == 2 ? 3 : 14;
        final speed = <double>[1.6, 0.9, 0.12][i];
        for (var k = 0; k < count; k++) {
          final u = (k / count + _t * speed * 0.25) % 1;
          b.sphere(0.32, _pulse[i], _wires[i].at(u), glow: _pulse[i]);
        }
      }
    }
    b.label(const Vec3(2, 0.9, -7), 'MCLK', LabelStyle.smallMono);
    b.label(const Vec3(2, 0.9, 0.4), 'SMCLK', LabelStyle.smallMono);
    b.label(const Vec3(2, 0.9, 7), 'ACLK', LabelStyle.smallMono);
    b.label(const Vec3(-12, 2.6, -7), 'LFXT1 32 kHz', LabelStyle.small);
    b.label(const Vec3(-12, 2.2, 0), 'DCO', LabelStyle.small);
    b.label(const Vec3(-12, 2.6, 7), 'XT2', LabelStyle.small);
    b.label(const Vec3(11, 2.6, -7), m.mclk ? 'CPU يعمل' : 'CPU متوقف');
    b.label(const Vec3(11, 2.2, 0), 'Timer_A · USART', LabelStyle.small);
    b.label(const Vec3(11, 2.2, 7), 'Timer_A · WDT', LabelStyle.small);
  }

  @override
  String? describe(String id) => switch (id) {
    'lfxt1' => 'LFXT1\nكريستالة 32 768 Hz، دقيقة وبطيئة',
    'dco' => 'DCO\nمذبذب داخلي سريع يمكن تغيير تردده',
    'xt2' => 'XT2\nكريستالة سريعة اختيارية',
    'cpu' => 'CPU\nيأخذ ساعته من MCLK',
    'fast' => 'Timer_A و USART\nيأخذان ساعتهما من SMCLK',
    'slow' => 'Timer_A و WDT\nيأخذان ساعتهما من ACLK',
    _ => null,
  };

  void _set(String mode) {
    _mode = mode;
    changed();
  }

  @override
  void runAction(String action) {
    if (action.startsWith('mode:')) _set(action.substring(5));
  }

  @override
  List<LabControl> get controls => <LabControl>[
    LabChoice(
      options: <(String, String)>[for (final e in _modes.entries) (e.key, e.value.name)],
      value: _mode,
      onChanged: (v) {
        userDid();
        _set(v);
      },
    ),
  ];

  @override
  List<String> get values {
    final m = _m;
    final hours = 225e3 / m.microAmps;
    final days = hours / 24;
    final life = days > 365
        ? (hours / 8760 > 10 ? 'أكثر من 10 سنوات' : '${(hours / 8760).toStringAsFixed(1)} سنة')
        : '${days.toStringAsFixed(0)} يوماً';
    final amps = m.microAmps >= 10 ? m.microAmps.toStringAsFixed(0) : m.microAmps.toStringAsFixed(1);
    return <String>[
      '${m.name} · I ≈ $amps µA',
      'عمر بطارية CR2032: $life',
      'MCLK ${m.mclk ? 'تعمل' : 'متوقفة'} · SMCLK ${m.smclk ? 'تعمل' : 'متوقفة'} · ACLK ${m.aclk ? 'تعمل' : 'متوقفة'}',
    ];
  }
}
