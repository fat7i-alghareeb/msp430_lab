import 'dart:math' as math;
import 'dart:ui';

import 'vec3.dart';

/// How a scene label looks.
enum LabelStyle { normal, small, dark, hot, mono, smallMono, darkMono }

/// A box: a center, half sizes along its three axes, and those axes.
class BoxPrim {
  BoxPrim({
    required this.center,
    required this.half,
    required this.color,
    this.ax = Vec3.unitX,
    this.ay = Vec3.unitY,
    this.az = Vec3.unitZ,
    this.id,
    this.glow,
    this.opacity = 1,
  });

  final Vec3 center;
  final Vec3 half;
  final Color color;
  final Vec3 ax;
  final Vec3 ay;
  final Vec3 az;
  final String? id;
  final Color? glow;
  final double opacity;
}

/// A cylinder along [axis], centred on [center].
class CylinderPrim {
  CylinderPrim({
    required this.center,
    required this.axis,
    required this.radius,
    required this.height,
    required this.color,
    this.segments = 18,
    this.id,
    this.glow,
  });

  final Vec3 center;
  final Vec3 axis;
  final double radius;
  final double height;
  final Color color;
  final int segments;
  final String? id;
  final Color? glow;
}

/// A shaded ball, drawn as a lit disc facing the camera.
class SpherePrim {
  SpherePrim({
    required this.center,
    required this.radius,
    required this.color,
    this.id,
    this.glow,
  });

  final Vec3 center;
  final double radius;
  final Color color;
  final String? id;
  final Color? glow;
}

/// A round wire through [points].
class TubePrim {
  TubePrim({
    required this.points,
    required this.radius,
    required this.color,
    this.id,
    this.glow,
  });

  final List<Vec3> points;
  final double radius;
  final Color color;
  final String? id;
  final Color? glow;
}

/// Text that follows a point of the scene.
class LabelPrim {
  LabelPrim({required this.at, required this.text, this.style = LabelStyle.normal});

  final Vec3 at;
  final String text;
  final LabelStyle style;
}

/// A round numbered button pinned to a point of the scene.
class HotspotPrim {
  HotspotPrim({
    required this.at,
    required this.text,
    required this.color,
    required this.id,
    this.tooltip,
  });

  final Vec3 at;
  final String text;
  final Color color;
  final String id;
  final String? tooltip;
}

/// What a scene draws in one frame — filled again every frame.
///
/// Scenes are immediate-mode: a lab adds its parts here from its current
/// state, and the painter lights, sorts and draws them.
class SceneBuilder {
  final List<BoxPrim> boxes = <BoxPrim>[];
  final List<CylinderPrim> cylinders = <CylinderPrim>[];
  final List<SpherePrim> spheres = <SpherePrim>[];
  final List<TubePrim> tubes = <TubePrim>[];
  final List<LabelPrim> labels = <LabelPrim>[];
  final List<HotspotPrim> hotspots = <HotspotPrim>[];

  void clear() {
    boxes.clear();
    cylinders.clear();
    spheres.clear();
    tubes.clear();
    labels.clear();
    hotspots.clear();
  }

  /// An axis-aligned box of full size [w] × [h] × [d] centred on (x, y, z).
  void box(
    double w,
    double h,
    double d,
    Color color,
    double x,
    double y,
    double z, {
    String? id,
    Color? glow,
    double opacity = 1,
  }) {
    boxes.add(
      BoxPrim(
        center: Vec3(x, y, z),
        half: Vec3(w / 2, h / 2, d / 2),
        color: color,
        id: id,
        glow: glow,
        opacity: opacity,
      ),
    );
  }

  /// A box turned by [angle] around the X axis through (x, y, z).
  void boxRotX(
    double w,
    double h,
    double d,
    Color color,
    double x,
    double y,
    double z,
    double angle, {
    Vec3 offset = Vec3.zero,
    String? id,
  }) {
    final c = Vec3(x, y, z) + offset.rotX(angle);
    boxes.add(
      BoxPrim(
        center: c,
        half: Vec3(w / 2, h / 2, d / 2),
        color: color,
        ay: Vec3.unitY.rotX(angle),
        az: Vec3.unitZ.rotX(angle),
        id: id,
      ),
    );
  }

