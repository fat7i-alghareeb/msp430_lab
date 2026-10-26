import '../imports/imports.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// EmptyStateWidget
/// --------------
///
/// A simple full-height empty state widget.
///
/// Features:
/// - Centered content
/// - Customizable [icon] via [IconSource]
/// - Optional pull-to-refresh (wraps content with [RefreshIndicator])
/// - Optional retry button (primary gradient) using [AppButton]
///
/// Usage:
/// ```dart
/// EmptyStateWidget(
///   text: AppStrings.emptyStateNoData,
///   onRefresh: () async => cubit.load(),
///   onRetrying: () => cubit.load(),
/// )
///
/// // With a network image icon:
/// EmptyStateWidget(
///   icon: IconSource.imageNetwork("https://..."),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    this.icon,
    this.text,
    this.description,
    this.onRefresh,
    this.onRetrying,
    this.retryLabel,
    this.retryIcon,
    // DESIGN_SYSTEM.md: the empty-state icon is 28, not a hero graphic.
    this.iconSize = AppIconSizes.emptyState,
    this.padding,
    this.maxWidth,
    this.textStyle,
    this.iconColor,
  });

  final IconSource? icon;

  /// The headline. Be specific: `لا توجد نتائج لـ «براد صغير»`, never
  /// `لا توجد بيانات`.
  final String? text;

  /// One supporting line under [text]. Hidden when null.
  final String? description;

  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetrying;

  final String? retryLabel;
  final IconSource? retryIcon;

  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final TextStyle? textStyle;
  final Color? iconColor;

  Widget _buildBody(BuildContext context) {
    final colors = context.colorScheme;

    final effectiveIcon =
        icon ?? IconSource.svg(AppIcons.empty, size: iconSize);

    final effectiveText = text?.trim().isNotEmpty == true
        ? text!
        : AppStrings.emptyStateNoData;

    // For pull-to-refresh to work even when the content doesn't fill the
    // viewport, the scroll view must always be scrollable.
    final physics = onRefresh != null
        ? const AlwaysScrollableScrollPhysics()
        : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

    final content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics,
          child: ConstrainedBox(
            // Forces the column to take at least the full height so the
            // centered layout stays centered on tall screens.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth ?? 520),
                child: Padding(
                  padding: padding ?? AppSpacing.standardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A large icon disc, a bold title, one line, one pill.
                      AppStateDisc(
                        child: effectiveIcon.build(
                          context,
                          color: iconColor ?? AppStateDisc.iconColor(context),
                          size: 34,
                        ),
                      ),
                      AppSpacing.lg.verticalSpace,
                      Text(
                        effectiveText,
                        textAlign: TextAlign.center,
                        // The headline of the state.
                        style:
                            textStyle ??
                            context.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (description != null) ...[
                        AppSpacing.xs.verticalSpace,
                        Text(
                          description!,
                          textAlign: TextAlign.center,
                          style: context.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (onRetrying != null) ...[
                        AppSpacing.xl.verticalSpace,
                        AppActionPill(
                          onTap: onRetrying,
                          label: retryLabel ?? AppStrings.retry,
                          icon: (retryIcon ?? IconSource.svg(AppIcons.refresh))
                              .build(
                                context,
                                color: context.colorScheme.onPrimary,
                                size: 18,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (onRefresh == null) return content;

    // Wrap with RefreshIndicator only when refresh is enabled.
    return AppRefresh(onRefresh: onRefresh!, child: content);
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context)
        .animate()
        .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
        .scaleXY(begin: 0.94, end: 1, duration: 420.ms, curve: AppCurves.reveal)
        .slideY(begin: 0.06, end: 0, duration: 420.ms, curve: AppCurves.reveal);
  }
}
