import 'dart:ui';

import '../imports/imports.dart';

/// Overlay banners (glassy toast-like notifications).
///
/// Usage:
/// ```dart
/// // Success
/// showSuccessOverlay(context, 'Profile updated');
///
/// // Error
/// showErrorOverlay(context, 'Something went wrong');
///
/// // Loading (auto-dismiss after 20s fallback)
/// showLoadingOverlay(context, 'Loading...');
///
/// // Custom content
/// showOverlayBanner(
///   context,
///   position: OverlayPosition.top,
///   duration: const Duration(seconds: 3),
///   backgroundColor: context.primary.withValues(alpha: 0.25),
///   prefix: const AppIcon(AppIcons.info, color: Colors.white),
///   content: Text(
///     'Custom banner',
///     style: AppTextStyles.s14w600.copyWith(color: Colors.white),
///   ),
/// );
///
/// // Clear all active overlays
/// clearAllOverlays();
/// ```

/// Overlay position (top or bottom)
enum OverlayPosition { top, bottom }

/// Track active overlays to prevent stacking
final List<OverlayEntry> _activeOverlays = [];

/// Safely clear all overlays
void _clearAllOverlays() {
  for (final entry in _activeOverlays) {
    if (entry.mounted) entry.remove();
  }
  _activeOverlays.clear();
}

/// Core function to show any overlay banner
bool showOverlayBanner(
  BuildContext context, {
  required Widget content,
  Color backgroundColor = Colors.black87,
  OverlayPosition position = OverlayPosition.top,
  Duration duration = const Duration(seconds: 3),
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
  double? borderRadius,
  bool dismissible = true,
  Widget? prefix,
}) {
  if (!context.mounted) return false;

  _clearAllOverlays();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      final topSafe = context.topPadding;
      final bottomSafe = context.bottomPadding;

      return Positioned(
        top: position == OverlayPosition.top ? topSafe + 20 : null,
        bottom: position == OverlayPosition.bottom ? bottomSafe + 20 : null,
        left: 0,
        right: 0,
        child: _AnimatedOverlayContainer(
          entry: entry,
          onDismiss: () {
            if (entry.mounted) {
              entry.remove();
              _activeOverlays.remove(entry);
            }
          },
          dismissible: dismissible,
          autoDisappear: duration > Duration.zero,
          margin: margin ?? AppSpacing.horizontal,
          padding: padding ?? AppSpacing.standardPadding,
          borderRadius: BorderRadius.circular((borderRadius ?? AppRadii.lg)),
          backgroundColor: backgroundColor,
          prefix: prefix,
          content: content,
        ),
      );
    },
  );

  overlay.insert(entry);
  _activeOverlays.add(entry);

  if (duration > Duration.zero) {
    Future.delayed(duration, () async {
      final state = _AnimatedOverlayContainer.globalKeys[entry];
      await state?.reverseAndRemove();
    });
  }

  return true;
}

/// Animated container widget
class _AnimatedOverlayContainer extends StatefulWidget {
  final OverlayEntry entry;
  final VoidCallback onDismiss;
  final bool dismissible;
  final bool autoDisappear;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color backgroundColor;
  final Widget? prefix;
  final Widget content;

  static final Map<OverlayEntry, _AnimatedOverlayContainerState> globalKeys =
      {};

  const _AnimatedOverlayContainer({
    required this.entry,
    required this.onDismiss,
    required this.dismissible,
    required this.autoDisappear,
    required this.margin,
    required this.padding,
    required this.borderRadius,
    required this.backgroundColor,
    this.prefix,
    required this.content,
  });

  @override
  State<_AnimatedOverlayContainer> createState() =>
      _AnimatedOverlayContainerState();
}

class _AnimatedOverlayContainerState extends State<_AnimatedOverlayContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  static const double _dismissVelocityThreshold = 600;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.slow,
      reverseDuration: AppDurations.slow,
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _AnimatedOverlayContainer.globalKeys[widget.entry] = this;
    _controller.forward();
  }

  Future<void> reverseAndRemove() async {
    try {
      await _controller.reverse();
      if (mounted) widget.onDismiss();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _AnimatedOverlayContainer.globalKeys.remove(widget.entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = widget.backgroundColor.a < 1
        ? widget.backgroundColor
        : widget.backgroundColor.withValues(alpha: 0.48);

    final Widget banner = Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Padding(
            padding: widget.margin,
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius,
                    color: effectiveBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: context.onSurface.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (widget.prefix != null) widget.prefix!,
                      if (widget.prefix != null) 12.horizontalSpace,
                      Expanded(child: widget.content),
                      if (widget.dismissible && !widget.autoDisappear)
                        Row(
                          children: [
                            6.horizontalSpace,
                            GestureDetector(
                              onTap: reverseAndRemove,
                              child: AppIcon(
                                AppIcons.close,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.dismissible) return banner;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: reverseAndRemove,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        final velocity = details.primaryVelocity!;
        final isSwipeUp = velocity < -_dismissVelocityThreshold;
        if (isSwipeUp) reverseAndRemove();
      },
      child: banner,
    );
  }
}

/// Clear all overlays manually
void clearAllOverlays() => _clearAllOverlays();

/// ✅ Success overlay
bool showSuccessOverlay(BuildContext context, String message) {
  return showOverlayBanner(
    context,
    backgroundColor: AppColors.success,
    prefix: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      alignment: Alignment.center,
      child: const AppIcon(AppIcons.check, color: AppColors.success, size: 18),
    ),
    content: Text(
      message,
      style: AppTextStyles.s14w600.copyWith(color: Colors.white),
      textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
    ),
  );
}

/// ❌ Error overlay
bool showErrorOverlay(BuildContext context, String message) {
  return showOverlayBanner(
    context,
    backgroundColor: AppColors.error.withValues(alpha: 0.3),
    prefix: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      alignment: Alignment.center,
      child: const AppIcon(AppIcons.close, color: AppColors.error, size: 18),
    ),
    content: Text(
      message,
      style: AppTextStyles.s14w600.copyWith(color: Colors.white),
      textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
    ),
  );
}

/// ⏳ Loading overlay
bool showLoadingOverlay(BuildContext context, String message) {
  return showOverlayBanner(
    context,
    backgroundColor: context.primary.withValues(alpha: 0.72),
    duration: const Duration(
      seconds: 20,
    ), // Auto-dismiss after 20 seconds as fallback
    dismissible: false, // Can't be dismissed manually during loading
    prefix: const SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    ),
    content: Text(
      message,
      style: AppTextStyles.s14w600.copyWith(color: Colors.white),
      textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
    ),
  );
}
