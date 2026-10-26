part of 'app_scaffold.dart';

/// Small reusable tap wrapper.
///
/// We use [HitTestBehavior.opaque] so the tap target remains easy to hit even
/// when the child is visually small (e.g. an icon).
class _TapArea extends StatelessWidget {
  const _TapArea({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}
