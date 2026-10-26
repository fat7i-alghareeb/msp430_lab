import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../common/widgets/app_dialog.dart';
import '../../../../../utils/constants/design_constants.dart';
import '../../../../../utils/helpers/app_strings.dart';
import 'nav_bar/navigation_controller.dart';

/// What back does on the tabs themselves: on another tab it returns to
/// home — through the same cross-fade
/// as a tap on the bar — and on home it asks before the app closes.
///
/// A page pushed over the tabs pops as it always did: this only answers a
/// back that reaches the shell.
class RootBackGuard extends StatefulWidget {
  const RootBackGuard({
    super.key,
    required this.controller,
    required this.child,
    this.onLeave,
  });

  final NavigationController controller;
  final Widget child;

  /// Closes the app. Tests pass their own.
  final Future<void> Function()? onLeave;

  /// Home's place in the bar.
  static const int homeIndex = 0;

  @override
  State<RootBackGuard> createState() => _RootBackGuardState();
}

class _RootBackGuardState extends State<RootBackGuard> {
  bool _asking = false;

  Future<void> _onBack() async {
    if (widget.controller.currentIndex != RootBackGuard.homeIndex) {
      widget.controller.setIndex(RootBackGuard.homeIndex);
      return;
    }
    if (_asking) return;
    _asking = true;
    final leave = await AppDialog.show<bool>(
      context,
      dialog: AppDialog.basic(
        title: AppStrings.exitTitle,
        message: AppStrings.exitMessage,
        borderRadius: AppRadii.sheet,
        // «البقاء» is the primary action — staying is what we hope for —
        // and «خروج» wears the error colour.
        primaryAction: AppDialogAction.primary(
          label: AppStrings.exitStay,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        secondaryAction: AppDialogAction.danger(
          label: AppStrings.exitConfirm,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ),
    );
    _asking = false;
    if (leave != true) return;
    await (widget.onLeave ?? SystemNavigator.pop)();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: widget.child,
    );
  }
}
