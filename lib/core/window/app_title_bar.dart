import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../common/widgets/ds/app_icons.dart';
import '../../common/widgets/ds/app_mark.dart';
import '../../utils/constants/design_constants.dart';
import '../../utils/extensions/theme_extensions.dart';
import '../../utils/helpers/app_strings.dart';
import '../config/app_config.dart';
import '../layout/app_layout.dart';
import '../layout/app_layout_scope.dart';
import '../platform/app_platform.dart';
import '../shortcuts/app_commands.dart';
import 'app_window.dart';

/// What the title bar shows and does — supplied by `App`, which knows the
/// router, the tabs and the services.
@immutable
class AppTitleBarConfig {
  const AppTitleBarConfig({
    this.pageTitle,
    this.onSearch,
    this.searchAvailable,
    this.onToggleSidebar,
    this.onToggleTheme,
    this.onToggleLanguage,
    this.isDark = false,
  });

  /// The current page's name, beside the app's.
  final ValueListenable<String?>? pageTitle;

  /// Runs a search typed into the bar. Null hides the field.
  final ValueChanged<String>? onSearch;

  /// Whether a search can run on the page showing right now. The field is
  /// drawn only then (the sign-in page has nothing to search), but its room
  /// stays, so the bar does not change height between pages. Null: always.
  final ValueListenable<bool>? searchAvailable;

  /// Collapses or expands the sidebar. Shown only when there is one.
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onToggleLanguage;
  final bool isDark;
}

/// The desktop window's frame: the app's own title bar over the app.
///
/// ```text
/// ┌───────────────────────────────────────────────────────────────┐
/// │ ◧  ▣ MSP430 Lab · Feed      [🔍 Search      Ctrl K]   ☀  ع  ─ ▢ ✕ │  32 · 48
/// ├───────────────────────────────────────────────────────────────┤
/// │ sidebar │ content                                             │
/// ```
///
/// - **The screen's own ground**, not a grey OS strip: Microsoft asks title
///   bars to blend with the window where they can.
/// - **Height** (Microsoft): 32, or 48 once it carries the search box. On
///   macOS it matches the system band the real traffic lights sit in.
/// - **Empty space drags the window**; a double click maximises; a right
///   click opens the system window menu on Windows.
/// - **Inactive**: the bar's content dims while the window has no focus.
/// - **Caption buttons** stay top-right on Windows in either language;
///   macOS keeps its own traffic lights.
///
/// Phones and tablets get [child] unchanged.
class AppDesktopFrame extends StatelessWidget {
  const AppDesktopFrame({super.key, required this.config, required this.child});

