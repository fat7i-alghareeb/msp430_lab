import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-driven gradients and shadows.
///
/// Use these through `BuildContext`:
///
/// ```dart
/// decoration: BoxDecoration(
///   gradient: context.gradients.primary,
///   boxShadow: context.shadows.primary,
/// )
/// ```
///
/// Or use the fixed (non-theme) values:
///
/// ```dart
/// gradient: AppThemeGradients.fixed,
/// boxShadow: AppThemeShadows.fixed,
/// ```
///
/// The `context.gradients` and `context.shadows` getters are provided by
/// `utils/extensions/theme_extensions.dart`.

/// Static entry points for obtaining theme-aware gradients and shadows.
///
/// This is intentionally a pure facade (no DI). Values are derived from the
/// current `ThemeData` so they always reflect light/dark mode changes.
class AppThemeEffects {
  AppThemeEffects._();

  static AppThemeGradients gradients(ThemeData theme) => AppThemeGradients(
    colorScheme: theme.colorScheme,
    brightness: theme.brightness,
  );

  static AppThemeShadows shadows(ThemeData theme) => AppThemeShadows(
    colorScheme: theme.colorScheme,
    brightness: theme.brightness,
  );
}

/// Where a two-tone gradient runs, and how much darker its far end is.
///
/// The far end is the base colour mixed with black, never made transparent:
/// a see-through end lets the page show through and washes the colour out,
/// which is what drops white text on a button below readable contrast. A
/// darker end can only add contrast with light text.
class AppGradientSpec {
  const AppGradientSpec({
    required this.begin,
    required this.end,
    this.lightEndShade = 0.14,
    this.darkEndShade = 0.18,
  });

  final Alignment begin;
  final Alignment end;

  /// How much black is mixed into the far end, in the light and dark theme.
  final double lightEndShade;
  final double darkEndShade;
}

class AppShadowSpec {
  const AppShadowSpec({
    required this.blurRadius,
    required this.offset,
    required this.lightOpacity,
    required this.darkOpacity,
  });

  final double blurRadius;
  final Offset offset;

  final double lightOpacity;
  final double darkOpacity;
}

/// Theme-aware gradients derived from the current `ThemeData`.
///
/// Prefer accessing these through `BuildContext`:
///
/// ```dart
/// final g = context.gradients;
/// final gradient = g.primary;
/// ```
class AppThemeGradients {
  const AppThemeGradients({
    required this.colorScheme,
    required this.brightness,
  });

  final ColorScheme colorScheme;
  final Brightness brightness;

