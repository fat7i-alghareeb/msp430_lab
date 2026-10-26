import '../imports/imports.dart';

/// AppDialog
/// ---------
///
/// Standardized dialog used across the app.
///
/// Use [title] + [message] for simple dialogs. Use [child] when you need a
/// custom layout (e.g., form fields, rich content) while keeping the same
/// dialog chrome.
///
/// Usage:
/// ```dart
/// await AppDialog.show(
///   context,
///   dialog: AppDialog.basic(
///     title: AppStrings.somethingWentWrong,
///     message: AppStrings.unknownError,
///     primaryAction: AppDialogAction.primary(
///       label: AppStrings.retry,
///       onPressed: () => cubit.load(),
///     ),
///   ),
/// );
/// ```
class AppDialog extends StatelessWidget {
  const AppDialog._({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.titleStyle,
    this.messageStyle,
    this.child,
    this.primaryAction,
    this.secondaryAction,
    this.actions,
    this.maxWidth,
    this.padding,
    this.backgroundColor,
    // DESIGN_SYSTEM.md: dialogs use radius.lg (18) and cap at 320dp.
    this.borderRadius = AppRadii.lg,
    this.barrierDismissible = true,
  });

  /// Basic dialog with optional icon/title/message and actions.
  factory AppDialog.basic({
    Key? key,
    IconSource? icon,
    String? title,
    String? message,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    Widget? child,
    AppDialogAction? primaryAction,
    AppDialogAction? secondaryAction,
    List<AppDialogAction>? actions,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    double borderRadius = AppRadii.lg,
    bool barrierDismissible = true,
  }) {
    return AppDialog._(
      key: key,
      icon: icon,
      title: title,
      message: message,
      titleStyle: titleStyle,
      messageStyle: messageStyle,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      actions: actions,
      maxWidth: maxWidth,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      barrierDismissible: barrierDismissible,
      child: child,
    );
  }

  /// Shows a modal dialog using a consistent chrome.
  ///
  /// [useRootNavigator] pushes the dialog above nested navigators (e.g.
  /// go_router ShellRoute / nested Navigator). This avoids cases where the
  /// dialog appears under overlays or is dismissed unexpectedly.
  ///
  /// [barrierDismissible] controls whether tapping outside the dialog closes
  /// it. You can override it per call or set a default per dialog instance.
  static Future<T?> show<T>(
    BuildContext context, {
    required AppDialog dialog,
    bool? barrierDismissible,
    bool useRootNavigator = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible ?? dialog.barrierDismissible,
      barrierColor: barrierColor,
      builder: (context) => dialog,
    );
  }

  final IconSource? icon;
  final String? title;
  final String? message;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final Widget? child;

  final AppDialogAction? primaryAction;
  final AppDialogAction? secondaryAction;
  final List<AppDialogAction>? actions;

  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;

  final bool barrierDismissible;

