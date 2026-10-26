import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

class _Floor {
  const _Floor(this.key, this.name, this.address, this.height, this.color);

  final String key;
  final String name;
  final String address;
  final double height;
  final Color color;
}

/// 1.2 · The address space as a tower, 0x0000 at the bottom.
class MemoryLab extends TopicLab {
  MemoryLab() {
    var y = 0.0;
    for (final f in _floors) {
      _bottoms[f.key] = y;
      y += f.height;
    }
    _go('flash');
  }

  static const List<_Floor> _floors = <_Floor>[
    _Floor('sfr', 'SFR · مسجلات خاصة', '0x0000', 0.7, Color(0xFF8FA9C9)),
    _Floor('p8', 'طرفيات 8 بت', '0x0010', 1.3, Color(0xFFA9C1DE)),
    _Floor('p16', 'طرفيات 16 بت', '0x0100', 1.3, Color(0xFF7FA3D1)),
    _Floor('ram', 'RAM 2 KB', '0x0200', 3, Color(0xFF5C9A75)),
    _Floor('un', 'فارغ', '0x0A00', 0.6, Color(0xFFD5DAD3)),
    _Floor('bsl', 'محمّل الإقلاع BSL', '0x0C00', 1.1, Color(0xFF9C88C4)),
    _Floor('info', 'ذاكرة المعلومات', '0x1000', 0.9, Color(0xFFC9A0D8)),
    _Floor('flash', 'Flash · البرنامج', '0x1100', 6, Color(0xFFC08A52)),
    _Floor('vec', 'جدول المتجهات', '0xFFE0', 0.8, Color(0xFFC9554A)),
  ];

  /// Where each named spot points: floor, height within it, and its label.
  static const Map<String, (String, double, String, String)> _spots =
      <String, (String, double, String, String)>{
        'flash': ('flash', 0.5, 'البرنامج', '0x1100'),
        'vars': ('ram', 0.15, 'المتغيرات', '0x0200'),
        'stack': ('ram', 0.92, 'المكدس', '0x09FE'),
        'ports': ('p8', 0.5, 'P1OUT', '0x0021'),
        'reset': ('vec', 0.5, 'RESET', '0xFFFE'),
      };

  final Map<String, double> _bottoms = <String, double>{};
  late String _floor;
  late String _title;
  late String _address;
  double _markerY = 1;
  double _markerGoal = 1;

  @override
  CameraPose get home =>
      const CameraPose(theta: 0.75, phi: 1.2, radius: 34, target: Vec3(0, 8, 0));

  _Floor _byKey(String k) => _floors.firstWhere((f) => f.key == k);

  double _heightOf(String floor, double frac) =>
      _bottoms[floor]! + _byKey(floor).height * frac;

  void _go(String spot) {
    final (floor, frac, title, address) = _spots[spot]!;
    _floor = floor;
    _title = title;
    _address = address;
    _markerGoal = _heightOf(floor, frac);
    changed();
  }

  @override
  void tick(double dt) {
    _markerY += (_markerGoal - _markerY) * math.min(1, dt * 4);
  }

  @override
  void build(SceneBuilder b) {
    b.box(16, 0.4, 16, SceneColors.floor, 0, -0.2, 0);
    for (final f in _floors) {
      final y = _bottoms[f.key]!;
      b.box(
        9,
        f.height - 0.12,
        9,
        f.color,
        0,
        y + f.height / 2,
        0,
        id: 'floor:${f.key}',
        glow: f.key == _floor ? const Color(0xFF334433) : null,
      );
      b.label(Vec3(4.6, y + f.height / 2, 4.6), '${f.name} · ${f.address}', LabelStyle.small);
    }
    final marker = Vec3(-6, _markerY, 0);
    b.sphere(0.6, SceneColors.goldBall, marker, glow: SceneColors.gold);
    b.label(marker + const Vec3(0, 1, 0), '$_title · $_address', LabelStyle.hot);
  }

  @override
  String? describe(String id) {
    if (!id.startsWith('floor:')) return null;
    final f = _byKey(id.substring(6));
    return '${f.name}\nيبدأ من ${f.address}';
  }

  @override
  void onTap(String id) {
    if (!id.startsWith('floor:')) return;
    userDid();
    final f = _byKey(id.substring(6));
    _floor = f.key;
    _title = f.name;
    _address = f.address;
    _markerGoal = _heightOf(f.key, 0.5);
    changed();
  }

  @override
  void runAction(String action) {
    if (action.startsWith('go:')) _go(action.substring(3));
  }

  @override
  Vec3? focusOf(String id) {
    final s = _spots[id];
    return s == null ? null : Vec3(0, _heightOf(s.$1, s.$2), 0);
  }

  @override
  List<LabControl> get controls => <LabControl>[
    LabButtons(<LabButton>[
      LabButton('البرنامج', () => _user('flash')),
      LabButton('المتغيرات', () => _user('vars')),
      LabButton('المكدس', () => _user('stack')),
      LabButton('المنافذ', () => _user('ports'), primary: false),
      LabButton('بداية التشغيل', () => _user('reset'), primary: false),
    ]),
  ];

  void _user(String spot) {
    userDid();
    _go(spot);
  }

  @override
  List<String> get values => <String>[
    'المؤشر عند $_title · $_address',
    'كل الذاكرة في فضاء عناوين واحد من 0x0000 إلى 0xFFFF',
  ];
}
