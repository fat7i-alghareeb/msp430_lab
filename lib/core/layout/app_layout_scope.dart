import 'package:flutter/widgets.dart';

import 'app_layout.dart';
import 'layout_reader.dart';

/// The parts of [AppLayout] a widget can depend on separately.
enum AppLayoutAspect { deviceType, windowSize, heightClass, size }

/// Hands the frame's [AppLayout] down the tree.
///
/// An [InheritedModel]: a widget that asks only for the window size class
/// (`AppLayoutScope.windowSizeOf`) rebuilds when the class flips — compact
/// to medium — not on every pixel of a window being dragged. Only
/// `AppLayoutScope.of` / `context.layout` subscribe to everything.
class AppLayoutScope extends InheritedModel<AppLayoutAspect> {
  const AppLayoutScope({super.key, required this.layout, required super.child});

  final AppLayout layout;

  /// The whole layout. Rebuilds on any change, the window size included.
  static AppLayout of(BuildContext context) => _of(context, null);

  static AppLayout? maybeOf(BuildContext context) =>
      InheritedModel.inheritFrom<AppLayoutScope>(context)?.layout;

  /// Rebuilds only when the width class changes.
  static WindowSize windowSizeOf(BuildContext context) =>
      _of(context, AppLayoutAspect.windowSize).windowSize;

  /// Rebuilds only when the height class changes.
  static HeightClass heightClassOf(BuildContext context) =>
      _of(context, AppLayoutAspect.heightClass).heightClass;

  static DeviceType deviceTypeOf(BuildContext context) =>
      _of(context, AppLayoutAspect.deviceType).deviceType;

  /// Where the destinations go. Rebuilds only when that changes.
  static NavLayout navOf(BuildContext context) {
    final layout = _of(context, AppLayoutAspect.windowSize);
    // `nav` also reads the height class.
    _of(context, AppLayoutAspect.heightClass);
    return layout.nav;
  }

  static AppLayout _of(BuildContext context, AppLayoutAspect? aspect) {
    final scope = InheritedModel.inheritFrom<AppLayoutScope>(
      context,
      aspect: aspect,
    );
    assert(scope != null, 'No AppLayoutScope above this context.');
    return scope!.layout;
  }

  @override
  bool updateShouldNotify(AppLayoutScope oldWidget) =>
      layout != oldWidget.layout;

  @override
  bool updateShouldNotifyDependent(
    AppLayoutScope oldWidget,
    Set<AppLayoutAspect> dependencies,
  ) {
    final old = oldWidget.layout;
    return dependencies.any(
      (aspect) => switch (aspect) {
        AppLayoutAspect.deviceType => layout.deviceType != old.deviceType,
        AppLayoutAspect.windowSize => layout.windowSize != old.windowSize,
        AppLayoutAspect.heightClass => layout.heightClass != old.heightClass,
        AppLayoutAspect.size => layout.size != old.size,
      },
    );
  }
}

/// Builds the [AppLayoutScope] for the window this frame is drawn into.
///
/// Sits in `MaterialApp.builder`, under the app's `MediaQuery`. Each build
/// also writes the layout into [reader] — the read-only copy blocs and
/// services use — so that copy is always one taken from a real frame.
class AppLayoutHost extends StatelessWidget {
  const AppLayoutHost({super.key, this.reader, required this.child});

  final LayoutReader? reader;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.resolve(
      size: MediaQuery.sizeOf(context),
      deviceType: AppLayout.deviceTypeOf(
        display: View.maybeOf(context)?.display,
      ),
    );
    reader?.update(layout);
    return AppLayoutScope(layout: layout, child: child);
  }
}
