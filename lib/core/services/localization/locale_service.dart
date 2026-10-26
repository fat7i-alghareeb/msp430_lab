import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../utils/constants/localization_constants.dart';
import '../../config/localization_config.dart';
import '../../services/storage/storage_service.dart';

/// Central service for resolving and changing the app locale.
///
/// Responsibilities:
/// - Decide the initial locale on app start (saved locale > device > fallback)
/// - Persist the chosen locale using [StorageService]
/// - Provide an API to change the locale at runtime and sync EasyLocalization
@lazySingleton
class LocaleService {
  LocaleService(this._storage);

  final StorageService _storage;
  String? _cachedLanguageCode;

  /// Resolves the locale to use for the first Flutter frame.
  ///
  /// This intentionally avoids storage so the app can render immediately.
  Locale resolveStartupLocale() {
    final code = _resolveDeviceOrFallbackLanguageCode();
    _cachedLanguageCode ??= code;
    return Locale(code);
  }

  /// Resolves the persisted locale.
  ///
  /// Priority:
  /// 1. Saved locale in [StorageService]
  /// 2. Device locale if supported
  /// 3. Fallback locale from [AppLocalizationConfig]
  Future<Locale> resolveInitialLocale() async {
    final saved = await resolveSavedLocale();
    if (saved != null) return saved;

    final finalCode = _resolveDeviceOrFallbackLanguageCode();
    _cachedLanguageCode = finalCode;
    await _storage.writeString(LocalizationStorageKeys.localeCode, finalCode);

    return Locale(finalCode);
  }

  /// Reads the saved locale without falling back to device or writing defaults.
  Future<Locale?> resolveSavedLocale() async {
    final savedCode = await _storage.readString(
      LocalizationStorageKeys.localeCode,
    );

    if (savedCode != null && _isSupported(savedCode)) {
      _cachedLanguageCode = savedCode;
      return Locale(savedCode);
    }

    return null;
  }

  /// Applies the saved locale after the app has already rendered once.
  Future<void> reconcilePersistedLocale(BuildContext context) async {
    final saved = await resolveSavedLocale();
    if (!context.mounted) return;

    if (saved == null) {
      final code = _isSupported(context.locale.languageCode)
          ? context.locale.languageCode
          : _resolveDeviceOrFallbackLanguageCode();
      _cachedLanguageCode = code;
      await _storage.writeString(LocalizationStorageKeys.localeCode, code);
      return;
    }

    if (context.locale.languageCode != saved.languageCode) {
      await context.setLocale(saved);
    }
  }

  /// Changes the current language and updates both storage and UI.
  ///
  /// You must pass a [BuildContext] from inside the widget tree wrapped by
  /// [EasyLocalization] so that [setLocale] can rebuild the app.
  Future<void> changeLanguage(
    AppLanguage language,
    BuildContext context,
  ) async {
    final code = language.code;

    _cachedLanguageCode = code;
    await _storage.writeString(LocalizationStorageKeys.localeCode, code);
    if (context.mounted) await context.setLocale(Locale(code));
  }

  /// Returns the currently saved language code, or the fallback if none.
  Future<String> currentLanguageCode() async {
    final cached = _cachedLanguageCode;
    if (cached != null && _isSupported(cached)) return cached;

    final savedCode = await _storage.readString(
      LocalizationStorageKeys.localeCode,
    );
    if (savedCode != null && _isSupported(savedCode)) {
      _cachedLanguageCode = savedCode;
      return savedCode;
    }

    final code = _resolveDeviceOrFallbackLanguageCode();
    _cachedLanguageCode = code;
    return code;
  }

  bool _isSupported(String code) =>
      AppLocalizationConfig.supportedLanguageCodes.contains(code);

  String _deviceLanguageCode() {
    final locale = PlatformDispatcher.instance.locale;
    return locale.languageCode.toLowerCase();
  }

  String _resolveDeviceOrFallbackLanguageCode() {
    if (!AppLocalizationConfig.followDeviceLanguageOnFirstLaunch) {
      return AppLocalizationConfig.defaultLanguageCode;
    }

    final deviceCode = _deviceLanguageCode();
    return _isSupported(deviceCode)
        ? deviceCode
        : AppLocalizationConfig.defaultLanguageCode;
  }
}
