import 'package:flutter/material.dart'
    show BoxFit, Color, ColorFilter, BlendMode;
import 'package:vector_graphics/vector_graphics.dart';

VectorGraphic buildSvgIcon({
  required String assetName,
  Color? color,
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  return VectorGraphic(
    loader: AssetBytesLoader(assetName),
    width: width,
    height: height,
    fit: fit,
    colorFilter: color != null
        ? ColorFilter.mode(color, BlendMode.srcIn)
        : null,
  );
}
