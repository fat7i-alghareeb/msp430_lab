import '../imports/imports.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// FailedStateWidget
/// ---------------
///
/// A full-height failure state widget.
///
/// Features:
/// - Centered content
/// - Customizable [icon] via [IconSource]
/// - Optional pull-to-refresh (wraps content with [RefreshIndicator])
/// - Optional retry button (primary gradient) using [AppButton]
/// - Optional `details` text for debugging (kept visually subtle)
///
/// Usage:
/// ```dart
/// FailedStateWidget(
///   message: errorMessage,
///   onRetrying: () => cubit.load(),
/// )
///
/// // With details for debugging:
/// FailedStateWidget(
///   message: AppStrings.somethingWentWrong,
///   details: exception.toString(),
///   onRetrying: () => cubit.load(),
/// )
/// ```
class FailedStateWidget extends StatelessWidget {
  const FailedStateWidget({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.details,
    this.onRefresh,
    this.onRetrying,
    this.retryLabel,
    this.retryIcon,
    // DESIGN_SYSTEM.md: the state icon is 28, not a hero graphic.
    this.iconSize = AppIconSizes.emptyState,
    this.padding,
    this.maxWidth,
    this.titleStyle,
    this.messageStyle,
    this.detailsStyle,
    this.iconColor,
  });

  final IconSource? icon;

  final String? title;
  final String? message;
  final String? details;

  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetrying;

  final String? retryLabel;
  final IconSource? retryIcon;

  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final TextStyle? detailsStyle;

  final Color? iconColor;

  Widget _buildBody(BuildContext context) {
    final colors = context.colorScheme;

    final effectiveIcon =
        icon ?? IconSource.svg(AppIcons.alert, size: iconSize);

    final effectiveTitle = title?.trim().isNotEmpty == true
        ? title!
        : AppStrings.somethingWentWrong;

    final effectiveMessage = message?.trim().isNotEmpty == true
        ? message!
        : AppStrings.unknownError;

    // Enable pull-to-refresh even when the error UI doesn't overflow.
    final physics = onRefresh != null
        ? const AlwaysScrollableScrollPhysics()
        : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

    final content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics,
          child: ConstrainedBox(
            // Keeps the state vertically centered by filling the viewport.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth ?? 560),
                child: Padding(
                  padding: padding ?? AppSpacing.standardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A large icon disc, a bold title, one line, one pill.
                      AppStateDisc(
                        isError: true,
                        child: effectiveIcon.build(
                          context,
                          color:
                              iconColor ??
                              AppStateDisc.iconColor(context, isError: true),
                          size: 34,
                        ),
                      ),
                      AppSpacing.lg.verticalSpace,
                      Text(
                        effectiveTitle,
                        textAlign: TextAlign.center,
                        style:
                            // titleSmall — not a display heading.
                            titleStyle ?? context.titleSmall,
                      ),
                      AppSpacing.sm.verticalSpace,
                      Text(
                        effectiveMessage,
                        textAlign: TextAlign.center,
                        style:
                            messageStyle ??
                            context.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                      if (details?.trim().isNotEmpty == true) ...[
                        AppSpacing.md.verticalSpace,
                        Text(
                          details!,
                          textAlign: TextAlign.center,
                          style:
                              detailsStyle ??
                              AppTextStyles.s12w400.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.55),
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
