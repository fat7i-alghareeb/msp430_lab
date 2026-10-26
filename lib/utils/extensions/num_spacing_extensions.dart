import 'package:flutter/widgets.dart';

/// Fixed gaps: `AppSpacing.md.verticalSpace`, `12.horizontalSpace`.
///
/// Plain logical pixels. Flutter's dp already account for screen density;
/// what changes with the window — gutters, columns, max widths — comes from
/// `AppLayout` (`docs/RESPONSIVE.md`), not from scaling every number by the
/// screen width.
extension AppGapX on num {
  Widget get verticalSpace => SizedBox(height: toDouble());

  Widget get horizontalSpace => SizedBox(width: toDouble());
}