  final AppTitleBarConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.hasDesktopWindow) return child;
    // Its own Overlay: `App` puts this frame ABOVE the navigator, where there
    // is no Overlay yet, and a Tooltip (the bar's icon buttons) has nowhere to
    // draw without one — «No Overlay widget found». The app's navigator keeps
    // its own overlay below; tooltips from the bar float over everything.
    return Overlay.wrap(
      child: Column(
        children: <Widget>[
          _TitleBar(config: config),
          Expanded(
            // The bar has taken the top of the window: pages below it must
            // not pad themselves for a status bar that is not there.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.config});

  final AppTitleBarConfig config;

  /// Microsoft's heights.
  static const double _standard = 32;
  static const double _tall = 48;

  /// The search box needs an expanded window; a narrower one keeps the
  /// screen's own search.
  ///
  /// It grows with the window — a third of it, between these two — so it does
  /// not sit as a small slot in the middle of a wide bar. The two drag areas
  /// beside it keep the rest.
  static const double _searchMinWidth = 360;
  static const double _searchMaxWidth = 640;

  /// What is left of the bar's height around the search box: 6 above, 6 below.
  static const double _searchInset = 12;

  static double _searchWidthFor(double windowWidth) =>
      (windowWidth / 3).clamp(_searchMinWidth, _searchMaxWidth);

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutScope.of(context);
    final showSearch = config.onSearch != null && layout.isExpandedUp;
    final mac = AppPlatform.isMacOS;

    return ValueListenableBuilder<double>(
      valueListenable: AppWindow.macTitleBarHeight,
      builder: (context, macHeight, _) {
        final height = mac ? macHeight : (showSearch ? _tall : _standard);
        return ValueListenableBuilder<bool>(
          valueListenable: AppWindow.isActive,
          builder: (context, active, _) => _bar(
            context,
            layout: layout,
            height: height,
            showSearch: showSearch,
            active: active,
          ),
        );
      },
    );
  }

  Widget _bar(
    BuildContext context, {
    required AppLayout layout,
    required double height,
    required bool showSearch,
    required bool active,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mac = AppPlatform.isMacOS;
    final sidebar = layout.nav == NavLayout.sidebar;
    // Microsoft: content fades when the window is inactive.
    final fg = colors.onSurface.withValues(alpha: active ? 1 : 0.45);
    final iconColor = colors.onSurfaceVariant.withValues(
      alpha: active ? 1 : 0.45,
    );

    final start = <Widget>[
      // macOS draws its traffic lights here; leave them room.
      if (mac) const SizedBox(width: 76) else const SizedBox(width: 6),
      if (sidebar && config.onToggleSidebar != null)
        _BarIcon(
          icon: AppIcons.panelLeft,
          label: AppStrings.windowToggleSidebar,
          color: iconColor,
          onTap: config.onToggleSidebar!,
        ),
      // The sidebar already carries the mark and the name; without it the
      // bar does (Microsoft: icon 16 from the edge, title 16 after it).
      if (!sidebar) ...<Widget>[
        const SizedBox(width: AppSpacing.sm2),
        const AppMark(size: 16),
        const SizedBox(width: AppSpacing.sm2),
        Text(
          AppConfig.appTitle,
          style: theme.textTheme.labelMedium?.copyWith(color: fg),
        ),
      ],
      if (config.pageTitle != null)
        ValueListenableBuilder<String?>(
          valueListenable: config.pageTitle!,
          builder: (context, title, _) {
            if (title == null || title.isEmpty) return const SizedBox();
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(color: fg),
              ),
            );
          },
        ),
    ];

    final end = <Widget>[
      if (config.onToggleTheme != null)
        _BarIcon(
          icon: config.isDark ? AppIcons.lightMode : AppIcons.darkMode,
          label: AppStrings.navDarkMode,
          color: iconColor,
          onTap: config.onToggleTheme!,
        ),
      if (config.onToggleLanguage != null)
        _BarIcon(
          icon: AppIcons.language,
          label: AppStrings.settingsLanguage,
          color: iconColor,
          onTap: config.onToggleLanguage!,
        ),
      const SizedBox(width: AppSpacing.xs),
    ];

    // The two sides drag the window; the search box between them does not,
    // so selecting its text never moves the window.
    final content = Row(
      children: <Widget>[
        Expanded(
          child: _DragArea(
            child: Row(children: <Widget>[...start, const Spacer()]),
          ),
        ),
        if (showSearch)
          SizedBox(
            width: _searchWidthFor(layout.size.width),
            height: height - _searchInset,
            child: ValueListenableBuilder<bool>(
              valueListenable:
                  config.searchAvailable ?? _searchAlways,
              builder: (context, available, _) => available
                  ? _BarSearch(onSearch: config.onSearch!, active: active)
                  : const SizedBox.shrink(),
            ),
          ),
        Expanded(
          child: _DragArea(
            child: Row(children: <Widget>[const Spacer(), ...end]),
          ),
        ),
      ],
    );

    return Material(
      color: context.semantic.background,
      child: SizedBox(
        height: height,
        child: Row(
          // Caption buttons stay top-right on Windows in either language;
          // only the bar's own content follows the reading direction.
          textDirection: TextDirection.ltr,
          children: <Widget>[
            Expanded(
              child: Directionality(
                textDirection: Directionality.of(context),
                child: content,
              ),
            ),
            if (!mac) _CaptionButtons(height: height, active: active),
          ],
        ),
      ),
    );
  }
}

/// Dragging moves the window, a double click maximises it (window_manager),
/// a right click opens the system window menu on Windows (Microsoft).
class _DragArea extends StatelessWidget {
  const _DragArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTap: AppPlatform.isWindows
          ? () => windowManager.popUpWindowMenu()
          : null,
      child: DragToMoveArea(child: child),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.xs),
          child: SizedBox(
            width: 36,
            height: 28,
            child: Center(
              child: AppIcon(icon, size: AppIconSizes.inline + 2, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stands in for `AppTitleBarConfig.searchAvailable` when there is none.
final ValueNotifier<bool> _searchAlways = ValueNotifier<bool>(true);

class _BarSearch extends StatefulWidget {
  const _BarSearch({required this.onSearch, required this.active});

  final ValueChanged<String> onSearch;
  final bool active;

  @override
  State<_BarSearch> createState() => _BarSearchState();
}

class _BarSearchState extends State<_BarSearch> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'title-bar-search');

  @override
  void initState() {
    super.initState();
    // Ctrl/⌘+K lands here.
    AppCommands.addSearchField(_focus);
  }

  @override
  void dispose() {
    AppCommands.removeSearchField(_focus);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hint = colors.onSurfaceVariant.withValues(
      alpha: widget.active ? 1 : 0.6,
    );
    return TextField(
      controller: _controller,
      focusNode: _focus,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        widget.onSearch(value.trim());
      },
      style: theme.textTheme.bodyMedium,
      // Fill the height the bar gives it. Without `expands` the field draws
      // its border around ONE line of text and floats in the middle of the
      // box it was given — a thin sliver in a 48dp bar.
      expands: true,
      maxLines: null,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.surface,
        hintText: AppStrings.searchPlaceholder,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: hint),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 10, end: 6),
          child: AppIcon(
            AppIcons.search,
            size: AppIconSizes.inline,
            color: hint,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 32),
        suffixText: '${AppPlatform.isMacOS ? '⌘' : 'Ctrl'} K',
        suffixStyle: theme.textTheme.labelSmall?.copyWith(color: hint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colors.outline),
        ),
      ),
    );
  }
}

