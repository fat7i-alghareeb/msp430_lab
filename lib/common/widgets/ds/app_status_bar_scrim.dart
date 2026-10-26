import 'package:flutter/material.dart';

/// A ground-coloured band behind the status bar, over a page that draws
/// edge to edge.
///
/// The inner pages open on a picture that runs under the status bar — right
/// while it is a picture. Once it has scrolled away the page's TEXT ran under
/// the clock and the battery. The band fades in when
/// [controller] has scrolled past [showAfter] — the point where the picture's
/// bottom reaches the status bar — and the content scrolls under it.
class AppStatusBarScrim extends StatelessWidget {
  const AppStatusBarScrim({
    super.key,
    required this.controller,
    required this.showAfter,
    required this.child,
  });

  final ScrollController controller;

  /// The scroll offset past which the band shows — usually the height of
  /// the picture minus the status bar's.
  final double showAfter;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    if (inset == 0) return child;
    final theme = Theme.of(context);

    return Stack(
      children: <Widget>[
        child,
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          height: inset,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final shows =
                    controller.hasClients && controller.offset > showAfter;
                return AnimatedOpacity(
                  opacity: shows ? 1 : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  child: ColoredBox(color: theme.scaffoldBackgroundColor),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
