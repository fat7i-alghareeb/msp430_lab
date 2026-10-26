import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../domain/entities/topic_entity.dart';
import '../labs/topic_lab.dart';

/// Plays a topic's tour: each step runs the lab's action, moves the camera
/// to its focus and shows its sentence, then waits its time.
///
/// Touching any of the lab's controls stops it ([TopicLab.onUserAction]).
/// After the last step it stops on that step; playing again starts over.
class TourController extends ChangeNotifier {
  TourController({
    required this.steps,
    required this.lab,
    required this.camera,
    required TickerProvider vsync,
  }) {
    _ticker = vsync.createTicker(_onTick);
    lab.onUserAction = pause;
  }

  final List<TourStepEntity> steps;
  final TopicLab lab;
  final OrbitCamera camera;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  int _index = -1;
  bool _playing = false;
  double _elapsed = 0;

  int get index => _index;
  bool get playing => _playing;
  bool get atEnd => _index >= steps.length - 1;
  TourStepEntity? get current =>
      _index >= 0 && _index < steps.length ? steps[_index] : null;

  /// How far the current step has run, 0 to 1.
  double get progress {
    final s = current;
    if (s == null || !_playing) return 0;
    return (_elapsed / s.seconds).clamp(0.0, 1.0);
  }

  void start() {
    _playing = true;
    goTo(0);
    _restartTicker();
  }

  void play() {
    if (_playing) return;
    if (atEnd || _index < 0) {
      start();
      return;
    }
    _playing = true;
    _elapsed = 0;
    _restartTicker();
    notifyListeners();
  }

  void pause() {
    if (!_playing) return;
    _playing = false;
    _ticker.stop();
    notifyListeners();
  }

  void toggle() => _playing ? pause() : play();

  void next() {
    pause();
    goTo(_index + 1);
  }

  void previous() {
    pause();
    goTo(_index - 1);
  }

  /// Shows step [i] and runs it.
  void goTo(int i) {
    if (steps.isEmpty) return;
    _index = i.clamp(0, steps.length - 1);
    _elapsed = 0;
    final s = steps[_index];
    final action = s.action;
    if (action != null) lab.runAction(action);
    final focus = s.focus;
    if (focus == 'home') {
      camera.goHome();
    } else if (focus != null) {
      final at = lab.focusOf(focus);
      if (at != null) camera.focus(at, closeness: lab.focusCloseness);
    }
    notifyListeners();
  }

  void _restartTicker() {
    _last = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration now) {
    final dt = _last == Duration.zero ? 0.0 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    final s = current;
    if (!_playing || s == null) return;
    _elapsed += dt;
    if (_elapsed >= s.seconds) {
      if (atEnd) {
        _playing = false;
        _ticker.stop();
        notifyListeners();
      } else {
        goTo(_index + 1);
      }
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (lab.onUserAction == pause) lab.onUserAction = null;
    super.dispose();
  }
}

/// Makes a camera for a lab.
OrbitCamera cameraFor(TopicLab lab) => OrbitCamera(lab.home);