/// Windows' minimise, maximise/restore and close, drawn the way Microsoft
/// asks a custom bar to draw them: the Segoe Fluent chrome glyphs (E921,
/// E922, E923, E8BB), 46 wide, full bar height, a full-bleed backplate, and
/// rest · hover · pressed · inactive states — Close turns red on hover.
///
/// Snap Layouts: Windows 11 shows its layout menu over a SYSTEM maximise
/// button. A drawn one needs the runner to answer WM_NCHITTEST with
/// HTMAXBUTTON (`docs/DESKTOP_SETUP.md`); Win + Z works either way.
class _CaptionButtons extends StatelessWidget {
  const _CaptionButtons({required this.height, required this.active});

  final double height;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppWindow.isMaximized,
      builder: (context, maximized, _) => Row(
        // Minimise, maximise, close — left to right in every language, as
        // Windows draws them: this row would otherwise inherit the app's
        // direction and put Close first in Arabic.
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _CaptionButton(
            glyph: '',
            label: AppStrings.windowMinimize,
            height: height,
            active: active,
            onTap: () => windowManager.minimize(),
          ),
          _CaptionButton(
            glyph: maximized ? '' : '',
            label: maximized
                ? AppStrings.windowRestore
                : AppStrings.windowMaximize,
            height: height,
            active: active,
            onTap: () => maximized
                ? windowManager.unmaximize()
                : windowManager.maximize(),
          ),
          _CaptionButton(
            glyph: '',
            label: AppStrings.actionClose,
            height: height,
            active: active,
            isClose: true,
            onTap: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.glyph,
    required this.label,
    required this.height,
    required this.active,
    required this.onTap,
    this.isClose = false,
  });

  final String glyph;
  final String label;
  final double height;
  final bool active;
  final VoidCallback onTap;
  final bool isClose;

  /// Windows' own close-button red.
  static const Color closeHover = Color(0xFFC42B1C);

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;
    if (widget.isClose && (_hover || _pressed)) {
      background = _CaptionButton.closeHover.withValues(
        alpha: _pressed ? 0.9 : 1,
      );
      foreground = Colors.white;
    } else {
      background = _pressed
          ? colors.onSurface.withValues(alpha: 0.10)
          : _hover
          ? colors.onSurface.withValues(alpha: 0.06)
          : Colors.transparent;
      foreground = colors.onSurface.withValues(
        alpha: widget.active || _hover ? 1 : 0.45,
      );
    }
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: Container(
            width: 46,
            height: widget.height,
            color: background,
            alignment: Alignment.center,
            child: Text(
              widget.glyph,
              style: TextStyle(
                fontFamily: 'Segoe Fluent Icons',
                fontFamilyFallback: const <String>['Segoe MDL2 Assets'],
                fontSize: 10,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
