import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

class _Block {
  const _Block(this.key, this.name, this.text, this.x, this.z, this.w, this.d, this.color, this.h);

  final String key;
  final String name;
  final String text;
  final double x;
  final double z;
  final double w;
  final double d;
  final Color color;
  final double h;
}

/// 1.1 · The die and its twelve blocks, joined by the MAB and MDB buses.
class ArchLab extends TopicLab {
  static const List<_Block> _blocks = <_Block>[
    _Block('flash', 'Flash 60 KB', 'يخزّن البرنامج ولا يُمحى بانقطاع الكهرباء', -5, -6, 12, 8, Color(0xFFB07A45), 1.6),
    _Block('ram', 'RAM 2 KB', 'المتغيرات والمكدس', 6.5, -7, 7, 6, Color(0xFF5C8F72), 1.3),
    _Block('bsl', 'BSL + Info', 'محمّل الإقلاع وذاكرة المعلومات', 6.5, -2.4, 7, 2.6, Color(0xFF7D6AA6), 1),
    _Block('cpu', 'CPU 16-bit RISC', 'المعالج: 16 مسجلاً ووحدة ALU', -4, 2.8, 8, 5, Color(0xFF2F8A5E), 1.8),
    _Block('mpy', 'المضاعف', 'ضرب 16 × 16 بالعتاد', 2.6, 2.8, 3.4, 3.4, Color(0xFF3F7C9C), 1.2),
    _Block('cmp', 'Comparator_A', 'مقارن تناظري', 7.6, 2.8, 3.4, 3.4, Color(0xFF6F7F8C), 1),
    _Block('clk', 'الساعة', 'DCO و LFXT1 و XT2', -10, 2.8, 3, 5, Color(0xFFB9506E), 1.3),
    _Block('ta', 'Timer_A3', 'مؤقت بثلاث مقارنات', -9.5, 8.4, 4, 3.6, Color(0xFF3E68A8), 1.2),
    _Block('tb', 'Timer_B7', 'مؤقت بسبع مقارنات', -5.3, 8.4, 4, 3.6, Color(0xFF3E68A8), 1.2),
    _Block('wdt', 'WDT', 'مؤقت المراقبة', -1.6, 8.4, 3, 3.6, Color(0xFF4F79B5), 1),
    _Block('adc', 'ADC12', 'يحوّل الجهد إلى رقم', 2.4, 8.4, 4.6, 3.6, Color(0xFFB58A22), 1.4),
    _Block('usart', 'USART0 / 1', 'اتصال UART أو SPI', 7.6, 8.4, 5, 3.6, Color(0xFFA55A2A), 1.2),
  ];
  static const Set<String> _peripherals = <String>{
    'ta', 'tb', 'adc', 'usart', 'clk', 'wdt', 'cmp', 'mpy',
  };
  static const Color _hl = Color(0xFFF2C200);

  String? _highlight;
  String? _selected;
  bool _names = true;
  double _lift = 0;
  double _liftGoal = 0;

  @override
  CameraPose get home =>
      const CameraPose(theta: 0.35, phi: 0.85, radius: 40, target: Vec3(0, 0, 1));

  bool _lit(String key) =>
      _selected == key ||
      _highlight == key ||
      (_highlight == 'peri' && _peripherals.contains(key));

  @override
  void tick(double dt) {
    _lift += (_liftGoal - _lift) * math.min(1, dt * 4);
  }

  @override
  void build(SceneBuilder b) {
    b.box(26, 0.8, 26, SceneColors.die, 0, -0.4, 0, id: 'die');
    for (var i = 0; i < _blocks.length; i++) {
      final k = _blocks[i];
      final y = k.h / 2 + _lift * (1.5 + (i % 4) * 0.8);
      b.box(k.w, k.h, k.d, k.color, k.x, y, k.z, id: 'blk:${k.key}', glow: _lit(k.key) ? _hl : null);
      if (_names) b.label(Vec3(k.x, y + k.h / 2 + 0.2, k.z), k.name, LabelStyle.small);
    }
    final busLit = _highlight == 'bus';
    b.box(24, 0.12, 0.4, const Color(0xFFD9A23A), 0, 0.06, -0.9, id: 'mab', glow: busLit ? _hl : null);
    b.box(24, 0.12, 0.4, const Color(0xFF2D5BA8), 0, 0.06, -0.1, id: 'mdb', glow: busLit ? _hl : null);
    if (_names) b.label(const Vec3(11, 0.6, -1), 'MAB / MDB', LabelStyle.dark);
    for (var i = 0; i < 16; i++) {
      final o = -11.25 + i * 1.5;
      for (final (x, z) in <(double, double)>[(o, -12.4), (o, 12.4), (-12.4, o), (12.4, o)]) {
        b.box(0.7, 0.12, 0.7, const Color(0xFFE0C060), x, 0.06, z, id: 'pad');
      }
    }
  }

  @override
  String? describe(String id) {
    if (id.startsWith('blk:')) {
      final k = _blocks.firstWhere((e) => 'blk:${e.key}' == id);
      return '${k.name}\n${k.text}';
    }
    return switch (id) {
      'mab' => 'MAB · ناقل العناوين\n16 بت، يحمل العنوان من المعالج',
      'mdb' => 'MDB · ناقل البيانات\n16 بت، يحمل القيمة في الاتجاهين',
      'pad' => 'نقطة ربط\nيتصل بها سلك ذهبي يصل إلى أحد الأطراف',
      'die' => 'القالب السيليكوني\nكل ما على الشريحة مصنوع فوق قطعة سيليكون واحدة',
      _ => null,
    };
  }

  @override
  void onTap(String id) {
    if (id.startsWith('blk:')) {
      _selected = id.substring(4);
      _highlight = null;
      changed();
    }
  }

  @override
  void runAction(String action) {
    if (action.startsWith('hl:')) {
      final k = action.substring(3);
      _highlight = k == 'none' ? null : k;
      _selected = null;
      changed();
    }
  }

  @override
  Vec3? focusOf(String id) {
    if (id == 'bus') return const Vec3(0, 0, -0.5);
    if (id == 'peri') return const Vec3(0, 0, 7);
    for (final k in _blocks) {
      if (k.key == id) return Vec3(k.x, 0, k.z);
    }
    return null;
  }

  @override
  List<LabControl> get controls => <LabControl>[
    LabButtons(<LabButton>[
      LabButton('ارفع الوحدات / أنزلها', () {
        userDid();
        _liftGoal = _liftGoal == 0 ? 1 : 0;
      }),
      LabButton('الأسماء', () {
        userDid();
        _names = !_names;
        changed();
      }, primary: false),
    ]),
  ];

  @override
  List<String> get values {
    final sel = _selected ?? _highlight;
    final block = _blocks.where((k) => k.key == sel).firstOrNull;
    return <String>[
      if (block != null) '${block.name} · ${block.text}' else '12 وحدة · ناقلان MAB و MDB بـ 16 بت',
      'اضغط أي وحدة لمعرفة اسمها',
    ];
  }
}
