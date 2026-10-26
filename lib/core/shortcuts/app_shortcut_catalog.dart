import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/widgets/app_bottom_sheet.dart';
import '../../common/widgets/ds/app_icons.dart';
import '../../utils/constants/design_constants.dart';
import '../../utils/helpers/app_strings.dart';
import '../platform/app_platform.dart';

/// One keyboard shortcut: what it does and the keys, as the reader's OS
/// spells them.
@immutable
class AppShortcutInfo {
  const AppShortcutInfo({required this.label, required this.keys});

  final String label;
  final List<String> keys;
}

/// Every app-wide shortcut, in one list — the help sheet and the `?` key all read it, so they cannot disagree with the bindings
/// in `AppShortcuts`.
abstract final class AppShortcutCatalog {
  /// ⌘ on macOS and iPadOS, Ctrl everywhere else.
  static String get primaryModifier =>
      AppPlatform.isMacOS || AppPlatform.isIOS ? '⌘' : 'Ctrl';

  static bool get _apple => AppPlatform.isMacOS || AppPlatform.isIOS;

  static List<AppShortcutInfo> get all {
    final mod = primaryModifier;
    return <AppShortcutInfo>[
      AppShortcutInfo(label: AppStrings.shortcutsSwitchTab, keys: [mod, '1–5']),
      AppShortcutInfo(label: AppStrings.shortcutsBack, keys: const ['Esc']),
      AppShortcutInfo(label: AppStrings.actionRefresh, keys: [mod, 'R']),
      AppShortcutInfo(label: AppStrings.navCollapse, keys: [mod, 'B']),
      AppShortcutInfo(
        label: AppStrings.shortcutsFullScreen,
        keys: _apple ? const ['⌃', '⌘', 'F'] : const ['F11'],
      ),
      AppShortcutInfo(label: AppStrings.shortcutsHelp, keys: const ['?']),
    ];
  }

  /// Opens the list of shortcuts — a sheet on phones and tablets, a dialog
  /// in expanded windows.
  static Future<void> showHelp(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      sheet: AppBottomSheet.basic(
        title: AppStrings.shortcutsTitle,
        titleIcon: AppIcons.keyboard,
        child: const _ShortcutList(),
      ),
    );
  }
}

class _ShortcutList extends StatelessWidget {
  const _ShortcutList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = AppShortcutCatalog.all;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const Divider(height: 1),
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      items[i].label,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  // Keys are read left to right in every language.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: <Widget>[
                        for (final key in items[i].keys) _KeyCap(key),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 2),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// The keys that open the help sheet from anywhere: `?` (Shift + /).
const SingleActivator appShortcutHelpKey = SingleActivator(
  LogicalKeyboardKey.slash,
  shift: true,
);
