import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

class _Block {
  _Block(this.text, this.color, this.goal);

  final String text;
  final Color color;
  double goal;
  double y = 14;
}

/// 3.4 · A press wakes the CPU: PC and SR go on the stack, the vector table
/// gives the routine, RETI takes them back, and the CPU sleeps again.
class InterruptsLab extends TopicLab {
  static const List<(int, String)> _vectors = <(int, String)>[
    (0xFFFE, 'Reset'), (0xFFFC, 'NMI'), (0xFFFA, 'Timer_B'), (0xFFF8, 'Timer_B'),
    (0xFFF6, 'Comparator'), (0xFFF4, 'WDT'), (0xFFF2, 'USART0 RX'), (0xFFF0, 'USART0 TX'),
    (0xFFEE, 'ADC12'), (0xFFEC, 'Timer_A CCR0'), (0xFFEA, 'Timer_A'), (0xFFE8, 'Port 1'),
    (0xFFE6, 'USART1 RX'), (0xFFE4, 'USART1 TX'), (0xFFE2, 'Port 2'), (0xFFE0, '—'),
  ];
  static const Vec3 _chipAt = Vec3(-5, 0.4, 2);
  static const Vec3 _btnAt = Vec3(-11, 1.3, 6);
  static const Vec3 _timerAt = Vec3(-11, 1, -2);
  static const Vec3 _wall = Vec3(1, 0, -8);

  final Movers _movers = Movers();
  final List<_Block> _stack = <_Block>[];
  bool _busy = false;
  bool _awake = false;
  bool _led = false;
  bool _pressed = false;
  int? _litVector;
  int _count = 0;
  String _step = 'نائم في LPM3، ينتظر مقاطعة';

  @override
  CameraPose get home =>
      const CameraPose(theta: 0.15, phi: 1.02, radius: 38, target: Vec3(1, 3, 0));

  static String _hex(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(4, '0')}';

  Vec3 _tileAt(int index) {
    final r = index ~/ 4, c = index % 4;
    return _wall + Vec3(-4.5 + c * 3, 7.6 - r * 2, 0.35);
  }

  Future<bool> _shot(Vec3 from, Vec3 to) async {
    var arrived = false;
    _movers.go(Path3.arc(from, to, lift: 3.5),
        seconds: 0.8, color: SceneColors.goldBall, onDone: () => arrived = true);
    while (!arrived) {
      if (!await wait(30)) return false;
    }
    return true;
  }

  Future<bool> _say(String text, [int ms = 850]) async {
    _step = text;
    changed();
    return wait(ms);
  }

  Future<void> fire(String kind) async {
    if (_busy) return;
    _busy = true;
    final p1 = kind == 'p1';
    final vector = p1 ? 0xFFE8 : 0xFFEA;
    final chip = _chipAt + const Vec3(0, 1.2, 0);
    if (p1) {
      _pressed = true;
      Future<void>.delayed(const Duration(milliseconds: 200), () => _pressed = false);
    }
    _step = 'طلب مقاطعة من ${p1 ? 'Port 1' : 'Timer_A'}';
    changed();
    if (!await _shot((p1 ? _btnAt : _timerAt) + const Vec3(0, 1, 0), chip)) return;
    _awake = true;
    if (!await _say('المعالج يستيقظ', 650)) return;
    _stack.add(_Block('PC = 0xF016', SceneColors.blue, 8.6));
    if (!await _say('دفع PC إلى المكدس')) return;
    _stack.add(_Block('SR = 0x00D8', SceneColors.purple, 7));
    if (!await _say('دفع SR إلى المكدس')) return;
    final idx = _vectors.indexWhere((v) => v.$1 == vector);
    _litVector = idx;
    if (!await _say('قراءة العنوان من جدول المتجهات ${_hex(vector)}')) return;
    if (!await _shot(_tileAt(idx), chip)) return;
    _litVector = null;
    if (p1) _led = !_led;
    if (!await _say(p1 ? 'تنفيذ ISR: تبديل الـ LED' : 'تنفيذ ISR: عدّ ثانية', 950)) return;
    if (!await _say('RETI: سحب SR', 150)) return;
    _stack.last.goal = 16;
    if (!await wait(650)) return;
    if (!await _say('RETI: سحب PC', 150)) return;
    _stack.first.goal = 16;
    if (!await wait(650)) return;
    _stack.clear();
    _awake = false;
    _count++;
    _step = 'عاد إلى النوم في LPM3';
    _busy = false;
    changed();
  }

