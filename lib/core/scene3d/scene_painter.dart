import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'orbit_camera.dart';
import 'scene_builder.dart';
import 'vec3.dart';

/// Light comes from above, a little to the front and right.
final Vec3 _light = const Vec3(0.4, 0.9, 0.55).normalized;

enum SceneItemKind { polygon, disc, segment }

/// One thing to draw, already projected: a face, a ball or a piece of wire.
class _Item {
  _Item.polygon(this.points, this.depth, this.color, this.id, this.glow)
    : kind = SceneItemKind.polygon,
      center = Offset.zero,
      radius = 0,
      width = 0;

  _Item.disc(this.center, this.radius, this.depth, this.color, this.id, this.glow)
    : kind = SceneItemKind.disc,
      points = const <Offset>[],
      width = 0;

  _Item.segment(
    this.points,
    this.width,
    this.depth,
    this.color,
    this.id,
    this.glow,
  ) : kind = SceneItemKind.segment,
      center = Offset.zero,
      radius = 0;

  final SceneItemKind kind;
  final List<Offset> points;
  final Offset center;
  final double radius;
  final double width;
  final double depth;
  final Color color;
  final String? id;
  final Color? glow;
}

/// Lights, sorts and draws one frame of a [SceneBuilder], and remembers what
/// it drew so a tap can be traced back to a part ([hitTest]).
///
/// Painter's algorithm: every face is drawn back to front. Faces turned away
/// from the camera are skipped. Enough for the small, mostly boxy scenes of
/// this app, and it runs the same on every platform with no GPU plugin.
class ScenePainter extends CustomPainter {
  ScenePainter({
    required this.scene,
    required this.camera,
    required this.background,
    required this.items,
    super.repaint,
  });

  final SceneBuilder scene;
  final OrbitCamera camera;
  final Color background;

  /// Filled during [paint]; read by [hitTest] in the widget.
  final List<SceneHitItem> items;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    camera.begin(size);
    final eye = camera.eye;
    final list = <_Item>[];

    for (final b in scene.boxes) {
      _addBox(list, b, eye);
    }
    for (final c in scene.cylinders) {
      _addCylinder(list, c, eye);
    }
    for (final s in scene.spheres) {
      final p = camera.project(s.center);
      if (!p.visible) continue;
      final r = s.radius * camera.scaleAt(p.depth);
      list.add(_Item.disc(p.offset, r, p.depth, s.color, s.id, s.glow));
    }
    for (final t in scene.tubes) {
      for (var i = 0; i < t.points.length - 1; i++) {
        final a = camera.project(t.points[i]);
        final b = camera.project(t.points[i + 1]);
        if (!a.visible || !b.visible) continue;
        final depth = (a.depth + b.depth) / 2;
        final w = math.max(1.5, 2 * t.radius * camera.scaleAt(depth));
        list.add(
          _Item.segment(
            <Offset>[a.offset, b.offset],
            w,
            depth,
            t.color,
            t.id,
            t.glow,
          ),
        );
      }
    }

    list.sort((a, b) => b.depth.compareTo(a.depth));
    items.clear();

    final fill = Paint()..isAntiAlias = true;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..isAntiAlias = true;

