import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import 'app_icons.dart';

/// One entry of a context menu.
@immutable
class AppMenuAction {
  const AppMenuAction({
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  /// A constant from [AppIcons].
  final String icon;
  final String label;
  final VoidCallback onSelected;
}

/// A context menu at a point: a right click with a mouse, a long press on
/// touch.
///
/// Flutter's platform idioms guide: mouse users rely on context menus, so on
/// desktop they are part of the interface, not a shortcut. The same actions
/// stay reachable another way (the card opens on tap; its page has the rest).
abstract final class AppContextMenu {
  static Future<void> show(
    BuildContext context, {
    required Offset globalPosition,
    required List<AppMenuAction> actions,
  }) async {
    if (actions.isEmpty) return;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final local = overlay.globalToLocal(globalPosition);
    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        local & Size.zero,
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      items: <PopupMenuEntry<int>>[
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: <Widget>[
                AppIcon(actions[i].icon),
                const SizedBox(width: AppSpacing.md),
                Flexible(child: Text(actions[i].label)),
              ],
            ),
          ),
      ],
    );
    if (selected != null) actions[selected].onSelected();
  }
}