  void cylinder(
    double radius,
    double height,
    Color color,
    double x,
    double y,
    double z, {
    Vec3 axis = Vec3.unitY,
    String? id,
    Color? glow,
    int segments = 18,
  }) {
    cylinders.add(
      CylinderPrim(
        center: Vec3(x, y, z),
        axis: axis,
        radius: radius,
        height: height,
        color: color,
        id: id,
        glow: glow,
        segments: segments,
      ),
    );
  }

  void sphere(
    double radius,
    Color color,
    Vec3 at, {
    String? id,
    Color? glow,
  }) {
    spheres.add(
      SpherePrim(center: at, radius: radius, color: color, id: id, glow: glow),
    );
  }

  void tube(
    List<Vec3> points,
    double radius,
    Color color, {
    String? id,
    Color? glow,
  }) {
    tubes.add(
      TubePrim(points: points, radius: radius, color: color, id: id, glow: glow),
    );
  }

  void label(Vec3 at, String text, [LabelStyle style = LabelStyle.normal]) {
    labels.add(LabelPrim(at: at, text: text, style: style));
  }

  void hotspot(
    Vec3 at,
    String text,
    Color color,
    String id, {
    String? tooltip,
  }) {
    hotspots.add(
      HotspotPrim(at: at, text: text, color: color, id: id, tooltip: tooltip),
    );
  }
}

/// A path through the scene, walked by length so a ball moves at an even
/// speed along it.
class Path3 {
  Path3(this.points) : assert(points.length >= 2) {
    var total = 0.0;
    _cumulative.add(0);
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).length;
      _cumulative.add(total);
    }
    length = total;
  }

  /// A curved hop from [a] to [b], [lift] above the straight line.
  factory Path3.arc(Vec3 a, Vec3 b, {double lift = 2.5, int steps = 24}) {
    final mid = a.lerp(b, 0.5) + Vec3(0, lift, 0);
    return Path3(<Vec3>[
      for (var i = 0; i <= steps; i++) _quad(a, mid, b, i / steps),
    ]);
  }

  static Vec3 _quad(Vec3 a, Vec3 m, Vec3 b, double t) {
    final u = 1 - t;
    return a * (u * u) + m * (2 * u * t) + b * (t * t);
  }

  final List<Vec3> points;
  final List<double> _cumulative = <double>[];
  late final double length;

  /// The point [t] of the way along, 0 to 1.
  Vec3 at(double t) {
    if (length == 0) return points.first;
    final target = t.clamp(0.0, 1.0) * length;
    for (var i = 1; i < points.length; i++) {
      if (_cumulative[i] >= target) {
        final seg = _cumulative[i] - _cumulative[i - 1];
        final f = seg == 0 ? 0.0 : (target - _cumulative[i - 1]) / seg;
        return points[i - 1].lerp(points[i], f);
      }
    }
    return points.last;
  }

  Path3 reversed() => Path3(points.reversed.toList());
}

/// Balls that travel along paths and call back when they arrive.
class Movers {
  final List<_Mover> _list = <_Mover>[];

  bool get isEmpty => _list.isEmpty;

  void go(
    Path3 path, {
    required double seconds,
    required Color color,
    double radius = 0.45,
    bool glow = true,
    void Function()? onDone,
  }) {
    _list.add(_Mover(path, seconds, color, radius, glow, onDone));
  }

  void clear() => _list.clear();

  /// The position of the newest ball, if any.
  Vec3? get lead => _list.isEmpty ? null : _list.last.position;

  void tick(double dt) {
    for (var i = _list.length - 1; i >= 0; i--) {
      final m = _list[i];
      m.t += dt / m.seconds;
      if (m.t >= 1) {
        _list.removeAt(i);
        m.onDone?.call();
      }
    }
  }

  void build(SceneBuilder b) {
    for (final m in _list) {
      b.sphere(m.radius, m.color, m.position, glow: m.glow ? m.color : null);
    }
  }
}

class _Mover {
  _Mover(
    this.path,
    this.seconds,
    this.color,
    this.radius,
    this.glow,
    this.onDone,
  );

  final Path3 path;
  final double seconds;
  final Color color;
  final double radius;
  final bool glow;
  final void Function()? onDone;
  double t = 0;

  Vec3 get position => path.at(math.min(1, t));
}
