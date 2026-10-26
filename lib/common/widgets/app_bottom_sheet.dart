import '../imports/imports.dart';

/// AppBottomSheet
/// -------------
///
/// Standardized bottom sheet layout used across the app.
///
/// Usage:
/// ```dart
/// await AppBottomSheet.show(
///   context,
///   sheet: AppBottomSheet.basic(
///     title: 'Filter',
///     child: FilterForm(),
///   ),
/// );
/// ```
///
/// This widget focuses on presentation. Showing it is done via the
/// [AppBottomSheet.show] helper.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet._({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.titleStyle,
    this.header,
    this.actions,
    this.padding,
    this.backgroundColor,
    // DESIGN_SYSTEM.md: sheets use radius.sheet.
    this.borderRadius = AppRadii.sheet,
    this.showDragHandle = true,
    this.unfocusOnTapOutside = true,
    this.scrollable = true,
  });

  /// A simple, common bottom sheet layout.
  factory AppBottomSheet.basic({
    Key? key,
    required Widget child,
    String? title,
    String? titleIcon,
    TextStyle? titleStyle,
    Widget? header,
    List<Widget>? actions,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    double borderRadius = AppRadii.sheet,
    bool showDragHandle = true,
    bool unfocusOnTapOutside = true,
    bool scrollable = true,
  }) {
    return AppBottomSheet._(
      key: key,
      title: title,
      titleIcon: titleIcon,
      titleStyle: titleStyle,
      header: header,
      actions: actions,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      showDragHandle: showDragHandle,
      unfocusOnTapOutside: unfocusOnTapOutside,
      scrollable: scrollable,
      child: child,
    );
  }

  /// Shows a modal bottom sheet using a consistent chrome.
  ///
  /// [useRootNavigator] pushes the sheet above nested navigators (e.g.
  /// go_router ShellRoute / nested Navigator) so it behaves consistently.
  /// The widest a sheet gets when it is shown as a dialog.
  static const double dialogMaxWidth = 720;

  /// Sheets become centred dialogs in expanded windows (840dp and wider):
  /// a sheet rising from the bottom of a desktop window, 1200dp wide, is
  /// the wrong shape for a choice (`docs/RESPONSIVE.md`).
  static bool presentsAsDialog(BuildContext context) =>
      AppLayoutScope.maybeOf(context)?.isExpandedUp ?? false;

  /// Shows [builder]'s content as a bottom sheet in compact and medium
  /// windows, and as a centred dialog of at most [maxDialogWidth] in
  /// expanded ones. The same widget either way: it reads
  /// [AppSheetPresentation.presentsAsDialog] to drop its handle and round all four
  /// corners.
  static Future<T?> showAdaptive<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool useRootNavigator = true,
    bool isScrollControlled = true,
    bool enableDrag = true,
    bool isDismissible = true,
    bool useSafeArea = false,
    Color? barrierColor,
    double maxDialogWidth = dialogMaxWidth,
    bool childPaintsSurface = false,
  }) {
    if (presentsAsDialog(context)) {
      return showDialog<T>(
        context: context,
        useRootNavigator: useRootNavigator,
        barrierDismissible: isDismissible,
        barrierColor: barrierColor,
        builder: (context) => AppSheetPresentation(
          isDialog: true,
          child: Dialog(
            // An [AppBottomSheet] paints its own surface; plain content gets
            // the dialog's.
            backgroundColor: childPaintsSurface ? Colors.transparent : null,
            elevation: childPaintsSurface ? 0 : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxDialogWidth,
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: Builder(builder: builder),
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      useSafeArea: useSafeArea,
      barrierColor: barrierColor,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: builder,
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required AppBottomSheet sheet,
    bool useRootNavigator = true,
    bool isScrollControlled = true,
    bool enableDrag = true,
    bool isDismissible = true,
    Color? barrierColor,
  }) {
    if (presentsAsDialog(context)) {
      return showAdaptive<T>(
        context,
        builder: (_) => sheet,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        barrierColor: barrierColor,
        childPaintsSurface: true,
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      barrierColor: barrierColor,
      backgroundColor: Colors.transparent,
      // The sheet draws its own handle. The theme's (`showDragHandle: true`)
      // was drawn as well, on this transparent modal — a second handle
      // floating on the scrim above the sheet.
      showDragHandle: false,
      builder: (context) => sheet,
    );
  }

  final Widget child;
  final String? title;

  /// An icon in a `primaryContainer` disc before the title.
  final String? titleIcon;
  final TextStyle? titleStyle;
  final Widget? header;
  final List<Widget>? actions;

  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;

  final bool showDragHandle;
  final bool unfocusOnTapOutside;
  final bool scrollable;

  /// The theme's handle — `34×4`, `outlineVariant` —
  /// so every sheet in the app carries the same one.
  Widget _dragHandle(BuildContext context) {
    final theme = Theme.of(context).bottomSheetTheme;
    final size = theme.dragHandleSize ?? const Size(34, 4);

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.height),
        color: theme.dragHandleColor ?? context.colorScheme.outlineVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asDialog = AppSheetPresentation.presentsAsDialog(context);
    // A dialog sits above the keyboard on its own.
    final bottomInset = asDialog
        ? 0.0
        : MediaQuery.of(context).viewInsets.bottom;
    final radius = asDialog
        ? BorderRadius.circular(AppRadii.lg)
        : BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
          );

    final body = Material(
      color: backgroundColor ?? context.colorScheme.surface,
      borderRadius: radius,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: padding ?? AppSpacing.standardPadding,
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A dialog is not dragged away; it has no handle.
                if (showDragHandle && !asDialog) _dragHandle(context),
                if (header != null) ...[AppSpacing.md.verticalSpace, header!],
                if (title?.trim().isNotEmpty == true) ...[
                  AppSpacing.md.verticalSpace,
                  if (titleIcon == null)
                    Text(
                      title!,
                      textAlign: TextAlign.center,
                      style:
                          titleStyle ??
                          AppTextStyles.s16w400.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: AppIcon(
                            titleIcon!,
                            color: context.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        AppSpacing.md.horizontalSpace,
                        Expanded(
                          child: Text(
                            title!,
                            style:
                                titleStyle ??
                                AppTextStyles.s16w400.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                ],
                if (title?.trim().isNotEmpty == true || header != null)
                  AppSpacing.lg.verticalSpace,

                // `scrollable` allows large content (forms) without overflow.
                if (scrollable)
                  Flexible(child: SingleChildScrollView(child: child))
                else
                  child,

                if (actions != null && actions!.isNotEmpty) ...[
                  AppSpacing.lg.verticalSpace,
                  ...actions!,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Tap outside content to dismiss keyboard (common in forms).
    final maybeUnfocus = unfocusOnTapOutside
        ? GestureDetector(onTap: context.unfocus, child: body)
        : body;

    return asDialog ? maybeUnfocus : SafeArea(child: maybeUnfocus);
  }
}

/// Tells a sheet whether it is being shown as a centred dialog
/// (`AppBottomSheet.showAdaptive`) rather than from the bottom edge.
class AppSheetPresentation extends InheritedWidget {
  const AppSheetPresentation({
    super.key,
    required this.isDialog,
    required super.child,
  });

  final bool isDialog;

  static bool presentsAsDialog(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppSheetPresentation>()
          ?.isDialog ??
      false;

  @override
  bool updateShouldNotify(AppSheetPresentation oldWidget) =>
      isDialog != oldWidget.isDialog;
}
