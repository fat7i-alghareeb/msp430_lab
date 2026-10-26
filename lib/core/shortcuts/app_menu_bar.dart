import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/helpers/app_strings.dart';
import '../config/app_config.dart';
import '../platform/app_platform.dart';
import 'app_shortcuts.dart';

/// The macOS menu bar, localised and wired to the app.
///
/// [PlatformMenuBar] draws natively on macOS only, so every other platform
/// gets [child] as it is. The system's own items — About, Services, Hide,
/// Quit, Full Screen, the Window menu — come from
/// [PlatformProvidedMenuItem], so they behave and read exactly as in any
/// Mac app; the app adds a View menu.
class AppMenuBar extends StatelessWidget {
  const AppMenuBar({super.key, required this.handlers, required this.child});

  final AppShortcutHandlers handlers;
  final Widget child;

  static bool _provided(PlatformProvidedMenuItemType type) =>
      PlatformProvidedMenuItem.hasMenu(type);

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isMacOS) return child;
    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: AppConfig.appTitle,
          menus: <PlatformMenuItem>[
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                if (_provided(PlatformProvidedMenuItemType.about))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.about,
                  ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                if (_provided(PlatformProvidedMenuItemType.servicesSubmenu))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.servicesSubmenu,
                  ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                for (final type in const <PlatformProvidedMenuItemType>[
                  PlatformProvidedMenuItemType.hide,
                  PlatformProvidedMenuItemType.hideOtherApplications,
                  PlatformProvidedMenuItemType.showAllApplications,
                ])
                  if (_provided(type)) PlatformProvidedMenuItem(type: type),
              ],
            ),
            if (_provided(PlatformProvidedMenuItemType.quit))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
          ],
        ),
        PlatformMenu(
          label: AppStrings.menuView,
          menus: <PlatformMenuItem>[
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: AppStrings.windowToggleSidebar,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyB,
                    meta: true,
                  ),
                  onSelected: handlers.toggleSidebar,
                ),
                PlatformMenuItem(
                  label: AppStrings.actionRefresh,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyR,
                    meta: true,
                  ),
                  onSelected: handlers.refresh,
                ),
              ],
            ),
            if (_provided(PlatformProvidedMenuItemType.toggleFullScreen))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.toggleFullScreen,
              ),
          ],
        ),
        PlatformMenu(
          label: AppStrings.menuWindow,
          menus: <PlatformMenuItem>[
            for (final type in const <PlatformProvidedMenuItemType>[
              PlatformProvidedMenuItemType.minimizeWindow,
              PlatformProvidedMenuItemType.zoomWindow,
              PlatformProvidedMenuItemType.arrangeWindowsInFront,
            ])
              if (_provided(type)) PlatformProvidedMenuItem(type: type),
          ],
        ),
      ],
      child: child,
    );
  }
}
