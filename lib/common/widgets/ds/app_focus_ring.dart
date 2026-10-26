import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';

/// Draws the app's focus ring around [child] while something inside it has
/// the keyboard focus — and only when the keyboard is being used.
///
/// A mouse click or a tap moves focus too; a ring after every click is
/// noise. Flutter tracks which one the reader is using
/// ([FocusManager.highlightMode]); the ring shows in
/// [FocusHighlightMode.traditional] — Tab, the arrow keys — only.
///
/// The ring: [AppBorders.focusRing] wide, [AppBorders.focusRingOffset] off
/// the shape, in the primary colour (WCAG 2.2 focus appearance).
class AppFocusRing extends StatefulWidget {
  const AppFocusRing({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadii.md)),
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<AppFocusRing> createState() => _AppFocusRingState();
}

class _AppFocusRingState extends State<AppFocusRing> {
  bool _focused = false;
  bool _keyboard =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onMode);
    super.dispose();
  }

  void _onMode(FocusHighlightMode mode) {
    final keyboard = mode == FocusHighlightMode.traditional;
    if (keyboard != _keyboard) setState(() => _keyboard = keyboard);
  }

  @override
  Widget build(BuildContext context) {
    final show = _focused && _keyboard;
    const offset = AppBorders.focusRingOffset;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      // Called when focus enters or leaves anything inside.
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          widget.child,
          if (show)
            Positioned(
              left: -offset,
              top: -offset,
              right: -offset,
              bottom: -offset,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        widget.borderRadius +
                        const BorderRadius.all(Radius.circular(offset)),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: AppBorders.focusRing,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
