import 'dart:ui';
import 'dart:math' as math;

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

class _Instr {
  const _Instr(this.address, this.text, this.run, this.size);

  final int address;
  final String text;

  /// Runs the instruction; returns the jump target, or null to go on.
  final int? Function() run;
  final int size;
}

/// 1.3 · R0–R15 as a 16 × 16 grid of bits, running a loop that adds
/// 5 + 4 + 3 + 2 + 1.
class RegistersLab extends TopicLab {
  RegistersLab() {
    _program = <_Instr>[
      _Instr(0xF000, 'mov.w #0x0A00, SP', () {
        _r[1] = 0x0A00;
        return null;
      }, 4),
      _Instr(0xF004, 'mov.w #5, R4', () {
        _r[4] = 5;
        return null;
      }, 4),
      _Instr(0xF008, 'clr.w R5', () {
        _r[5] = 0;
        return null;
      }, 2),
      _Instr(0xF00A, 'add.w R4, R5', () {
        final t = _r[5] + _r[4];
        _c = t > 0xFFFF;
        _v = false;
        _r[5] = t & 0xFFFF;
        _setNZ(_r[5]);
        return null;
      }, 2),
      _Instr(0xF00C, 'dec.w R4', () {
        final o = _r[4];
        _c = o >= 1;
        _r[4] = (o - 1) & 0xFFFF;
        _setNZ(_r[4]);
        return null;
      }, 2),
      _Instr(0xF00E, 'jnz loop', () => _z ? null : 0xF00A, 2),
      _Instr(0xF010, 'jmp \$  ← انتهى', () => 0xF010, 2),
    ];
    reset();
  }

  static const List<String> _names = <String>[
    'R0 · PC', 'R1 · SP', 'R2 · SR', 'R3 · CG', 'R4', 'R5', 'R6', 'R7',
    'R8', 'R9', 'R10', 'R11', 'R12', 'R13', 'R14', 'R15',
  ];

  late final List<_Instr> _program;
  final List<int> _r = List<int>.filled(16, 0);
  List<int> _prev = List<int>.filled(16, 0);
  bool _n = false, _z = false, _c = false, _v = false;
  String _last = '—';
  double _flash = 0;
  bool _running = false;
  double _acc = 0;

  @override
  CameraPose get home => const CameraPose(theta: 0, phi: 0.78, radius: 34);

  void _setNZ(int v) {
    _n = (v >> 15) & 1 == 1;
    _z = v == 0;
  }

  int get _sr => (_c ? 1 : 0) | (_z ? 2 : 0) | (_n ? 4 : 0) | (_v ? 256 : 0);

  _Instr? get _next {
    for (final i in _program) {
      if (i.address == _r[0]) return i;
    }
    return null;
  }

  bool get _done => _r[0] == 0xF010;

  void reset() {
    _prev = List<int>.of(_r);
    _r.fillRange(0, 16, 0);
    _n = _z = _c = _v = false;
    _r[0] = 0xF000;
    _r[2] = _sr;
    _last = '—';
    _running = false;
    _flash = 1;
    changed();
  }

  void step() {
    final i = _next;
    if (i == null) return;
    _prev = List<int>.of(_r);
    final jump = i.run();
    _last = i.text;
    _r[0] = jump ?? i.address + i.size;
    _r[2] = _sr;
    _flash = 1;
    changed();
  }

  void toEnd() {
    var guard = 0;
    while (!_done && guard++ < 60) {
      step();
    }
  }

  @override
  void tick(double dt) {
    if (_flash > 0) _flash = math.max(0, _flash - dt * 1.2);
    if (_running) {
      _acc += dt;
      if (_acc > 0.6) {
        _acc = 0;
        step();
        if (_done) {
          _running = false;
          changed();
        }
      }
    }
  }

  @override
  void build(SceneBuilder b) {
    b.box(22, 0.4, 21, const Color(0xFF7E8A82), 0, -0.5, 0);
    for (var r = 0; r < 16; r++) {
      final z = (r - 7.5) * 1.15;
      final changedRow = _r[r] != _prev[r] && _flash > 0;
      for (var bit = 0; bit < 16; bit++) {
        final on = (_r[r] >> bit) & 1 == 1;
        final special = r < 4;
        final color = on
            ? (special ? SceneColors.blue : SceneColors.board)
            : (special ? const Color(0xFFBCCBE0) : const Color(0xFFCDD5CA));
        b.box(
          0.9,
          0.6,
          0.9,
          color,
          (7.5 - bit) * 1.1,
          on ? 0.35 : 0,
          z,
          id: 'bit:$r:$bit',
          glow: changedRow && on ? SceneColors.gold : null,
        );
      }
      b.label(Vec3(-9.9, 0.3, z), _names[r], r < 4 ? LabelStyle.dark : LabelStyle.small);
    }
    b.label(const Vec3(-8.25, 0.6, -10), 'بت 15', LabelStyle.small);
    b.label(const Vec3(8.25, 0.6, -10), 'بت 0', LabelStyle.small);
    for (final (f, bit) in <(String, int)>[('C', 0), ('Z', 1), ('N', 2), ('GIE', 3), ('V', 8)]) {
      b.label(Vec3((7.5 - bit) * 1.1, 0.9, (2 - 7.5) * 1.15), f, LabelStyle.smallMono);
    }
  }

  @override
  String? describe(String id) {
    if (!id.startsWith('bit:')) return null;
    final p = id.split(':');
    final r = int.parse(p[1]), bit = int.parse(p[2]);
    final on = (_r[r] >> bit) & 1;
    return '${_names[r]} · البت $bit\nقيمته $on';
  }

  @override
  void runAction(String action) {
    switch (action) {
      case 'reset':
        reset();
      case 'step':
        step();
      case 'toEnd':
        toEnd();
    }
  }

  @override
  List<LabControl> get controls => <LabControl>[
    LabButtons(<LabButton>[
      LabButton('خطوة', () {
        userDid();
        step();
      }),
      LabButton(_running ? 'إيقاف' : 'تشغيل', () {
        userDid();
        _running = !_running;
        changed();
      }, primary: false),
      LabButton('إعادة', () {
        userDid();
        reset();
      }, primary: false),
    ]),
  ];

  @override
  List<String> get values {
    String hex(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(4, '0')}';
    return <String>[
      'R4 = ${_r[4]} · R5 = ${_r[5]}',
      'نُفّذت: $_last',
      'التالية: ${_next?.text ?? '—'}',
      'PC = ${hex(_r[0])} · SP = ${hex(_r[1])} · SR = ${hex(_r[2])}',
    ];
  }
}
