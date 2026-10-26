import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'vec3.dart';

/// Where the camera sits: around [target], at [radius], [theta] around the
/// vertical axis and [phi] down from straight above.
@immutable
class CameraPose {
  const CameraPose({
    required this.theta,
    required this.phi,
    required this.radius,
    this.target = Vec3.zero,
  });

  final double theta;
  final double phi;
  final double radius;
  final Vec3 target;

  CameraPose copyWith({
    double? theta,
    double? phi,
    double? radius,
    Vec3? target,
  }) => CameraPose(
    theta: theta ?? this.theta,
    phi: phi ?? this.phi,
    radius: radius ?? this.radius,
    target: target ?? this.target,
  );

  static CameraPose lerp(CameraPose a, CameraPose b, double t) => CameraPose(
    theta: a.theta + (b.theta - a.theta) * t,
    phi: a.phi + (b.phi - a.phi) * t,
    radius: a.radius + (b.radius - a.radius) * t,
    target: a.target.lerp(b.target, t),
  );
}

/// A point of the scene on the screen.
@immutable
class Projected {
  const Projected(this.offset, this.depth);

  final Offset offset;

  /// Distance along the view direction. Not positive: behind the camera.
  final double depth;

  bool get visible => depth > OrbitCamera.near;
}

/// An orbit camera: drag turns it, pinch or the wheel moves it closer, and
/// [flyTo] glides it to a new pose.
///
/// The radius is kept between [minFactor] and [maxFactor] times the home
/// pose's radius so the scene never gets lost.
class OrbitCamera extends ChangeNotifier {
  OrbitCamera(CameraPose home) : _home = home, _pose = home;

  static const double near = 0.1;
  static const double fov = 40 * math.pi / 180;
  static const double minFactor = 0.35;
  static const double maxFactor = 2.4;

  CameraPose _home;
  CameraPose _pose;

  CameraPose? _flyFrom;
  CameraPose? _flyTo;
  double _flyT = 0;

  /// Scales the home radius for the view's shape: a tall, narrow view needs
  /// the camera further back to keep the scene inside it.
  double fitFactor = 1;

  CameraPose get pose => _pose;
  CameraPose get home => _home;

  bool get isFlying => _flyTo != null;

  /// Sets [fitFactor] for a view of a new shape, keeping the current
  /// distance in proportion. Does not notify: called during layout.
  void applyFit(double factor) {
    if (factor == fitFactor) return;
    _pose = _pose.copyWith(radius: _pose.radius / fitFactor * factor);
    fitFactor = factor;
  }

  /// Replaces the home pose and jumps to it.
  void reset(CameraPose home) {
    _home = home;
    _pose = home.copyWith(radius: home.radius * fitFactor);
    _flyTo = null;
    notifyListeners();
  }

  /// Glides back to the home pose.
  void goHome() => flyTo(_home.copyWith(radius: _home.radius * fitFactor));

  /// Glides to [target], closer by [closeness] of the home distance.
  void focus(Vec3 target, {double closeness = 0.62}) {
    flyTo(
      _pose.copyWith(
        target: target,
        phi: math.min(_pose.phi, 0.95),
        radius: _home.radius * fitFactor * closeness,
      ),
    );
  }

  void flyTo(CameraPose to) {
    _flyFrom = _pose;
    _flyTo = to;
    _flyT = 0;
    notifyListeners();
  }

  void rotate(double dTheta, double dPhi) {
    _flyTo = null;
    _pose = _pose.copyWith(
      theta: _pose.theta + dTheta,
      phi: (_pose.phi + dPhi).clamp(0.12, 1.5),
    );
    notifyListeners();
  }

  void zoom(double factor) {
    _flyTo = null;
    final base = _home.radius * fitFactor;
    _pose = _pose.copyWith(
      radius: (_pose.radius * factor).clamp(base * minFactor, base * maxFactor),
    );
    notifyListeners();
  }

  /// Advances a flight. Returns true while one is running.
  bool tick(double dt) {
    final to = _flyTo;
    final from = _flyFrom;
    if (to == null || from == null) return false;
    _flyT = math.min(1, _flyT + dt / 0.8);
    final eased = 1 - math.pow(1 - _flyT, 3).toDouble();
    _pose = CameraPose.lerp(from, to, eased);
    if (_flyT >= 1) _flyTo = null;
    notifyListeners();
    return true;
  }

  // ── projection

  late Vec3 _eye;
  late Vec3 _right;
  late Vec3 _up;
  late Vec3 _forward;
  late double _focal;
  late Offset _center;

  Vec3 get eye => _eye;

  /// Prepares [project] for a frame of [size].
  void begin(Size size) {
    final p = _pose;
    _eye =
        p.target +
        Vec3(
          p.radius * math.sin(p.phi) * math.sin(p.theta),
          p.radius * math.cos(p.phi),
          p.radius * math.sin(p.phi) * math.cos(p.theta),
        );
    _forward = (p.target - _eye).normalized;
    _right = _forward.cross(Vec3.unitY).normalized;
    _up = _right.cross(_forward);
    _focal = (size.height / 2) / math.tan(fov / 2);
    _center = Offset(size.width / 2, size.height / 2);
  }

  Projected project(Vec3 point) {
    final d = point - _eye;
    final z = d.dot(_forward);
    if (z <= near) return Projected(Offset.zero, z);
    final x = d.dot(_right);
    final y = d.dot(_up);
    return Projected(
      Offset(_center.dx + x * _focal / z, _center.dy - y * _focal / z),
      z,
    );
  }

  /// The on-screen size of [worldSize] at [depth].
  double scaleAt(double depth) => depth <= near ? 0 : _focal / depth;
}
