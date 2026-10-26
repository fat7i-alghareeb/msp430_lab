part of 'app_scaffold.dart';

/// End-drawer shell used by [AppScaffold].
///
/// This is intentionally a minimal container:
/// - It only allocates when drawer is enabled.
/// - Width is fixed to 75% of the screen as a consistent compact drawer rule.
///
/// You can evolve this later by adding a content slot/config without changing
/// the scaffold's core behavior.
class _AppEndDrawerShell extends StatelessWidget {
  const _AppEndDrawerShell({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    /// Drawer width rule: 75% of the screen width.
    final width = context.screenWidth * 0.75;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Material(
        color: context.surface,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
