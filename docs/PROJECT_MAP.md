# Project map

```
lib/
  main.dart, bootstrap.dart, app.dart   start-up and the root widget
  core/
    config/       AppConfig, localization config
    injection/    GetIt + Injectable (run build_runner after changing)
    layout/       breakpoints, AppLayout, AdaptiveLayout, adaptive typography
    platform/     AppPlatform: what the device can do (never for layout)
    window/       desktop window + custom title bar (Windows)
    shortcuts/    keyboard shortcuts and the macOS menu bar
    router/       go_router: nested page tree, navigator, transitions
    theme/        colours, text styles, light theme
    services/     storage (shared_preferences), localization, haptics
    error/ utils/ AppException, Result, BlocStatus, StatusBuilder
  common/
    widgets/      app_scaffold, buttons, dialogs, sheets, states, ds/ (design system)
    imports/      one barrel for screens
  features/
    splash/       first screen
    root/         the shell: bottom bar, rail or sidebar by window size
                  (full data/domain/presentation example, local data)
    topic/        a page pushed over the shell (placeholder)
  utils/          constants, extensions, helpers, generated AppStrings
assets/l10n/      ar.json, en.json  ->  dart run tool/generate_app_strings.dart
tool/             generate_feature.dart, generate_app_strings.dart, widget_catalog.dart
docs/             RESPONSIVE.md, CODE_STYLE.md, DESKTOP_SETUP.md
```

New feature: `dart run tool/generate_feature.dart <name>`, then register the
route in `core/router/app_routes.dart` and write its strings in `assets/l10n`.
After any change to injectable or freezed classes: `dart run build_runner build`.
