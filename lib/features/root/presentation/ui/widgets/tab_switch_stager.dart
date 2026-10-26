import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService;

import '../../../../../common/widgets/nav_bar_visibility.dart';
import '../../../../../utils/constants/design_constants.dart';
import '../../../../../utils/helpers/app_strings.dart';
import 'nav_bar/app_bottom_nav.dart';
import 'nav_bar/navigation_controller.dart';

/// Stages a tab change asked for from INSIDE a page — «عرض الكل», a section
/// tile, «back to the tab» from a pushed page — so it reads as switching
/// tabs rather than opening a page:
///
/// 1. the bar comes back if it was docked;
/// 2. its pill slides to the new tab;
/// 3. a moment later the page cross-fades (`RootTabStack`);
/// 4. «انتقلت إلى الأخبار» shows above the bar, and is announced.
///
/// Under reduced motion the tab changes at once and the sentence is still
/// shown and announced. A tap on the bar itself is never staged: the reader
/// already knows where they went.
class TabSwitchStager extends StatefulWidget {
  const TabSwitchStager({
    super.key,
    required this.controller,
    required this.labels,
    required this.child,
    this.visibility,
  });

  final NavigationController controller;

  /// Each tab's name, in the bar's order.
  final List<String> labels;
  final NavBarVisibility? visibility;
  final Widget child;

  @override
  State<TabSwitchStager> createState() => _TabSwitchStagerState();
}

class _TabSwitchStagerState extends State<TabSwitchStager>
    with TickerProviderStateMixin {
  // Made in `initState`, not lazily: a shell closed before any page asked
  // for a tab would first create them in `dispose`, against a deactivated
  // tree.
  late final AnimationController _handoff;
  late final AnimationController _toast;

  OverlayEntry? _toastEntry;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _handoff = AnimationController(
      vsync: this,
      duration: AppDurations.tabHandoff,
    );
    _toast = AnimationController(vsync: this, duration: AppDurations.tabToast);
    widget.controller.hasStager = true;
    widget.controller.bodyRequests.addListener(_onRequest);
  }

  @override
  void didUpdateWidget(TabSwitchStager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    oldWidget.controller
      ..hasStager = false
      ..bodyRequests.removeListener(_onRequest);
    widget.controller
      ..hasStager = true
      ..bodyRequests.addListener(_onRequest);
  }

  @override
  void dispose() {
    widget.controller
      ..hasStager = false
      ..bodyRequests.removeListener(_onRequest);
    _removeToast();
    _handoff.dispose();
    _toast.dispose();
    super.dispose();
  }

  String _labelOf(int index) =>
      index >= 0 && index < widget.labels.length ? widget.labels[index] : '';

  Future<void> _onRequest() async {
    final request = widget.controller.bodyRequests.value;
    if (request == null || !mounted) return;
    final run = ++_run;
    final index = request.index;
    final label = _labelOf(index);
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    widget.visibility?.show();

    if (!reduced) {
      widget.controller.highlight(index);
      if (!await _play(_handoff)) return;
      if (run != _run || !mounted) return;
    }

    widget.controller.setIndex(index);
    _showToast(label, reduced: reduced);
  }

  /// Plays [controller] from the start; false when it was cut short (the
  /// shell went away, or a newer request took over).
  Future<bool> _play(AnimationController controller) async {
    try {
      await controller.forward(from: 0).orCancel;
      return mounted;
    } on TickerCanceled {
      return false;
    }
  }

  // --------------------------------------------------------------- the toast

  void _showToast(String label, {required bool reduced}) {
    if (label.isEmpty || !mounted) return;
    final sentence = AppStrings.navSwitchedTo(label);
    SemanticsService.sendAnnouncement(
      View.of(context),
      sentence,
      Directionality.of(context),
    );
    _removeToast();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _toastEntry = OverlayEntry(
      builder: (context) => _SwitchToast(
        animation: _toast,
        text: sentence,
        bottom: AppBottomNav.listBottomPadding(context) - AppSpacing.sm,
      ),
    );
    overlay.insert(_toastEntry!);
    _toast.forward(from: reduced ? 0.12 : 0).whenCompleteOrCancel(() {
      if (mounted) _removeToast();
    });
  }

  void _removeToast() {
    _toastEntry?.remove();
    _toastEntry?.dispose();
    _toastEntry = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// «انتقلت إلى الأخبار» — the snackbar's dark pill, just above the bar. It
/// rises in, holds, and fades away on its own.
class _SwitchToast extends StatelessWidget {
  const _SwitchToast({
    required this.animation,
    required this.text,
    required this.bottom,
  });

  final Animation<double> animation;
  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: bottom,
      child: IgnorePointer(
        child: ExcludeSemantics(
          // Announced once by the stager; not read again as a node.
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final v = animation.value;
              // Clamped: (1 - 0.85) / 0.15 lands a hair above 1 in floating
              // point, which a curve refuses.
              final shown = v < 0.12
                  ? Curves.easeOut.transform((v / 0.12).clamp(0.0, 1.0))
                  : v > 0.85
                  ? 1 -
                        Curves.easeIn.transform(
                          ((v - 0.85) / 0.15).clamp(0.0, 1.0),
                        )
                  : 1.0;
              return Opacity(
                opacity: shown,
                child: Transform.translate(
                  offset: Offset(0, (1 - shown) * 8),
                  child: child,
                ),
              );
            },
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.onSurface,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
