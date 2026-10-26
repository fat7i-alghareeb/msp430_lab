import 'dart:ui';

import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';

/// Colours the scenes share.
abstract final class SceneColors {
  static const Color board = Color(0xFF1B7350);
  static const Color floor = Color(0xFFD5DCD3);
  static const Color chip = Color(0xFF23272B);
  static const Color pin = Color(0xFFC9CED1);
  static const Color pinDim = Color(0xFF8E9693);
  static const Color pad = Color(0xFFC9A15A);
  static const Color copper = Color(0xFFB5893F);
  static const Color die = Color(0xFF4C516B);
  static const Color gold = Color(0xFFF2A900);
  static const Color goldBall = Color(0xFFF2B000);
  static const Color ledOff = Color(0xFFA8231B);
  static const Color ledOn = Color(0xFFFF3B2F);
  static const Color awake = Color(0xFF1FB85A);
  static const Color blue = Color(0xFF2D5BA8);
  static const Color green = Color(0xFF2F8A5E);
  static const Color purple = Color(0xFF6E4BAE);
  static const Color copperDark = Color(0xFFAD5C17);
  static const Color grey = Color(0xFF9AA19C);
}

/// A pin of the MSP430F149 package: its name and its group.
class PinInfo {
  const PinInfo(this.name, this.group);

  final String name;

  /// P1…P6, `clk`, `pwr` or `jtag`.
  final String group;
}

/// The F149's 64 pins, 1-based (index 0 unused). From the datasheet and the
/// book's Figure 13.1.
final List<PinInfo> f149Pins = _buildPins();

List<PinInfo> _buildPins() {
  final pins = List<PinInfo>.filled(65, const PinInfo('', ''));
  void port(int p, List<int> bits, int start) {
    for (var k = 0; k < bits.length; k++) {
      pins[start + k] = PinInfo('P$p.${bits[k]}', 'P$p');
    }
  }

  pins[1] = const PinInfo('DVcc', 'pwr');
  port(6, <int>[3, 4, 5, 6, 7], 2);
  pins[7] = const PinInfo('VREF+', 'pwr');
  pins[8] = const PinInfo('XIN', 'clk');
  pins[9] = const PinInfo('XOUT', 'clk');
  pins[10] = const PinInfo('VeREF+', 'pwr');
  pins[11] = const PinInfo('VREF−', 'pwr');
  port(1, <int>[0, 1, 2, 3, 4, 5, 6, 7], 12);
  port(2, <int>[0, 1, 2, 3, 4, 5, 6, 7], 20);
  port(3, <int>[0, 1, 2, 3, 4, 5, 6, 7], 28);
  port(4, <int>[0, 1, 2, 3, 4, 5, 6, 7], 36);
  port(5, <int>[0, 1, 2, 3, 4, 5, 6, 7], 44);
  pins[52] = const PinInfo('XT2OUT', 'clk');
  pins[53] = const PinInfo('XT2IN', 'clk');
  const jtag = <String>['TDO', 'TDI', 'TMS', 'TCK'];
  for (var k = 0; k < 4; k++) {
    pins[54 + k] = PinInfo(jtag[k], 'jtag');
  }
  pins[58] = const PinInfo('RST/NMI', 'jtag');
  port(6, <int>[0, 1, 2], 59);
  pins[62] = const PinInfo('AVss', 'pwr');
  pins[63] = const PinInfo('DVss', 'pwr');
  pins[64] = const PinInfo('AVcc', 'pwr');
  return pins;
}

const Map<String, Color> portColors = <String, Color>{
  'P1': Color(0xFF1B7350),
  'P2': Color(0xFFAD5C17),
  'P3': Color(0xFF2D5BA8),
  'P4': Color(0xFFD49A00),
  'P5': Color(0xFF6E4BAE),
  'P6': Color(0xFF1E8C93),
  'clk': Color(0xFFC2417A),
  'pwr': Color(0xFF58646E),
  'jtag': Color(0xFF14202A),
};