  static const AppGradientSpec _primarySpec = AppGradientSpec(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const AppGradientSpec _successSpec = AppGradientSpec(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const AppGradientSpec _errorSpec = AppGradientSpec(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const AppGradientSpec _warningSpec = AppGradientSpec(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const AppGradientSpec _greySpec = AppGradientSpec(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get primary =>
      _twoTone(colorScheme.primary, spec: _primarySpec);

  LinearGradient get success => _twoTone(_semantic.success, spec: _successSpec);

  LinearGradient get error => _twoTone(colorScheme.error, spec: _errorSpec);

  LinearGradient get warning => _twoTone(_semantic.warning, spec: _warningSpec);

  /// The theme's own success and warning colours: the light ones are too dark
  /// to carry dark text on a dark theme, and the dark ones too pale to carry
  /// white text on a light one.
  AppSemanticColors get _semantic => brightness == Brightness.dark
      ? AppSemanticColors.dark
      : AppSemanticColors.light;

  LinearGradient get grey => _twoTone(colorScheme.outline, spec: _greySpec);

  static const LinearGradient fixed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF8B5CF6), Color(0xFF3B82F6)],
  );

  LinearGradient _twoTone(Color base, {required AppGradientSpec spec}) {
    final shade = brightness == Brightness.dark
        ? spec.darkEndShade
        : spec.lightEndShade;
    return LinearGradient(
      begin: spec.begin,
      end: spec.end,
      colors: <Color>[
        base,
        Color.lerp(base, const Color(0xFF000000), shade)!,
      ],
    );
  }
}

/// Theme-aware shadows derived from the current `ThemeData`.
///
/// Prefer accessing these through `BuildContext`:
///
/// ```dart
/// final s = context.shadows;
/// final shadow = s.primary;
/// ```
class AppThemeShadows {
  const AppThemeShadows({required this.colorScheme, required this.brightness});

  final ColorScheme colorScheme;
  final Brightness brightness;

  static const AppShadowSpec _primarySpec = AppShadowSpec(
    blurRadius: 22,
    offset: Offset(0, 12),
    lightOpacity: 0.65,
    darkOpacity: 0.45,
  );

  static const AppShadowSpec _successSpec = AppShadowSpec(
    blurRadius: 18,
    offset: Offset(0, 10),
    lightOpacity: 0.65,
    darkOpacity: 0.42,
  );

  static const AppShadowSpec _errorSpec = AppShadowSpec(
    blurRadius: 20,
    offset: Offset(0, 10),
    lightOpacity: 0.65,
    darkOpacity: 0.48,
  );

  static const AppShadowSpec _warningSpec = AppShadowSpec(
    blurRadius: 16,
    offset: Offset(0, 9),
    lightOpacity: 0.18,
    darkOpacity: 0.40,
  );

  static const AppShadowSpec _greySpec = AppShadowSpec(
    blurRadius: 14,
    offset: Offset(0, 8),
    lightOpacity: 0.8,
    darkOpacity: 0.6,
  );

  List<BoxShadow> get primary =>
      _colored(colorScheme.primary, spec: _primarySpec);

  List<BoxShadow> get success =>
      _colored(AppColors.success, spec: _successSpec);

  List<BoxShadow> get error => _colored(AppColors.error, spec: _errorSpec);

  List<BoxShadow> get warning =>
      _colored(AppColors.warning, spec: _warningSpec);

  List<BoxShadow> get grey => _colored(colorScheme.outline, spec: _greySpec);

  static const List<BoxShadow> fixed = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  // ───────────────────────────── Elevation system
  //
  // ONE shadow in the whole system, at three intensities. In dark mode the
  // shadow is replaced by a 1px `outline` border, because a shadow is
  // invisible on a dark ground — use [borderOnDark] for that.
  //
  // Forbidden: a shadow AND a border on the same element; more than three
  // elevation layers on one screen.

  static const Color _shadowTint = Color(0xFF23261C);
  static const Color _sheetTint = Color(0xFF141510);

  /// `0 4px 16px rgba(35,38,28,.07)` — cards.
  List<BoxShadow> get card => brightness == Brightness.dark
      ? const <BoxShadow>[]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x1223261C), // .07
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];

  /// `0 4px 18px rgba(35,38,28,.12)` — the floating navigation bar.
  List<BoxShadow> get nav => brightness == Brightness.dark
      ? const <BoxShadow>[]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F23261C), // .12
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ];

  /// `0 -8px 30px rgba(20,21,16,.18)` — bottom sheets.
  List<BoxShadow> get sheet => brightness == Brightness.dark
      ? const <BoxShadow>[]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x2E141510), // .18
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ];

  /// What replaces the shadow in dark mode.
  ///
  /// Returns `null` in light mode — apply a shadow there instead, never both.
  BoxBorder? get borderOnDark => brightness == Brightness.dark
      ? Border.all(color: colorScheme.outline)
      : null;

  /// The raw tints, for callers that need to build their own shadow.
  static const Color shadowTint = _shadowTint;
  static const Color sheetTint = _sheetTint;

  List<BoxShadow> _colored(Color base, {required AppShadowSpec spec}) {
    final opacity = brightness == Brightness.dark
        ? spec.darkOpacity
        : spec.lightOpacity;

    return <BoxShadow>[
      BoxShadow(
        color: base.withValues(alpha: opacity),
        blurRadius: spec.blurRadius,
        offset: spec.offset,
      ),
    ];
  }
}
