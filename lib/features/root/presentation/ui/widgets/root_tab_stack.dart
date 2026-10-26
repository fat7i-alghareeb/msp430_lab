import 'package:flutter/material.dart';

import '../../../../../utils/constants/design_constants.dart';
import 'nav_bar/navigation_controller.dart';

/// The four root tabs, and the cross-fade between them.
///
/// Every tab keeps its scroll position, its filters and its
/// loaded data while another one is showing — holds by construction: a tab
/// is built the first time it is opened and is never thrown away after
/// that. A tab that has not been opened yet is not built at all, so the
/// stores tab asks nothing of the server until the reader goes there.
///
/// The handover is a **cross-fade**: the tab being left and the tab arriving
/// dissolve into each other over the same [AppDurations.tabSwitch], and
/// nothing moves. What says «another
/// tab» is the pill sliding in the bar, not the page. It replaced a
/// circle revealed from the tab's icon
/// and, before that, a fade through with a 96% settle that read like a new
/// page opening.
///
/// Every tab is wrapped in the SAME chain of widgets whatever its role, and
/// only the animations handed to them change: swapping a wrapper in for the
/// handover would remount the tab under it — its bloc, its first request —
/// which is the very thing this stack exists to prevent. The arriving tab is painted last;
/// a keyed reorder moves it without remounting it.
class RootTabStack extends StatefulWidget {
  const RootTabStack({super.key, required this.controller, required this.tabs});

  final NavigationController controller;

  /// One builder per tab, in the order of the navigation bar.
  final List<WidgetBuilder> tabs;

  @override
  State<RootTabStack> createState() => _RootTabStackState();
}

class _RootTabStackState extends State<RootTabStack>
    with SingleTickerProviderStateMixin {
  // Made in `initState`, not lazily: at rest nothing reads it, and a
  // controller first created in `dispose` asks a deactivated tree for its
  // ticker mode.
  late final AnimationController _handover;

  late final Animation<double> _inOpacity = CurvedAnimation(
    parent: _handover,
    curve: Curves.easeInOut,
  );

  late final Animation<double> _outOpacity = ReverseAnimation(_inOpacity);

  late int _current = widget.controller.currentIndex;

  /// The tab fading out, while it is.
  int? _outgoing;

  /// Every tab opened so far — built, and kept.
  late final Set<int> _visited = <int>{_current};

  @override
  void initState() {
    super.initState();
    _handover = AnimationController(
      vsync: this,
      duration: AppDurations.tabSwitch,
      // At rest the handover is «finished»: the active tab fully shown.
      value: 1,
    )..addStatusListener(_onHandoverStatus);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(RootTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
    _onControllerChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _handover.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final next = widget.controller.currentIndex;
    // A tap on the active tab only bumps the reselect token; the tab itself
    // scrolls to the top. A highlight alone (the bar running ahead) changes
    // nothing here either.
    if (next == _current || !mounted) return;

    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    setState(() {
      _outgoing = reducedMotion ? null : _current;
      _current = next;
      _visited.add(next);
    });

    if (reducedMotion) {
      _handover.value = 1;
    } else {
      _handover.forward(from: 0);
    }
  }

  void _onHandoverStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null && mounted) {
      setState(() => _outgoing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Painted in this order: the tabs at rest, the one leaving, and the one
    // arriving on top.
    final order = <int>[
      for (var i = 0; i < widget.tabs.length; i++)
        if (_visited.contains(i) && i != _current && i != _outgoing) i,
      ?_outgoing,
      _current,
    ];
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[for (final i in order) _tab(context, i)],
    );
  }

  Widget _tab(BuildContext context, int index) {
    final isActive = index == _current;
    final isLeaving = index == _outgoing;
    final onStage = isActive || isLeaving;
    final switching = _outgoing != null;

    final Animation<double> opacity = !switching
        ? kAlwaysCompleteAnimation
        : isActive
        ? _inOpacity
        : isLeaving
        ? _outOpacity
        : kAlwaysCompleteAnimation;

    return KeyedSubtree(
      key: ValueKey<int>(index),
      child: Offstage(
        offstage: !onStage,
        // A tab off screen is not animating anything the reader could see.
        child: TickerMode(
          enabled: onStage,
          child: IgnorePointer(
            // The tab fading out takes no taps meant for the new one.
            ignoring: !isActive,
            child: ExcludeSemantics(
              excluding: !isActive,
              // Only the tab on screen flies. Every tab stays mounted
              //, so every tab's heroes sit in this one route: home's
              // banner and the news tab both tag a news item `news-<id>`,
              // home's listings and the marketplace share
              // `product-market-<id>`, and opening any page found two heroes
              // with one tag and threw.
              child: HeroMode(
                enabled: isActive,
                child: FadeTransition(
                  opacity: opacity,
                  child: RepaintBoundary(child: widget.tabs[index](context)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
