import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../platform/app_platform.dart';
import 'app_shortcut_catalog.dart';

/// What the app-wide shortcuts do — supplied by `App`, which knows the
/// router, the tabs and the sidebar.
@immutable
class AppShortcutHandlers {
  const AppShortcutHandlers({
    required this.switchTab,
    required this.goBack,
    required this.refresh,
    required this.toggleSidebar,
    required this.showHelp,
  });

  final ValueChanged<int> switchTab;
  final VoidCallback goBack;
  final VoidCallback refresh;
  final VoidCallback toggleSidebar;
  final VoidCallback showHelp;
}

/// The app-wide keyboard shortcuts (the list: [AppShortcutCatalog]).
///
/// Above the navigator, so they work on every page. ⌘ on macOS and iPadOS,
/// Ctrl elsewhere; an iPad or an Android tablet with a keyboard gets them
/// too.
///
/// **Typing wins.** Flutter's input guide: app-wide keys must step aside
/// while the reader types. Every action here is disabled while a text field
/// has the focus, and a disabled action lets the key through to the field —
/// `?` types a question mark, Esc closes the keyboard's own thing.
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({super.key, required this.handlers, required this.child});

  final AppShortcutHandlers handlers;
  final Widget child;

  static bool get _apple => AppPlatform.isMacOS || AppPlatform.isIOS;

  /// ⌘+[key] on Apple platforms, Ctrl+[key] elsewhere.
  static SingleActivator primary(LogicalKeyboardKey key) =>
      SingleActivator(key, meta: _apple, control: !_apple);

  @override
  Widget build(BuildContext context) {
    final tabKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
    ];
    final bindings = <ShortcutActivator, VoidCallback>{
      for (var i = 0; i < tabKeys.length; i++)
        primary(tabKeys[i]): () => handlers.switchTab(i),
      const SingleActivator(LogicalKeyboardKey.escape): handlers.goBack,
      primary(LogicalKeyboardKey.keyR): handlers.refresh,
      const SingleActivator(LogicalKeyboardKey.f5): handlers.refresh,
      primary(LogicalKeyboardKey.keyB): handlers.toggleSidebar,
      appShortcutHelpKey: handlers.showHelp,
      if (AppPlatform.hasDesktopWindow)
        (AppPlatform.isMacOS
                ? const SingleActivator(
                    LogicalKeyboardKey.keyF,
                    control: true,
                    meta: true,
                  )
                : const SingleActivator(LogicalKeyboardKey.f11)):
            _toggleFullScreen,
    };

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        for (final entry in bindings.entries)
          entry.key: _CommandIntent(entry.value),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{_CommandIntent: _CommandAction()},
        child: child,
      ),
    );
  }

  static void _toggleFullScreen() {
    unawaited(() async {
      final full = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!full);
    }());
  }
}

class _CommandIntent extends Intent {
  const _CommandIntent(this.run);

  final VoidCallback run;
}

class _CommandAction extends Action<_CommandIntent> {
  /// Off while a text field has the focus, so the key reaches the field.
  @override
  bool isEnabled(_CommandIntent intent) {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return true;
    return focused.widget is! EditableText &&
        focused.findAncestorWidgetOfExactType<EditableText>() == null;
  }

  @override
  Object? invoke(_CommandIntent intent) {
    intent.run();
    return null;
  }
}
