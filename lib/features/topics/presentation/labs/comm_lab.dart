import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

class _Slot {
  const _Slot(this.wire, this.bit, this.label, {this.clock, this.back = false});

  final String wire;
  final int bit;
  final String label;
  final String? clock;

  /// Sent by the other device (an ACK).
  final bool back;
}

/// 3.3 · A byte sent bit by bit on UART, SPI or I2C wires.
class CommLab extends TopicLab {
  CommLab() {
    _reset();
  }

  static const Color _one = Color(0xFFF2A900);
  static const Color _zero = Color(0xFF8C9AA3);
  static const Color _clock = Color(0xFF7CC7F0);

  final Movers _movers = Movers();
  String _proto = 'uart';
  String _char = 'A';
  List<_Slot> _slots = const <_Slot>[];
  int _i = 0;
  double _acc = 0;
  double _speed = 1.4;
  final Map<String, Path3> _wires = <String, Path3>{};

  @override
  CameraPose get home => const CameraPose(theta: 0, phi: 0.95, radius: 34);

  int get _code => _char.isEmpty ? 0x41 : _char.codeUnitAt(0) & 0xFF;

  List<String> get _wireNames => switch (_proto) {
    'uart' => const <String>['TX', 'RX'],
    'spi' => const <String>['SCLK', 'MOSI', 'MISO', 'CS'],
    _ => const <String>['SCL', 'SDA'],
  };

  List<_Slot> _frame() {
    final c = _code;
    final out = <_Slot>[];
    switch (_proto) {
      case 'uart':
        out.add(const _Slot('TX', 0, 'Start'));
        for (var i = 0; i < 8; i++) {
          out.add(_Slot('TX', (c >> i) & 1, 'D$i'));
        }
        out.add(const _Slot('TX', 1, 'Stop'));
      case 'spi':
        for (var i = 7; i >= 0; i--) {
          out.add(_Slot('MOSI', (c >> i) & 1, 'D$i', clock: 'SCLK'));
        }
      default:
        out.add(const _Slot('SDA', 0, 'S'));
        for (var i = 6; i >= 0; i--) {
          out.add(_Slot('SDA', (0x48 >> i) & 1, 'A$i', clock: 'SCL'));
        }
        out
          ..add(const _Slot('SDA', 0, 'W', clock: 'SCL'))
          ..add(const _Slot('SDA', 0, 'ACK', clock: 'SCL', back: true));
        for (var i = 7; i >= 0; i--) {
          out.add(_Slot('SDA', (c >> i) & 1, 'D$i', clock: 'SCL'));
        }
        out
          ..add(const _Slot('SDA', 0, 'ACK', clock: 'SCL', back: true))
          ..add(const _Slot('SDA', 1, 'P'));
    }
    return out;
  }

  void _reset() {
    _movers.clear();
    _slots = _frame();
    _i = 0;
    _acc = 0;
    _wires.clear();
    final names = _wireNames;
    for (var k = 0; k < names.length; k++) {
      final z = (k - (names.length - 1) / 2) * 2.6;
      _wires[names[k]] = Path3(<Vec3>[Vec3(-8.4, 0.5, z), Vec3(8.4, 0.5, z)]);
    }
    changed();
  }

  @override
  void tick(double dt) {
    _movers.tick(dt);
    _acc += dt * _speed;
    if (_acc < 1) return;
    _acc = 0;
    if (_i < _slots.length) {
      final s = _slots[_i];
      final wire = _wires[s.wire]!;
      _movers.go(s.back ? wire.reversed() : wire,
          seconds: 1.6, color: s.bit == 1 ? _one : _zero, radius: 0.42, glow: s.bit == 1);
      if (s.clock != null) {
        _movers.go(_wires[s.clock]!, seconds: 1.6, color: _clock, radius: 0.3);
      }
    }
    _i++;
    if (_i > _slots.length + 2) _i = 0;
    changed();
  }

  @override
  void build(SceneBuilder b) {
    buildFloor(b, 34, 20);
    buildChip(b, at: const Vec3(-11, 0, 0), scale: 0.5, pickPins: false);
    b.box(5, 1, 5, const Color(0xFF3A4A5A), 11, 0.6, 0, id: 'other');
    b.label(const Vec3(-11, 2, 0), 'MSP430');
    b.label(const Vec3(11, 2, 0), 'جهاز آخر');
    _wires.forEach((name, path) {
      b.tube(path.points, 0.14, const Color(0xFF9AA19C));
      b.label(Vec3(0, 0.9, path.points.first.z - 0.9), name, LabelStyle.smallMono);
    });
    _movers.build(b);
  }

  @override
  String? describe(String id) => switch (id) {
    'other' => 'جهاز آخر\nحساس أو شريحة ثانية',
    'chip' => 'MSP430F149\nفيه USART0 و USART1',
    _ => null,
  };

  @override
  void runAction(String action) {
    if (action.startsWith('proto:')) {
      _proto = action.substring(6);
      _char = 'A';
      _reset();
    }
  }

  String _hex(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(2, '0')}';

  @override
  List<LabControl> get controls => <LabControl>[
    LabChoice(
      options: const <(String, String)>[('uart', 'UART'), ('spi', 'SPI'), ('i2c', 'I2C')],
      value: _proto,
      onChanged: (v) {
        userDid();
        _proto = v;
        _reset();
      },
    ),
    LabCharField(
      value: _char,
      onChanged: (v) {
        userDid();
        _char = v.isEmpty ? 'A' : v.characters1;
        _reset();
      },
    ),
    LabButtons(<LabButton>[
      LabButton(_speed > 1 ? 'أبطأ' : 'أسرع', () {
        userDid();
        _speed = _speed > 1 ? 0.6 : 1.4;
        changed();
      }, primary: false),
    ]),
    LabBits(bits: <String>[for (final s in _slots) s.label], current: _i),
  ];

  @override
  List<String> get values => <String>[
    '${_proto.toUpperCase()} · \'$_char\' = ${_hex(_code)} = ${_code.toRadixString(2).padLeft(8, '0')}',
    switch (_proto) {
      'uart' => 'بت بداية، 8 بتات من الأصغر أولاً، بت توقف. سلكان.',
      'spi' => 'سلك ساعة وسلك بيانات، من الأكبر أولاً.',
      _ => 'سلكان: العنوان 0x48 ثم البيانات، مع إقرار ACK.',
    },
  ];
}

extension on String {
  /// The first character only.
  String get characters1 => isEmpty ? this : String.fromCharCode(codeUnitAt(0));
}
