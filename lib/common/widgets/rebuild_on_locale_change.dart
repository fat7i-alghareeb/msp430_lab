import 'package:flutter/widgets.dart';

/// Rebuilds everything under it when [locale] changes — in place.
///
/// Every word on screen is read through `AppStrings` when its widget BUILDS,
/// and a widget with no other reason to rebuild keeps the language it was
/// built in. Without this, switching language turned the direction and a
/// few rows, and left the rest of the screen in the old language.
///
/// So a new language marks every element below for a rebuild. Nothing is
/// recreated: every screen keeps its state and the navigation stack stays
/// where it was. Only the words change.
class RebuildOnLocaleChange extends StatefulWidget {
  const RebuildOnLocaleChange({
    super.key,
    required this.locale,
    required this.child,
  });

  final Locale locale;
  final Widget child;

  @override
  State<RebuildOnLocaleChange> createState() => _RebuildOnLocaleChangeState();
}

class _RebuildOnLocaleChangeState extends State<RebuildOnLocaleChange> {
  @override
  void didUpdateWidget(RebuildOnLocaleChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale == widget.locale) return;

    // After this frame: the new language is loaded by then, and the
    // elements rebuilt in it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
