// 🐦 Flutter imports:
import 'package:flutter/material.dart';

import '../../common/imports/imports.dart'
    show AppStrings, EmptyStateWidget, FailedStateWidget;
import '../../common/widgets/ds/app_motion.dart' show AppRefresh;
import '../../common/widgets/main_loading_progress.dart'
    show MainLoadingProgress;
import '../../core/utils/bloc_status.dart' show BlocStatus, BlocStatusPatterns;

class StatusBuilder<T> extends StatelessWidget {
  const StatusBuilder({
    super.key,
    required this.success,
    this.loading,
    this.init,
    this.empty,
    this.isEmpty,
    this.onError,
    this.onRefresh,
    required this.state,
    this.errorMessage,
    this.showLoadingProgress = true,
    this.showInitWidget = true,
  });

  final BlocStatus<T> state;
  final Widget Function()? loading;
  final Widget Function()? init;
  final Widget Function()? empty;
  final bool Function(T data)? isEmpty;
  final Widget Function(T data) success;
  final Function()? onError;
  final Future<void> Function()? onRefresh;
  final String? errorMessage;
  final bool showLoadingProgress;
  final bool showInitWidget;

  @override
  Widget build(BuildContext context) {
    late final Widget next;
    bool wrapWithRefresh = onRefresh != null;

    defaultLoading() => showLoadingProgress
        ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Center(child: MainLoadingProgress())],
          )
        : const SizedBox.shrink();

    defaultInit() => const SizedBox.shrink();

    defaultEmpty() => EmptyStateWidget(
      text: AppStrings.emptyStateNoData,
      onRefresh: onRefresh,
      onRetrying: onError,
    );

    state.when(
      initial: () => next = init?.call() ?? defaultInit(),
      loading: () => next = loading?.call() ?? defaultLoading(),
      success: (data) {
        final isEmptyNow = isEmpty?.call(data) ?? false;
        if (isEmptyNow) {
          next = empty?.call() ?? defaultEmpty();
          wrapWithRefresh = false;
          return;
        }
        next = success(data);
      },
      failure: (message) {
        wrapWithRefresh = false;
        return next = FailedStateWidget(
          message: errorMessage ?? message,
          onRefresh: onRefresh,
          onRetrying: onError,
        );
      },
    );

    if (!wrapWithRefresh) return next;

    final Widget scrollableChild;
    if (next is ScrollView || next is SingleChildScrollView) {
      scrollableChild = next;
    } else {
      scrollableChild = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: next,
      );
    }

    return AppRefresh(onRefresh: onRefresh!, child: scrollableChild);
  }
}
