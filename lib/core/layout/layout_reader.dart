import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';

import 'app_layout.dart';

/// The current [AppLayout] for code that has no `BuildContext` — a bloc
/// choosing a page size, a service picking image widths.
///
/// Read-only: `AppLayoutHost` writes it from every frame, so it never holds
/// a guessed value. Before the first frame [current] is null.
///
/// [changes] fires AFTER the frame that changed the layout: a listener that
/// emits state must not mark widgets dirty in the middle of a build.
@lazySingleton
class LayoutReader {
  AppLayout? _current;
  final ValueNotifier<AppLayout?> _changes = ValueNotifier<AppLayout?>(null);
  bool _notifyScheduled = false;

  AppLayout? get current => _current;

  ValueListenable<AppLayout?> get changes => _changes;

  /// Called by `AppLayoutHost` only.
  void update(AppLayout layout) {
    if (layout == _current) return;
    _current = layout;
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      _changes.value = _current;
    });
  }

  @disposeMethod
  void dispose() => _changes.dispose();
}