  List<AppDialogAction> _resolveActions() {
    final resolved = <AppDialogAction>[];

    // Convention: secondary (cancel/back) comes before primary — except on
    // Windows, where the confirming button comes first (Flutter's platform
    // idioms guide, «Horizontal button order»).
    final confirmFirst = AppPlatform.isWindows;
    if (confirmFirst && primaryAction != null) resolved.add(primaryAction!);
    if (secondaryAction != null) resolved.add(secondaryAction!);
    if (!confirmFirst && primaryAction != null) resolved.add(primaryAction!);

    // Additional actions are appended after the primary/secondary pair.
    if (actions != null && actions!.isNotEmpty) {
      resolved.addAll(actions!);
    }

    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final colors = context.colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    final effectiveTitle = title?.trim();
    final effectiveMessage = message?.trim();

    final resolvedActions = _resolveActions();

    final body = Material(
      color: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              // Constraining width keeps the dialog readable on tablets/desktop.
              constraints: BoxConstraints(maxWidth: maxWidth ?? 520),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor ?? colors.surface,
                  borderRadius: radius,
                ),
                padding: padding ?? AppSpacing.standardPadding,
                margin: AppSpacing.standardPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!.build(
                        context,
                        color: colors.onSurface.withValues(alpha: 0.65),
                        size: 56,
                      ),
                      AppSpacing.md.verticalSpace,
                    ],
                    if (effectiveTitle?.isNotEmpty == true) ...[
                      Text(
                        effectiveTitle!,
                        textAlign: TextAlign.center,
                        style:
                            titleStyle ??
                            AppTextStyles.s20w700.copyWith(
                              color: colors.onSurface,
                            ),
                      ),
                    ],
                    if (effectiveMessage?.isNotEmpty == true) ...[
                      if (effectiveTitle?.isNotEmpty == true)
                        AppSpacing.sm.verticalSpace
                      else
                        AppSpacing.xs.verticalSpace,
                      Text(
                        effectiveMessage!,
                        textAlign: TextAlign.center,
                        style:
                            messageStyle ??
                            AppTextStyles.s16w400.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.82),
                            ),
                      ),
                    ],
                    if (child != null) ...[AppSpacing.lg.verticalSpace, child!],
                    if (resolvedActions.isNotEmpty) ...[
                      AppSpacing.xl.verticalSpace,
                      ...resolvedActions.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: a.build(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // PopScope is used instead of WillPopScope to support Android predictive
    // back gestures.
    return PopScope(canPop: barrierDismissible, child: body);
  }
}

/// Describes a single dialog action.
class AppDialogAction {
  const AppDialogAction._({
    required this.label,
    required this.variant,
    required this.fill,
    this.icon,
    this.labelStyle,
    this.onPressed,
  });

  factory AppDialogAction.primary({
    required String label,
    VoidCallback? onPressed,
    IconSource? icon,
    TextStyle? labelStyle,
  }) {
    return AppDialogAction._(
      label: label,
      variant: AppButtonVariant.primary,
      fill: AppButtonFill.gradient,
      icon: icon,
      labelStyle: labelStyle,
      onPressed: onPressed,
    );
  }

  /// The way out: "Cancel", "Exit", "Back". Red (the error variant): it is a
  /// real action, and grey is reserved for buttons that are inactive
  /// (`AppButtonVariant.grey`).
  factory AppDialogAction.secondary({
    required String label,
    VoidCallback? onPressed,
    IconSource? icon,
    TextStyle? labelStyle,
  }) {
    return AppDialogAction._(
      label: label,
      variant: AppButtonVariant.error,
      fill: AppButtonFill.solid,
      icon: icon,
      labelStyle: labelStyle,
      onPressed: onPressed,
    );
  }
  factory AppDialogAction.danger({
    required String label,
    VoidCallback? onPressed,
    IconSource? icon,
    TextStyle? labelStyle,
  }) {
    return AppDialogAction._(
      label: label,
      variant: AppButtonVariant.error,
      fill: AppButtonFill.solid,
      icon: icon,
      labelStyle: labelStyle,
      onPressed: onPressed,
    );
  }
  factory AppDialogAction.success({
    required String label,
    VoidCallback? onPressed,
    IconSource? icon,
    TextStyle? labelStyle,
  }) {
    return AppDialogAction._(
      label: label,
      variant: AppButtonVariant.success,
      fill: AppButtonFill.solid,
      icon: icon,
      labelStyle: labelStyle,
      onPressed: onPressed,
    );
  }

  final String label;
  final AppButtonVariant variant;
  final AppButtonFill fill;
  final IconSource? icon;
  final TextStyle? labelStyle;
  final VoidCallback? onPressed;

  Widget build(BuildContext context) {
    final child = icon == null
        ? AppButtonChild.label(label, textStyle: labelStyle)
        : AppButtonChild.labelIcon(
            label: label,
            icon: icon!,
            textStyle: labelStyle,
          );

    return AppButton.variant(
      variant: variant,
      fill: fill,
      onTap: onPressed,
      child: child,
    );
  }
}
