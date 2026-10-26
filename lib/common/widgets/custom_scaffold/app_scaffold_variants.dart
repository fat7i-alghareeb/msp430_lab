part of 'app_scaffold.dart';

/// Feature flags for [AppScaffold].
///
/// The scaffold only builds UI sections whose feature is enabled.
/// This is intentional to avoid creating widgets that are not needed.
enum ScaffoldFeature { appBar }

/// Alignment strategy for the app bar's title block.
///
/// - [centered] uses a [Stack] so the title remains truly centered regardless
///   of leading/actions width.
/// - [start]/[end] align the title within the available expanded space.
enum AppScaffoldTitleAlignment { centered, start, end }

enum AppScaffoldSafeArea { top, bottom, left, right }
