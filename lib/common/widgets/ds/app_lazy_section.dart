import 'package:flutter/material.dart';

import '../../../core/utils/bloc_status.dart';
import '../../../utils/constants/design_constants.dart';
import '../../../utils/helpers/app_strings.dart';
import '../scroll_reveal.dart';
import 'app_chip.dart';
import 'app_icons.dart';

/// The frame every section of a sectioned page sits in — a home screen made
/// of independent blocks (a carousel, a rail, a list…).
///
/// It owns the four behaviours that are the same for every section, so no
/// section can forget one of them:
///
/// * **It asks for its own data** ([onRequested]) the first time it is
///   built. Put the sections in a lazy `SliverList` inside a
///   `CustomScrollView` with `scrollCacheExtent: 400` and that is the
///   «nothing loads until it is within 400dp of the viewport» rule, with no
///   scroll maths. The bloc must ignore a request for a section that is not
///   in its initial state — a section is built again on every scroll past it.
/// * **The title appears immediately** and is never a skeleton — the page does
///   not jump when the data lands.
/// * **An empty section disappears entirely**, its title with it. A page has
///   one empty state at most (everything empty), never one per section.
/// * **A failure stays inside the section**: a retry row ([onRetry]), and the
///   rest of the page keeps working.
///
/// Give each section its own `BlocStatus` in the bloc's state and select it
/// with a `BlocSelector`, so one section landing never rebuilds another.
class AppLazySection<T> extends StatefulWidget {
  const AppLazySection({
    super.key,
    required this.status,
    required this.builder,
    required this.loading,
    required this.onRequested,
    required this.onRetry,
    this.title,
    this.actionLabel,
    this.onActionTap,
    this.count,
    this.accent,
    this.newLabel,
  });

  final BlocStatus<List<T>> status;

  /// Draws the section once its data is in.
  final Widget Function(BuildContext context, List<T> data) builder;

  /// The section's own skeleton — its real shape (a `.loading()` widget),
  /// not a grey block.
  final WidgetBuilder loading;

  /// Asks the bloc for this section's data. Called once, after the first
  /// frame the section is built in.
  final VoidCallback onRequested;

  /// Reloads this section only.
  final VoidCallback onRetry;

  /// A section with no title (a banner carousel) simply has no header.
  final String? title;

  final String? actionLabel;
  final VoidCallback? onActionTap;

  /// How many items «See all» leads to, counting up the first time.
  final int? count;

  /// The header's accent bar colour.
  final Color? accent;

  /// «2 new» when the section has items newer than the last visit.
  final String? newLabel;

  @override
  State<AppLazySection<T>> createState() => _AppLazySectionState<T>();
}

class _AppLazySectionState<T> extends State<AppLazySection<T>> {
  @override
  void initState() {
    super.initState();
    // Post-frame: a bloc event dispatched during build would rebuild the tree
    // it is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRequested();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;

    // Gone, with its title.
    final data = status.getDataWhenSuccess;
    if (status.isSuccess && (data == null || data.isEmpty)) {
      return const SizedBox.shrink();
    }

    final Widget content = status.isFailed
        ? _SectionRetryRow(onRetry: widget.onRetry)
        : status.isSuccess
        ? widget.builder(context, data!)
        : widget.loading(context);

    final title = widget.title;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              // The header rises on its own; the section's cards and rows each
              // carry their own entrance.
              child: ScrollReveal(
                child: AppSectionHeader(
                  title: title,
                  actionLabel: widget.actionLabel,
                  onActionTap: widget.onActionTap,
                  count: widget.count,
                  accent: widget.accent,
                  newLabel: widget.newLabel,
                ),
              ),
            ),
          content,
        ],
      ),
    );
  }
}

/// «Couldn't load this section» + «Retry», inside the section only.
class _SectionRetryRow extends StatelessWidget {
  const _SectionRetryRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screenMargin,
      ),
      child: Row(
        children: <Widget>[
          AppIcon(AppIcons.alert, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppStrings.stateSectionFailed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