const Map<String, String> portNames = <String, String>{
  'P1': 'المنفذ 1 · يدعم المقاطعة',
  'P2': 'المنفذ 2 · يدعم المقاطعة',
  'P3': 'المنفذ 3',
  'P4': 'المنفذ 4',
  'P5': 'المنفذ 5',
  'P6': 'المنفذ 6 · مداخل ADC',
  'clk': 'الكريستالة',
  'pwr': 'التغذية والمرجع',
  'jtag': 'البرمجة وإعادة التشغيل',
};

/// Where pin [n] sits on a 10 × 10 package centred on the origin: 16 per
/// side, pin 1 at the top of the left side, counter-clockwise seen from
/// above. [side] is 0 left, 1 near, 2 right, 3 far.
({double x, double z, int side}) pinXZ(int n) {
  final k = (n - 1) % 16, s = (n - 1) ~/ 16, o = -3.75 + k * 0.5;
  return switch (s) {
    0 => (x: -5.5, z: o, side: 0),
    1 => (x: o, z: 5.5, side: 1),
    2 => (x: 5.5, z: -o, side: 2),
    _ => (x: -o, z: -5.5, side: 3),
  };
}

/// The tap card text for pin [n].
String pinDescription(int n) {
  final p = f149Pins[n];
  return 'الطرف $n · ${p.name}\n${portNames[p.group] ?? ''}';
}

/// Draws the MSP430F149 package: a 10 × 1.4 × 10 body and 64 pins, scaled by
/// [scale] around [at]. [pinColor] colours each pin (default silver). Pins
/// get the ids `pin:<n>`, the body `chip`.
void buildChip(
  SceneBuilder b, {
  Vec3 at = Vec3.zero,
  double scale = 1,
  bool ghost = false,
  bool marking = true,
  Color? bodyColor,
  Color? bodyGlow,
  Color Function(int pin)? pinColor,
  bool pickPins = true,
}) {
  double s(double v) => v * scale;
  b.box(
    s(10),
    s(1.4),
    s(10),
    bodyColor ?? SceneColors.chip,
    at.x,
    at.y + s(0.85),
    at.z,
    id: 'chip',
    opacity: ghost ? 0.22 : 1,
    glow: bodyGlow,
  );
  if (!ghost) {
    // The pin-1 dot.
    b.cylinder(
      s(0.35),
      s(0.04),
      const Color(0xFF14171A),
      at.x + s(-4),
      at.y + s(1.56),
      at.z + s(-4),
      segments: 12,
    );
  }
  for (var n = 1; n <= 64; n++) {
    final p = pinXZ(n);
    final hz = p.side.isEven;
    final dx = p.side == 0 ? -0.05 : (p.side == 2 ? 0.05 : 0.0);
    final dz = p.side == 1 ? 0.05 : (p.side == 3 ? -0.05 : 0.0);
    b.box(
      s(hz ? 1.1 : 0.22),
      s(0.14),
      s(hz ? 0.22 : 1.1),
      pinColor?.call(n) ?? SceneColors.pin,
      at.x + s(p.x + dx),
      at.y + s(0.25),
      at.z + s(p.z + dz),
      id: pickPins ? 'pin:$n' : null,
    );
  }
  if (marking && !ghost && scale >= 0.5) {
    b.label(
      at + Vec3(0, s(1.6), s(0.6)),
      'MSP430F149',
      scale >= 0.9 ? LabelStyle.darkMono : LabelStyle.darkMono,
    );
  }
}

/// A green board [w] × [d] whose top is at y = 0.
void buildBoard(SceneBuilder b, double w, double d, {double x = 0, double z = 0}) {
  b.box(w, 0.8, d, SceneColors.board, x, -0.4, z, id: 'board');
}

/// A light floor slab whose top is at y = 0.
void buildFloor(SceneBuilder b, double w, double d) {
  b.box(w, 0.4, d, SceneColors.floor, 0, -0.2, 0);
}

/// Copper pads under the pins of a full-size chip at the origin.
void buildPads(SceneBuilder b) {
  for (var n = 1; n <= 64; n++) {
    final p = pinXZ(n);
    final hz = p.side.isEven;
    b.box(
      hz ? 1.3 : 0.32,
      0.04,
      hz ? 0.32 : 1.3,
      SceneColors.pad,
      p.x * 1.05,
      0.02,
      p.z * 1.05,
    );
  }
}

/// The lights the scenes share: a gentle step toward [glow].
Color lerpColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;