    for (final it in list) {
      switch (it.kind) {
        case SceneItemKind.polygon:
          final path = Path()..addPolygon(it.points, true);
          if (it.glow != null) {
            canvas.drawPath(
              path,
              Paint()
                ..color = it.glow!.withValues(alpha: 0.55)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
            );
          }
          fill.color = it.color;
          canvas.drawPath(path, fill);
          // A hairline of the same colour closes the gaps between faces.
          edge.color = it.color;
          canvas.drawPath(path, edge);
          items.add(SceneHitItem.polygon(it.points, it.id));
        case SceneItemKind.disc:
          if (it.glow != null) {
            canvas.drawCircle(
              it.center,
              it.radius * 1.6,
              Paint()
                ..color = it.glow!.withValues(alpha: 0.45)
                ..maskFilter = MaskFilter.blur(
                  BlurStyle.normal,
                  math.max(2, it.radius * 0.6),
                ),
            );
          }
          final shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 1.0,
            colors: <Color>[
              Color.lerp(it.color, const Color(0xFFFFFFFF), 0.55)!,
              it.color,
              Color.lerp(it.color, const Color(0xFF000000), 0.35)!,
            ],
            stops: const <double>[0, 0.55, 1],
          ).createShader(Rect.fromCircle(center: it.center, radius: it.radius));
          canvas.drawCircle(it.center, it.radius, Paint()..shader = shader);
          items.add(SceneHitItem.disc(it.center, it.radius, it.id));
        case SceneItemKind.segment:
          if (it.glow != null) {
            canvas.drawLine(
              it.points[0],
              it.points[1],
              Paint()
                ..color = it.glow!.withValues(alpha: 0.5)
                ..strokeWidth = it.width * 2.2
                ..strokeCap = StrokeCap.round
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
            );
          }
          canvas.drawLine(
            it.points[0],
            it.points[1],
            Paint()
              ..color = it.color
              ..strokeWidth = it.width
              ..strokeCap = StrokeCap.round
              ..isAntiAlias = true,
          );
          items.add(SceneHitItem.segment(it.points, it.width, it.id));
      }
    }
  }

  void _addFace(
    List<_Item> list,
    List<Vec3> corners,
    Vec3 normal,
    Color base,
    double opacity,
    Vec3 eye,
    String? id,
    Color? glow, {
    bool cull = true,
  }) {
    var center = Vec3.zero;
    for (final c in corners) {
      center = center + c;
    }
    center = center * (1 / corners.length);
    if (cull && normal.dot(eye - center) <= 0) return;
    final pts = <Offset>[];
    var depth = 0.0;
    for (final c in corners) {
      final p = camera.project(c);
      if (!p.visible) return;
      pts.add(p.offset);
      depth += p.depth;
    }
    depth /= corners.length;
    final lit = 0.62 + 0.38 * math.max(0, normal.dot(_light));
    var color = Color.lerp(const Color(0xFF000000), base, lit)!;
    if (glow != null) color = Color.lerp(color, glow, 0.55)!;
    if (opacity < 1) color = color.withValues(alpha: opacity);
    list.add(_Item.polygon(pts, depth, color, id, glow));
  }

  void _addBox(List<_Item> list, BoxPrim b, Vec3 eye) {
    final ax = b.ax * b.half.x, ay = b.ay * b.half.y, az = b.az * b.half.z;
    final c = b.center;
    Vec3 p(int sx, int sy, int sz) =>
        c + ax * sx.toDouble() + ay * sy.toDouble() + az * sz.toDouble();
    final faces = <(List<Vec3>, Vec3)>[
      ([p(1, -1, -1), p(1, 1, -1), p(1, 1, 1), p(1, -1, 1)], b.ax),
      ([p(-1, -1, 1), p(-1, 1, 1), p(-1, 1, -1), p(-1, -1, -1)], -b.ax),
      ([p(-1, 1, -1), p(-1, 1, 1), p(1, 1, 1), p(1, 1, -1)], b.ay),
      ([p(-1, -1, 1), p(-1, -1, -1), p(1, -1, -1), p(1, -1, 1)], -b.ay),
      ([p(-1, -1, 1), p(1, -1, 1), p(1, 1, 1), p(-1, 1, 1)], b.az),
      ([p(1, -1, -1), p(-1, -1, -1), p(-1, 1, -1), p(1, 1, -1)], -b.az),
    ];
    for (final (corners, n) in faces) {
      _addFace(list, corners, n, b.color, b.opacity, eye, b.id, b.glow);
    }
  }

  void _addCylinder(List<_Item> list, CylinderPrim c, Vec3 eye) {
    final a = c.axis.normalized;
    final helper = a.y.abs() > 0.9 ? Vec3.unitX : Vec3.unitY;
    final u = a.cross(helper).normalized;
    final w = a.cross(u).normalized;
    final half = a * (c.height / 2);
    final top = <Vec3>[];
    final bottom = <Vec3>[];
    for (var i = 0; i < c.segments; i++) {
      final ang = i / c.segments * 2 * math.pi;
      final r = u * (math.cos(ang) * c.radius) + w * (math.sin(ang) * c.radius);
      top.add(c.center + half + r);
      bottom.add(c.center - half + r);
    }
    for (var i = 0; i < c.segments; i++) {
      final j = (i + 1) % c.segments;
      final mid = (top[i] + top[j]) * 0.5 - (c.center + half);
      _addFace(
        list,
        <Vec3>[bottom[i], bottom[j], top[j], top[i]],
        mid.normalized,
        c.color,
        1,
        eye,
        c.id,
        c.glow,
      );
    }
    _addFace(list, top.reversed.toList(), a, c.color, 1, eye, c.id, c.glow);
    _addFace(list, bottom, -a, c.color, 1, eye, c.id, c.glow);
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) => true;
}

/// What was drawn where, for tapping. Kept front-most last.
class SceneHitItem {
  SceneHitItem.polygon(this.points, this.id)
    : kind = SceneItemKind.polygon,
      center = Offset.zero,
      radius = 0;
  SceneHitItem.disc(this.center, this.radius, this.id)
    : kind = SceneItemKind.disc,
      points = const <Offset>[];
  SceneHitItem.segment(this.points, double width, this.id)
    : kind = SceneItemKind.segment,
      center = Offset.zero,
      radius = width / 2 + 4;

  final SceneItemKind kind;
  final List<Offset> points;
  final Offset center;
  final double radius;
  final String? id;

  bool contains(Offset p) {
    switch (kind) {
      case SceneItemKind.disc:
        return (p - center).distance <= radius;
      case SceneItemKind.segment:
        return _distToSegment(p, points[0], points[1]) <= radius;
      case SceneItemKind.polygon:
        var inside = false;
        for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
          final a = points[i], b = points[j];
          if ((a.dy > p.dy) != (b.dy > p.dy) &&
              p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
            inside = !inside;
          }
        }
        return inside;
    }
  }

  static double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }
}

/// The front-most part under [point] in the last frame, or null.
String? hitTestScene(List<SceneHitItem> items, Offset point) {
  for (var i = items.length - 1; i >= 0; i--) {
    final it = items[i];
    if (it.contains(point)) return it.id;
  }
  return null;
}

/// A fresh list for [ScenePainter.items].
List<SceneHitItem> newHitList() => <SceneHitItem>[];
