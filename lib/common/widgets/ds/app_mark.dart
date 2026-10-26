import 'package:flutter/material.dart';

/// The app's mark: the isometric MSP430 with its lid lifted.
///
/// Every place that shows the mark — the sidebar, the splash, the title bar,
/// the About page — reads it from here.
///
/// Below [detailMinSize] the full artwork turns to mush, so a simplified chip
/// (same colours, no lid) is drawn instead.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 32});

  final double size;

  /// Under this size the simplified mark is used.
  static const double detailMinSize = 24;

  static const String _full = 'assets/images/app_logo.png';
  static const String _small = 'assets/images/app_logo_small.png';

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image.asset(
        size < detailMinSize ? _small : _full,
        width: size,
        height: size,
      ),
    );
  }
}
