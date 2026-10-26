import 'dart:math' as math;

import 'package:flutter/material.dart';

/// LoadingDots
/// -----------
///
/// Lightweight animated loading indicator used by [AppButton] when
/// `isLoading` is true.
///
/// The animation is implemented as a phase-shifted sine wave per dot, which
/// creates a smooth "traveling" pulse without multiple controllers.
///
/// Usage:
/// ```dart
/// const LoadingDots(color: Colors.white);
/// ```
class LoadingDots extends StatefulWidget {
  const LoadingDots({
    super.key,
    required this.color,
    this.dotSize = 6,
    this.spacing = 6,
    this.dots = 3,
  });

  final Color color;
  final double dotSize;
  final double spacing;
  final int dots;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotScale(int index) {
    // Offset each dot by its index so the wave travels from left to right.
    final phase = (_controller.value + (index / widget.dots)) % 1.0;
    // Map sin output from [-1, 1] to [0, 1] to get a clean amplitude.
    final wave = (math.sin(phase * 2 * math.pi) + 1) / 2;
    return 0.60 + (0.50 * wave);
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.dotSize;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.dots, (i) {
            final s = _dotScale(i);
            return Padding(
              padding: EdgeInsetsDirectional.only(
                end: i == widget.dots - 1 ? 0 : widget.spacing,
              ),
              child: Transform.scale(
                scale: s,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
