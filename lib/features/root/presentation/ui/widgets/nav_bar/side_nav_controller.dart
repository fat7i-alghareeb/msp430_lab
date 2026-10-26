import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../../core/services/storage/storage_service.dart';

/// Whether the sidebar is collapsed to a rail.
///
/// One instance for the app: the sidebar's own button, the title bar's
/// toggle and Ctrl/⌘+B all flip the same value, and it is remembered across
/// launches. Only expanded windows read it — a medium window always shows
/// the rail, a compact one the capsule.
@lazySingleton
class SideNavController extends ValueNotifier<bool> {
  SideNavController(this._storage) : super(false) {
    unawaited(_restore());
  }

  static const String _storageKey = 'nav.sidebarCollapsed';

  final StorageService _storage;

  bool get collapsed => value;

  void toggle() => setCollapsed(!value);

  void setCollapsed(bool collapsed) {
    if (collapsed == value) return;
    value = collapsed;
    unawaited(_storage.writeBool(_storageKey, collapsed));
  }

  Future<void> _restore() async {
    try {
      final saved = await _storage.readBool(_storageKey);
      if (saved != null) value = saved;
    } catch (_) {
      // A storage that cannot be read leaves the sidebar open.
    }
  }
}
