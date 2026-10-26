import 'package:flutter/material.dart';

import '../../../../../utils/helpers/app_strings.dart';
import '../../states/tour_controller.dart';

/// The self-explaining tour: the step's title and sentence, the controls to
/// step and pause, and one progress line per step.
class TourBar extends StatelessWidget {
  const TourBar({super.key, required this.tour, this.compact = false});

  final TourController tour;

  /// The phone: at most three lines of text.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: tour,
      builder: (context, _) {
        final step = tour.current;
        if (step == null) return const SizedBox.shrink();
        return Material(
          color: Colors.white.withValues(alpha: 0.96),
          elevation: 3,
          shadowColor: const Color(0x55000000),
          borderRadius: BorderRadius.circular(compact ? 16 : 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        step.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${tour.index + 1} / ${tour.steps.length}',
                      textDirection: TextDirection.ltr,
                      style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  step.text,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: const Color(0xFF33404A)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    _RoundButton(
                      tooltip: AppStrings.tourPreviousStep,
                      icon: Icons.arrow_back,
                      onTap: tour.index > 0 ? tour.previous : null,
                    ),
                    const SizedBox(width: 4),
                    _RoundButton(
                      tooltip: tour.playing ? AppStrings.tourPause : AppStrings.tourPlay,
                      icon: tour.playing ? Icons.pause : Icons.play_arrow,
                      onTap: tour.toggle,
                      primary: true,
                    ),
                    const SizedBox(width: 4),
                    _RoundButton(
                      tooltip: AppStrings.tourNextStep,
                      icon: Icons.arrow_forward,
                      onTap: tour.atEnd ? null : tour.next,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _Progress(tour: tour)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.tour});

  final TourController tour;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        for (var i = 0; i < tour.steps.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: i < tour.index
                    ? 1
                    : i == tour.index
                    ? (tour.playing ? tour.progress : 1)
                    : 0,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: primary ? scheme.primary : scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 20,
              color: primary
                  ? scheme.onPrimary
                  : (onTap == null ? scheme.outline : scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
