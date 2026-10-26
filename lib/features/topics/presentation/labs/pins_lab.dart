import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

/// 2.1 · The 64 pins, coloured by port.
class PinsLab extends TopicLab {
  static const Map<String, String> _ranges = <String, String>{
    'P1': '12–19',
    'P2': '20–27',
    'P3': '28–35',
    'P4': '36–43',
    'P5': '44–51',
    'P6': '2–6 و 59–61',
    'clk': '8، 9، 52، 53',
  };

  static const Map<String, Vec3> _focus = <String, Vec3>{
    'P1': Vec3(-5.5, 0, 1.75),
    'P2': Vec3(-1, 0, 5.5),
    'P3': Vec3(4, 0, 4),
    'P4': Vec3(5.5, 0, -1),
    'P5': Vec3(1, 0, -5.5),
    'P6': Vec3(-3, 0, -5.5),
    'clk': Vec3(-5.5, 0, 0.25),
  };

  String _port = 'all';
  int? _pin;

  @override
  CameraPose get home => const CameraPose(theta: 0.7, phi: 0.95, radius: 30);

  void _setPort(String p) {
    _port = p;
    _pin = null;
    changed();
  }

  @override
  void build(SceneBuilder b) {
    buildBoard(b, 34, 30);
    buildPads(b);
    buildChip(
      b,
      pinColor: (n) {
        if (_pin == n) return SceneColors.gold;
        if (_port == 'all') return SceneColors.pin;
        final g = f149Pins[n].group;
        return g == _port ? portColors[g]! : SceneColors.pinDim;
      },
    );
    for (final n in const <int>[1, 16, 17, 32, 33, 48, 49, 64]) {
      final p = pinXZ(n);
      b.label(Vec3(p.x * 1.25, 0.4, p.z * 1.25), '$n', LabelStyle.darkMono);
    }
  }

  @override
  String? describe(String id) {
    if (id.startsWith('pin:')) return pinDescription(int.parse(id.substring(4)));
    if (id == 'chip') return 'MSP430F149\nغلاف QFP بـ 64 طرفاً، 10 × 10 mm';
    return null;
  }

  @override
  void onTap(String id) {
    if (!id.startsWith('pin:')) return;
    userDid();
    _pin = int.parse(id.substring(4));
    changed();
  }

  @override
  void runAction(String action) {
    if (action.startsWith('port:')) _setPort(action.substring(5));
  }

  @override
  Vec3? focusOf(String id) => _focus[id];

  @override
  List<LabControl> get controls => <LabControl>[
    LabChoice(
      options: const <(String, String)>[
        ('all', 'الكل'),
        ('P1', 'P1'),
        ('P2', 'P2'),
        ('P3', 'P3'),
        ('P4', 'P4'),
        ('P5', 'P5'),
        ('P6', 'P6'),
        ('clk', 'الساعة'),
      ],
      value: _port,
      onChanged: (v) {
        userDid();
        _setPort(v);
      },
    ),
  ];

  @override
  List<String> get values {
    final pin = _pin;
    if (pin != null) {
      final p = f149Pins[pin];
      return <String>['الطرف $pin · ${p.name}', portNames[p.group] ?? ''];
    }
    if (_port == 'all') {
      return <String>[
        '6 منافذ × 8 أطراف = 48 طرف دخل وخرج',
        'الباقي للتغذية والساعة والبرمجة',
      ];
    }
    return <String>[
      '$_port · الأطراف ${_ranges[_port]}',
      portNames[_port] ?? '',
      if (_port == 'P4') 'في مشروع الفصل 13: ثمانية مرحّلات',
    ];
  }
}
