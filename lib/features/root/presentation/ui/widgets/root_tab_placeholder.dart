import 'package:flutter/material.dart';

import '../../../../../utils/constants/design_constants.dart';
import '../../../../../utils/extensions/theme_extensions.dart';

/// A tab with nothing in it yet: its name, centred. Replaced by the real
/// screen as each feature lands.
class RootTabPlaceholder extends StatelessWidget {
  const RootTabPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
