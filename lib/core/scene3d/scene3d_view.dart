import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'orbit_camera.dart';
import 'scene_builder.dart';
import 'scene_painter.dart';

/// Something that can be shown in a [Scene3DView]: it draws itself from its
/// own state every frame and answers taps on its parts.
abstract class SceneSource {
  /// Where the camera starts.
  CameraPose get home;

  /// Adds this frame's parts to [b].
  void build(SceneBuilder b);

  /// Advances animations by [dt] seconds.
  void tick(double dt) {}

  /// The name and a line about part [id], for the tap card. Null: nothing.
  String? describe(String id) => null;

  /// Part [id] was tapped.
  void onTap(String id) {}

  /// A finger or the mouse went down on part [id]. Return true to hold it
  /// (a push button): the drag does not turn the camera then.
  bool onPress(String id) => false;

  /// The held press ended.
  void onRelease() {}
}

/// A 3D scene the reader can turn (drag), zoom (pinch or wheel) and tap.
///
/// The parts' names float over the scene as Flutter widgets, so they stay
/// sharp and follow the language direction.
class Scene3DView extends StatefulWidget {
  const Scene3DView({
    super.key,
    required this.source,
    required this.camera,
    this.background = const Color(0xFFEEF2EE),
    this.onHotspot,
    this.tipAlignment = AlignmentDirectional.topEnd,
    this.tipPadding = const EdgeInsets.all(10),
    this.paused = false,
  });

  final SceneSource source;
  final OrbitCamera camera;
  final Color background;

  /// A numbered hotspot was tapped.
  final ValueChanged<String>? onHotspot;

  /// Where the tap card appears.
  final AlignmentDirectional tipAlignment;
  final EdgeInsets tipPadding;

  /// Stops the clock (a page covering this one).
  final bool paused;

  @override
  State<Scene3DView> createState() => _Scene3DViewState();
}

