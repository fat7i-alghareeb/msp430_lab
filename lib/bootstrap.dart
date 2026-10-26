import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;
import 'package:windows_single_instance/windows_single_instance.dart';

import 'core/config/app_config.dart';
import 'core/config/localization_config.dart';
import 'core/injection/injectable.dart';
import 'core/platform/app_platform.dart';
import 'core/services/localization/locale_service.dart';
import 'core/window/app_window.dart';
import 'utils/helpers/colored_print.dart';

/// Starts the app inside one guarded zone.
///
/// Order matters, and nothing slow runs before the first frame:
/// 1. binding and edge-to-edge system UI,
/// 2. dependency registration (no stored state is read),
/// 3. desktop only: the single-instance check and the hidden window,
/// 4. the saved language, within a short budget (the first frame must be
///    in the right language and direction),
/// 5. `runApp`, then the desktop window is shown once its first frame is up.
Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  List<String> args = const <String>[],
}) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      configureDependencies();

      await _ensureSingleInstance(args);
      await _initializeWindow();

      await EasyLocalization.ensureInitialized();
      final initialLocale = await _resolveSavedLocale();

      await _runGuardedApp(builder, initialLocale);
      unawaited(AppWindow.showWhenReady());
    },
    (error, stackTrace) {
      log('Uncaught application error', error: error, stackTrace: stackTrace);
    },
  );
}

Future<void> _initializeWindow() async {
  try {
    await AppWindow.initialize();
  } catch (e) {
    printY('[Bootstrap] Window initialize failed: $e');
  }
}

/// A second launch on Windows focuses the running window and exits.
Future<void> _ensureSingleInstance(List<String> args) async {
  if (!AppPlatform.isWindows) return;
  try {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      AppConfig.singleInstanceId,
    );
  } catch (e) {
    printY('[Bootstrap] Single-instance check failed: $e');
  }
}

const Duration _localeRestoreBudget = Duration(milliseconds: 250);

Future<Locale> _resolveSavedLocale() async {
  final service = getIt<LocaleService>();
  try {
    final saved = await service.resolveSavedLocale().timeout(
      _localeRestoreBudget,
      onTimeout: () => null,
    );
    return saved ?? service.resolveStartupLocale();
  } catch (e) {
    printY('[Bootstrap] Saved locale read failed: $e');
    return service.resolveStartupLocale();
  }
}

Future<void> _runGuardedApp(
  FutureOr<Widget> Function() builder,
  Locale initialLocale,
) async {
  final app = await builder();

  runApp(
    EasyLocalization(
      supportedLocales: AppLocalizationConfig.supportedLanguageCodes
          .map((code) => Locale(code))
          .toList(),
      path: AppLocalizationConfig.translationsPath,
      fallbackLocale: const Locale(AppLocalizationConfig.fallbackLanguageCode),
      startLocale: initialLocale,
      saveLocale: false,
      useOnlyLangCode: true,
      ignorePluralRules: false,
      child: app,
    ),
  );
}
