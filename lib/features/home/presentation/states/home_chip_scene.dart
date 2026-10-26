import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene3d_view.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import '../../../topics/domain/entities/topic_entity.dart';
import '../../../topics/presentation/labs/chip_parts.dart';

/// The home screen: the chip with a see-through lid, its die and blocks
/// showing, and one numbered dot per topic where that topic lives.
class HomeChipScene implements SceneSource {
  HomeChipScene(this.topics);

  final List<TopicEntity> topics;

  /// Where each topic's dot sits on the chip.
  static const Map<int, Vec3> spots = <int, Vec3>{
    1: Vec3(-0.8, 1.25, 0.6),
    2: Vec3(-1.2, 1.25, -1.6),
    3: Vec3(0.9, 1.25, 0.4),
    4: Vec3(1.7, 1.25, -1.9),
    5: Vec3(3.75, 0.6, -6.6),
    6: Vec3(-6.6, 0.6, 3),
    7: Vec3(-10.5, 2.3, 0),
    8: Vec3(-2.2, 1.25, 2.1),
    9: Vec3(4.5, 3.2, 4.5),
    10: Vec3(0.5, 1.25, 2.1),
    11: Vec3(2, 1.25, 2.6),
    12: Vec3(-0.75, 0.6, -6.6),
  };

  static const List<(String, double, double, double, double, Color)> _die =
      <(String, double, double, double, double, Color)>[
        ('FLASH', -1.14, -1.56, 3, 2.16, Color(0xFFB07A45)),
        ('RAM', 1.62, -1.92, 2.04, 1.44, Color(0xFF5C8F72)),
        ('BSL', 1.62, -0.75, 2.04, 0.54, Color(0xFF7D6AA6)),
        ('CPU', -0.78, 0.6, 2.04, 1.2, Color(0xFF2F8A5E)),
        ('MPY', 0.96, 0.42, 0.96, 0.84, Color(0xFF3F7C9C)),
        ('CLK', -2.28, 0.6, 0.72, 1.2, Color(0xFFB9506E)),
        ('TA', -2.22, 2.07, 0.84, 1.02, Color(0xFF3E68A8)),
        ('TB', -1.26, 2.07, 0.84, 1.02, Color(0xFF3E68A8)),
        ('ADC', 0.51, 2.07, 1.02, 1.02, Color(0xFFB58A22)),
        ('USART', 1.89, 2.07, 1.5, 1.02, Color(0xFFA55A2A)),
      ];

  /// A phone's view: closer and more from above, so the twelve dots spread
  /// out over the small chip.
  static const CameraPose phoneHome = CameraPose(
    theta: 0.25,
    phi: 0.55,
    radius: 19,
    target: Vec3(-2.5, 0, 0),
  );

  @override
  CameraPose get home =>
      const CameraPose(theta: 0.55, phi: 0.86, radius: 30, target: Vec3(-1, 0, 0));

  @override
  void build(SceneBuilder b) {
    buildBoard(b, 36, 30);
    buildPads(b);
    b.box(6, 0.3, 6, SceneColors.die, 0, 0.62, 0);
    for (final (_, x, z, w, d, c) in _die) {
      b.box(w, 0.12, d, c, x, 0.83, z);
    }
    buildChip(b, ghost: true);
    b.cylinder(0.9, 3.6, const Color(0xFFD3D8DB), -10.5, 0.9, 0,
        axis: Vec3.unitZ, id: 'crystal');
    for (final t in topics) {
      final at = spots[t.id];
      if (at == null) continue;
      b.hotspot(at, '${t.indexInPart}', t.part.color, 'topic:${t.id}', tooltip: t.title);
    }
  }

  @override
  void tick(double dt) {}

  @override
  String? describe(String id) {
    if (id.startsWith('pin:')) return pinDescription(int.parse(id.substring(4)));
    if (id == 'crystal') return 'كريستالة 32.768 kHz\nعلى الطرفين 8 و9';
    return null;
  }

  @override
  void onTap(String id) {}

  @override
  bool onPress(String id) => false;

  @override
  void onRelease() {}
}