class _Scene3DViewState extends State<Scene3DView>
    with SingleTickerProviderStateMixin {
  final SceneBuilder _scene = SceneBuilder();
  final List<SceneHitItem> _hits = <SceneHitItem>[];
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;

  final Map<int, Offset> _pointers = <int, Offset>{};
  Offset? _downAt;
  bool _moved = false;
  bool _held = false;
  double? _pinchStart;
  Size _size = Size.zero;

  String? _tip;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.paused) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant Scene3DView old) {
    super.didUpdateWidget(old);
    if (widget.paused && _ticker.isActive) _ticker.stop();
    if (!widget.paused && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : math.min(0.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    widget.source.tick(dt);
    widget.camera.tick(dt);
    _scene.clear();
    widget.source.build(_scene);
    _frame.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tipTimer?.cancel();
    _frame.dispose();
    super.dispose();
  }

  void _showTip(String? text) {
    if (text == null) return;
    _tipTimer?.cancel();
    setState(() => _tip = text);
    _tipTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _tip = null);
    });
  }

  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1) {
      _downAt = e.localPosition;
      _moved = false;
      final id = hitTestScene(_hits, e.localPosition);
      _held = id != null && widget.source.onPress(id);
    } else if (_pointers.length == 2) {
      final pts = _pointers.values.toList();
      _pinchStart = (pts[0] - pts[1]).distance;
      _held = false;
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    final prev = _pointers[e.pointer]!;
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 2 && _pinchStart != null) {
      final pts = _pointers.values.toList();
      final d = (pts[0] - pts[1]).distance;
      if (d > 10) widget.camera.zoom(_pinchStart! / d);
      _pinchStart = d;
      _moved = true;
      return;
    }
    if (_held) return;
    if (_downAt != null && (e.localPosition - _downAt!).distance > 5) {
      _moved = true;
    }
    if (_moved) {
      final delta = e.localPosition - prev;
      widget.camera.rotate(-delta.dx * 0.008, -delta.dy * 0.006);
    }
  }

  void _onUp(PointerEvent e) {
    final wasSingle = _pointers.length == 1;
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) _pinchStart = null;
    if (_held) {
      widget.source.onRelease();
      _held = false;
    }
    if (wasSingle && !_moved && e is PointerUpEvent) {
      final id = hitTestScene(_hits, e.localPosition);
      if (id != null) {
        _showTip(widget.source.describe(id));
        widget.source.onTap(id);
      }
    }
  }

  void _onSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      widget.camera.zoom(math.pow(1.0015, e.scrollDelta.dy).toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _size && size.width > 0 && size.height > 0) {
          _size = size;
          // A tall, narrow view moves the camera back to keep it all in.
          final aspect = size.width / size.height;
          widget.camera.applyFit((1.45 / aspect).clamp(1.0, 1.6));
        }
        return ClipRect(
          child: Listener(
            onPointerDown: _onDown,
            onPointerMove: _onMove,
            onPointerUp: _onUp,
            onPointerCancel: _onUp,
            onPointerSignal: _onSignal,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                RepaintBoundary(
                  child: CustomPaint(
                    painter: ScenePainter(
                      scene: _scene,
                      camera: widget.camera,
                      background: widget.background,
                      items: _hits,
                      repaint: _frame,
                    ),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _frame,
                  builder: (context, _, _) => _Overlay(
                    scene: _scene,
                    camera: widget.camera,
                    size: size,
                    onHotspot: widget.onHotspot,
                  ),
                ),
                Padding(
                  padding: widget.tipPadding,
                  child: Align(
                    alignment: widget.tipAlignment,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _tip == null ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: _tip == null ? null : _TipCard(text: _tip!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.scene,
    required this.camera,
    required this.size,
    this.onHotspot,
  });

  final SceneBuilder scene;
  final OrbitCamera camera;
  final Size size;
  final ValueChanged<String>? onHotspot;

  @override
  Widget build(BuildContext context) {
    if (size.isEmpty) return const SizedBox.shrink();
    camera.begin(size);
    final children = <Widget>[];
    for (final l in scene.labels) {
      final p = camera.project(l.at);
      if (!_onScreen(p)) continue;
      children.add(
        Positioned(
          left: p.offset.dx,
          top: p.offset.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -1.15),
            child: IgnorePointer(child: SceneLabel(l.text, style: l.style)),
          ),
        ),
      );
    }
    for (final h in scene.hotspots) {
      final p = camera.project(h.at);
      if (!_onScreen(p)) continue;
      children.add(
        Positioned(
          left: p.offset.dx,
          top: p.offset.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: _Hotspot(
              hotspot: h,
              onTap: onHotspot == null ? null : () => onHotspot!(h.id),
            ),
          ),
        ),
      );
    }
    return Stack(children: children);
  }

  bool _onScreen(Projected p) =>
      p.visible &&
      p.offset.dx > -40 &&
      p.offset.dy > -40 &&
      p.offset.dx < size.width + 40 &&
      p.offset.dy < size.height + 40;
}

const List<String> _monoFallback = <String>['Menlo', 'Roboto Mono', 'monospace', 'Courier New'];

/// A name floating over the scene.
class SceneLabel extends StatelessWidget {
  const SceneLabel(this.text, {super.key, this.style = LabelStyle.normal});

  final String text;
  final LabelStyle style;

  @override
  Widget build(BuildContext context) {
    final small =
        style == LabelStyle.small ||
        style == LabelStyle.smallMono ||
        style == LabelStyle.darkMono;
    final dark = style == LabelStyle.dark || style == LabelStyle.darkMono;
    final hot = style == LabelStyle.hot;
    final mono =
        style == LabelStyle.mono ||
        style == LabelStyle.smallMono ||
        style == LabelStyle.darkMono;
    final bg = hot
        ? const Color(0xFFF2B000)
        : dark
        ? const Color(0xD8131C24)
        : const Color(0xEEFFFFFF);
    final fg = dark ? Colors.white : const Color(0xFF131C24);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        textDirection: mono ? TextDirection.ltr : null,
        style: TextStyle(
          fontSize: small ? 10.5 : 12,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.3,
          fontFamily: mono ? 'Consolas' : null,
          fontFamilyFallback: mono ? _monoFallback : null,
        ),
      ),
    );
  }
}

class _Hotspot extends StatelessWidget {
  const _Hotspot({required this.hotspot, this.onTap});

  final HotspotPrim hotspot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hotspot.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        hotspot.text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: dot),
    );
    return hotspot.tooltip == null
        ? button
        : Tooltip(message: hotspot.tooltip!, child: button);
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCE2DD)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                lines.first,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              for (final l in lines.skip(1))
                Text(
                  l,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A6670)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
