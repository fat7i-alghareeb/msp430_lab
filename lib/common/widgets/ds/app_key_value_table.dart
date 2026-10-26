import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';

/// One row of [AppKeyValueTable].
@immutable
class AppKeyValue {
  const AppKeyValue(this.label, this.value);

  final String label;
  final String value;
}

/// A label/value table for the details of an item.
///
/// **Display only.** Nothing in this table is tappable: no `tel:`, no maps, no
/// links. That has a consequence the server must respect — a phone number
/// placed in these rows renders as dead text. Phone numbers belong in a contact block, locations in
/// a location card, dates in the item's own timestamp fields.
///
/// The label sits at the start of the line, the value at the end.
class AppKeyValueTable extends StatelessWidget {
  const AppKeyValueTable({
    super.key,
    required this.rows,
    this.title,
    this.minRowHeight = 40,
  });

  final List<AppKeyValue> rows;

  /// Shown above the table. Hidden when null.
  final String? title;

  final double minRowHeight;

  @override
  Widget build(BuildContext context) {
    // An empty table renders nothing at all — not an empty box, and not a gap.
    if (rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null) ...<Widget>[
          Text(title!, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (var i = 0; i < rows.length; i++)
          Semantics(
            label: '${rows[i].label}: ${rows[i].value}',
            excludeSemantics: true,
            child: Container(
              constraints: BoxConstraints(minHeight: minRowHeight),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    // No divider after the last row.
                    ? null
                    : Border(bottom: BorderSide(color: colors.outline)),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rows[i].label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
