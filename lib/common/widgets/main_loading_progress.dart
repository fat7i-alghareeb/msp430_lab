// Custom widget to control the size of the ResponsiveCircularProgressIndicator globally
import 'dart:ui' show Color;

import 'package:flutter/material.dart'
    show
        StatelessWidget,
        BuildContext,
        Widget,
        CircularProgressIndicator,
        SizedBox;

class MainLoadingProgress extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const MainLoadingProgress({
    super.key,
    this.size = 30,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
    );
  }
}
