import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

/// The app's mark: its initial on the primary colour.
///
/// Swap the child for your logo once; every place that shows the mark — the
/// sidebar, the sign-in brand panel, the splash, the title bar — reads it
/// from here.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 32, this.inverted = false});

  final double size;

  /// The colours swapped, for a mark ON the primary colour.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = inverted ? colors.onPrimary : colors.primary;
    final ink = inverted ? colors.primary : colors.onPrimary;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Text(
          AppConfig.appTitle.characters.first.toUpperCase(),
          style: TextStyle(
            color: ink,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
