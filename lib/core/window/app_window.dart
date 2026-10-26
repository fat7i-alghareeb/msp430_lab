import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../config/app_config.dart';
import '../injection/injectable.dart';
import '../platform/app_platform.dart';
import '../services/storage/storage_service.dart';

/// The desktop window: its first appearance, its size limits, its title
/// bar style and the size and place it is remembered at
/// (`docs/DESKTOP_SETUP.md`).
///
/// Every call is a no-op on Android and iOS — window_manager has no code
/// there.
///
/// **Hidden until the first frame.** flutter_native_splash draws nothing on
/// Windows or macOS, so a window shown at once is an empty rectangle until
/// Flutter paints. The runner is patched to create the window hidden
/// (`tool/setup_project.dart`); [showWhenReady] shows it once the first frame
/// is on screen — the first thing anyone sees is the app's own splash.
abstract final class AppWindow {
  /// Opens at this size the first time.
  static const Size defaultSize = Size(1280, 800);

  /// Microsoft: a window should accept a width of at most 500 for Snap
  /// Layouts to fit it in their zones.
  static const Size minimumSize = Size(500, 600);

  /// Whether the window currently has the keyboard focus. The title bar
  /// dims its content while it does not (Microsoft's title bar guidance).
  static final ValueNotifier<bool> isActive = ValueNotifier<bool>(true);

  /// Whether the window is maximised — the caption button swaps its glyph.
  static final ValueNotifier<bool> isMaximized = ValueNotifier<bool>(false);

  /// The height of the system title bar band on macOS, where the real
  /// traffic lights sit; the custom bar matches it so they line up.
  static final ValueNotifier<double> macTitleBarHeight = ValueNotifier<double>(
    28,
  );

  static _WindowState? _restore;

  /// Before `runApp`: sets the size limits and the hidden title bar.
  static Future<void> initialize() async {
    if (!AppPlatform.hasDesktopWindow) return;
    await windowManager.ensureInitialized();
    _restore = await _WindowState.read();

    final options = WindowOptions(
      size: _restore?.bounds.size ?? defaultSize,
      center: _restore == null,
      minimumSize: minimumSize,
      title: AppConfig.appTitle,
      // The app draws its own bar; macOS keeps its real traffic lights
      // (Apple's HIG: avoid custom window controls), Windows gets drawn
      // caption buttons in the bar.
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: AppPlatform.isMacOS,
    );
    // Applies the options. The window stays hidden — the runner no longer
    // shows it — until [showWhenReady].
    await windowManager.waitUntilReadyToShow(options);
    windowManager.addListener(_Listener());
    if (AppPlatform.isMacOS) {
      final height = await windowManager.getTitleBarHeight();
      if (height > 0) macTitleBarHeight.value = height.toDouble();
    }
  }

  /// After `runApp`: shows the window once its first frame is on screen,
  /// back where it was last time.
  static Future<void> showWhenReady() async {
    if (!AppPlatform.hasDesktopWindow) return;
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    final restore = _restore;
    if (restore != null && await _isOnAScreen(restore.bounds)) {
      await windowManager.setBounds(restore.bounds);
      if (restore.maximized) await windowManager.maximize();
    }
    await windowManager.show();
    await windowManager.focus();
    isMaximized.value = await windowManager.isMaximized();
  }

  /// A window remembered on a monitor that has since been unplugged would
  /// open off-screen; it opens centred at its default size instead.
  static Future<bool> _isOnAScreen(Rect bounds) async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      return displays.any((display) {
        final origin = display.visiblePosition ?? Offset.zero;
        final size = display.visibleSize ?? display.size;
        final screen = origin & size;
        // Enough of the title bar on screen to grab it.
        return screen.overlaps(
          Rect.fromLTWH(bounds.left, bounds.top, bounds.width, 48),
        );
      });
    } catch (_) {
      return false;
    }
  }

  static Timer? _saveTimer;

  /// Saved a moment after the last move or resize, not on every pixel.
  static void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () async {
      final maximized = await windowManager.isMaximized();
      final bounds = maximized
          ? _restore?.bounds ?? await windowManager.getBounds()
          : await windowManager.getBounds();
      final state = _WindowState(bounds: bounds, maximized: maximized);
      _restore = state;
      await state.write();
    });
  }
}

class _Listener with WindowListener {
  @override
  void onWindowFocus() => AppWindow.isActive.value = true;

  @override
  void onWindowBlur() => AppWindow.isActive.value = false;

  @override
  void onWindowMaximize() {
    AppWindow.isMaximized.value = true;
    AppWindow._scheduleSave();
  }

  @override
  void onWindowUnmaximize() {
    AppWindow.isMaximized.value = false;
    AppWindow._scheduleSave();
  }

  @override
  void onWindowResized() => AppWindow._scheduleSave();

  @override
  void onWindowMoved() => AppWindow._scheduleSave();
}

/// The window's last size, place and maximised state.
@immutable
class _WindowState {
  const _WindowState({required this.bounds, required this.maximized});

  static const String _key = 'window.state';

  final Rect bounds;
  final bool maximized;

  static StorageService? get _storage =>
      getIt.isRegistered<StorageService>() ? getIt<StorageService>() : null;

  static Future<_WindowState?> read() async {
    try {
      final raw = await _storage?.readString(_key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, Object?>;
      final width = (json['w']! as num).toDouble();
      final height = (json['h']! as num).toDouble();
      if (width < AppWindow.minimumSize.width ||
          height < AppWindow.minimumSize.height) {
        return null;
      }
      return _WindowState(
        bounds: Rect.fromLTWH(
          (json['x']! as num).toDouble(),
          (json['y']! as num).toDouble(),
          width,
          height,
        ),
        maximized: json['max'] == true,
      );
    } catch (_) {
      // A broken entry opens the window at its defaults.
      return null;
    }
  }

  Future<void> write() async {
    await _storage?.writeString(
      _key,
      jsonEncode(<String, Object>{
        'x': bounds.left,
        'y': bounds.top,
        'w': bounds.width,
        'h': bounds.height,
        'max': maximized,
      }),
    );
  }
}
