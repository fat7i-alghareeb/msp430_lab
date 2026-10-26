import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key–value interface implemented by concrete storage backends.
abstract class KeyValueStore {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<bool?> readBool(String key);
  Future<void> writeBool(String key, bool value);
  Future<void> remove(String key);
}

class _SharedPreferencesAsyncStore implements KeyValueStore {
  _SharedPreferencesAsyncStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> readString(String key) => _prefs.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<bool?> readBool(String key) => _prefs.getBool(key);

  @override
  Future<void> writeBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Key–value storage for small preferences (the language, the sidebar state,
/// the window's size). Nothing sensitive lives here.
///
/// Registered by `RegisterModule`; a test passes its own [KeyValueStore].
class StorageService {
  StorageService(this._store);

  /// A production instance backed by [SharedPreferencesAsync]: it needs no
  /// plugin data before `runApp`.
  factory StorageService.createDefault({SharedPreferencesAsync? preferences}) {
    return StorageService(
      _SharedPreferencesAsyncStore(preferences ?? SharedPreferencesAsync()),
    );
  }

  final KeyValueStore _store;

  Future<String?> readString(String key) => _store.readString(key);

  Future<void> writeString(String key, String value) =>
      _store.writeString(key, value);

  Future<bool?> readBool(String key) => _store.readBool(key);

  Future<void> writeBool(String key, bool value) =>
      _store.writeBool(key, value);

  Future<void> remove(String key) => _store.remove(key);
}