  @override
  void tick(double dt) {
    _movers.tick(dt);
    for (final s in _stack) {
      s.y += (s.goal - s.y) * math.min(1, dt * 5);
    }
  }

  @override
  void build(SceneBuilder b) {
    buildFloor(b, 34, 22);
    b.box(14, 0.8, 12, SceneColors.board, -6, 0, 2);
    buildChip(
      b,
      at: _chipAt,
      scale: 0.6,
      pickPins: false,
      bodyColor: _awake ? const Color(0xFF1F6B46) : SceneColors.chip,
      bodyGlow: _awake ? SceneColors.awake : null,
    );
    b.label(_chipAt + const Vec3(0, 1.8, 0), _awake ? 'نشط' : 'نائم · LPM3', LabelStyle.dark);
    b.box(2.4, 0.7, 2.4, const Color(0xFF2A2E31), _btnAt.x, 0.75, _btnAt.z, id: 'btn');
    b.cylinder(0.7, 0.5, const Color(0xFF8A9095), _btnAt.x, _pressed ? 1.1 : 1.3, _btnAt.z, id: 'btn');
    b.box(2.6, 1.2, 2.6, const Color(0xFF3E68A8), _timerAt.x, _timerAt.y, _timerAt.z, id: 'timer');
    b.label(_btnAt + const Vec3(0, 1.1, 0), 'زر Port 1', LabelStyle.small);
    b.label(_timerAt + const Vec3(0, 1.4, 0), 'Timer_A', LabelStyle.small);
    b.sphere(0.55, _led ? SceneColors.ledOn : const Color(0xFF7A2A20), const Vec3(-1, 1.2, 7),
        glow: _led ? SceneColors.ledOn : null);
    b.label(const Vec3(-1, 2.2, 7), 'LED', LabelStyle.small);

    b.box(4.4, 10, 4.4, const Color(0xFF5C9A75), 7, 5, 2, opacity: 0.14);
    b.label(const Vec3(7, 10.8, 2), 'المكدس في RAM');
    b.label(const Vec3(9.9, 8.6, 2), '0x09FE', LabelStyle.smallMono);
    b.label(const Vec3(9.9, 7, 2), '0x09FC', LabelStyle.smallMono);
    for (final s in _stack) {
      b.box(3.6, 1.4, 3.6, s.color, 7, s.y, 2);
      b.label(Vec3(7, s.y + 0.9, 2), s.text, LabelStyle.darkMono);
    }

    b.box(13, 9, 0.4, const Color(0xFFE5E9E3), _wall.x, 4.5, _wall.z);
    for (var i = 0; i < _vectors.length; i++) {
      final at = _tileAt(i);
      b.box(2.8, 1.7, 0.3, const Color(0xFFFFFFFF), at.x, at.y, at.z,
          id: 'vec:$i', glow: _litVector == i ? SceneColors.gold : null);
    }
    b.label(_wall + const Vec3(0, 9.6, 0), 'جدول المتجهات');
    b.label(_tileAt(11) + const Vec3(0, -1.2, 0.2), 'Port 1 · 0xFFE8', LabelStyle.smallMono);
    b.label(_tileAt(10) + const Vec3(0, 1.1, 0.2), 'Timer_A · 0xFFEA', LabelStyle.smallMono);
    _movers.build(b);
  }

  @override
  String? describe(String id) {
    if (id.startsWith('vec:')) {
      final v = _vectors[int.parse(id.substring(4))];
      return '${v.$2}\n${_hex(v.$1)}';
    }
    return switch (id) {
      'btn' => 'زر على P1.0\nاضغطه لتوليد مقاطعة',
      'timer' => 'Timer_A\nاضغطه لتوليد مقاطعة',
      'chip' => 'MSP430F149',
      _ => null,
    };
  }

  @override
  void onTap(String id) {
    if (id == 'btn') {
      userDid();
      fire('p1');
    } else if (id == 'timer') {
      userDid();
      fire('ta');
    }
  }

  @override
  void runAction(String action) {
    if (action.startsWith('fire:')) fire(action.substring(5));
  }

  @override
  List<LabControl> get controls => <LabControl>[
    LabButtons(<LabButton>[
      LabButton('اضغط زر Port 1', () {
        userDid();
        fire('p1');
      }, warm: true),
      LabButton('مقاطعة Timer_A', () {
        userDid();
        fire('ta');
      }),
    ]),
  ];

  @override
  List<String> get values => <String>[
    'الآن: $_step',
    'المقاطعات المكتملة: $_count',
  ];
}
