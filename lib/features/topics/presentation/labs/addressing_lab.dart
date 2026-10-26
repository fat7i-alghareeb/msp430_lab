import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

class _Mode {
  const _Mode(this.key, this.name, this.instruction, this.how, this.path, this.result);

  final String key;
  final String name;
  final String instruction;
  final String how;

  /// The parts the value passes through, from where it starts to R5.
  final List<String> path;
  final String result;
}

class _Part {
  const _Part(this.name, this.color, this.at, this.size);

  final String name;
  final Color color;
  final Vec3 at;
  final Vec3 size;
}

/// 1.4 · Where the value comes from, in each of the seven addressing modes.
class AddressingLab extends TopicLab {
  AddressingLab() {
    _run('reg');
  }

  static const List<_Mode> _modes = <_Mode>[
    _Mode('reg', 'المسجل', 'mov.w R4, R5', 'R5 ← R4 · دورة واحدة', <String>['r4', 'r5'], '0x0200'),
    _Mode('idx', 'المفهرس', 'mov.w 2(R4), R5', 'العنوان = R4 + 2 = 0x0202', <String>['fl', 'add', 'r4', 'add', 'm1', 'r5'], '0x2222'),
    _Mode('sym', 'الرمزي', 'mov.w VAR, R5', 'العنوان = PC + X = 0x0204', <String>['fl', 'add', 'pc', 'add', 'm2', 'r5'], '0x3333'),
    _Mode('abs', 'المطلق', 'mov.w &0x0206, R5', 'العنوان مكتوب كاملاً = 0x0206', <String>['fl', 'm3', 'r5'], '0x4444'),
    _Mode('ind', 'غير المباشر', 'mov.w @R4, R5', 'R4 يحمل العنوان 0x0200', <String>['r4', 'm0', 'r5'], '0x1111'),
    _Mode('inc', 'مع زيادة', 'mov.w @R4+, R5', 'يقرأ 0x0200 ثم R4 = R4 + 2', <String>['r4', 'm0', 'r5'], '0x1111'),
    _Mode('imm', 'الفوري', 'mov.w #0x1234, R5', 'القيمة نفسها بعد التعليمة', <String>['fl', 'r5'], '0x1234'),
  ];

  static const List<int> _memory = <int>[0x1111, 0x2222, 0x3333, 0x4444];

  static final Map<String, _Part> _parts = <String, _Part>{
    'r4': const _Part('R4', Color(0xFF5C8F72), Vec3(-5, 1.6, 3.5), Vec3(2.2, 1.6, 2.2)),
    'r5': const _Part('R5 (الوجهة)', Color(0xFF1B7350), Vec3(1, 1.6, 3.5), Vec3(2.2, 1.6, 2.2)),
    'pc': const _Part('PC = 0xF102', Color(0xFF2D5BA8), Vec3(-5, 1.6, 0), Vec3(2.2, 1.6, 2.2)),
    'add': const _Part('وحدة الجمع', Color(0xFFD49A00), Vec3(-1.5, 1.3, 0), Vec3(1.8, 1, 1.8)),
    'fl': const _Part('Flash · الكلمة بعد التعليمة', Color(0xFFC08A52), Vec3(-11, 1.5, -4), Vec3(4, 3, 4)),
    for (var i = 0; i < 4; i++)
      'm$i': _Part(
        '${_hex(0x0200 + i * 2)} = ${_hex(_memory[i])}',
        const Color(0xFF9DBFA9),
        Vec3(10, 0.9 + i * 1.8, -2),
        const Vec3(4, 1.6, 4),
      ),
  };

  static String _hex(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(4, '0')}';

  final Movers _movers = Movers();
  final Set<String> _lit = <String>{};
  late _Mode _mode;
  String _r5 = '—';
  String _r4 = '0x0200';
  int _gen = 0;

  @override
  CameraPose get home => const CameraPose(theta: 0, phi: 1, radius: 34, target: Vec3(0, 1, 0));

  Future<void> _run(String key) async {
    final g = ++_gen;
    _mode = _modes.firstWhere((m) => m.key == key);
    _movers.clear();
    _lit
      ..clear()
      ..add(_mode.path.first);
    _r5 = '—';
    _r4 = '0x0200';
    changed();
    for (var i = 1; i < _mode.path.length; i++) {
      final a = _parts[_mode.path[i - 1]]!.at + const Vec3(0, 1.2, 0);
      final b = _parts[_mode.path[i]]!.at + const Vec3(0, 1.2, 0);
      var arrived = false;
      _movers.go(
        Path3.arc(a, b),
        seconds: 0.7,
        color: SceneColors.goldBall,
        radius: 0.5,
        onDone: () => arrived = true,
      );
      while (!arrived) {
        if (!await wait(30) || g != _gen) return;
      }
      _lit.add(_mode.path[i]);
    }
    _r5 = _mode.result;
    if (_mode.key == 'inc') _r4 = '0x0202';
    changed();
  }

  @override
  void tick(double dt) => _movers.tick(dt);

  @override
  void build(SceneBuilder b) {
    buildFloor(b, 30, 16);
    b.box(11, 0.8, 8, SceneColors.green, -2, 0.4, 2, id: 'cpu');
    _parts.forEach((k, p) {
      b.box(p.size.x, p.size.y, p.size.z, p.color, p.at.x, p.at.y, p.at.z,
          id: 'part:$k', glow: _lit.contains(k) ? SceneColors.gold : null);
      final text = switch (k) {
        'r4' => 'R4 = $_r4',
        'r5' => 'R5 = $_r5',
        'pc' => 'PC',
        'add' => '+',
        'fl' => 'Flash',
        _ => p.name,
      };
      b.label(p.at + Vec3(0, p.size.y / 2 + 0.2, 0), text, LabelStyle.smallMono);
    });
    _movers.build(b);
  }

  @override
  String? describe(String id) {
    if (id == 'cpu') return 'المعالج CPU';
    if (!id.startsWith('part:')) return null;
    return _parts[id.substring(5)]!.name;
  }

  @override
  void runAction(String action) {
    if (action.startsWith('run:')) _run(action.substring(4));
  }

  @override
  List<LabControl> get controls => <LabControl>[
    LabChoice(
      options: <(String, String)>[for (final m in _modes) (m.key, m.name)],
      value: _mode.key,
      onChanged: (v) {
        userDid();
        _run(v);
      },
    ),
  ];

  @override
  List<String> get values => <String>[
    '${_mode.instruction}  →  R5 = $_r5',
    'نمط ${_mode.name}: ${_mode.how}',
  ];
}
