import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RectangularShimmer extends StatelessWidget {
  final double width;

  final double height;

  final Color? baseColor;

  final Color? highlightColor;

  final Duration period;

  final BorderRadiusGeometry borderRadius;

  const RectangularShimmer({
    super.key,
    required this.width,
    required this.height,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color defaultBaseColor = brightness == Brightness.light
        ? Colors.grey.shade300
        : Colors.grey.shade700;
    final Color defaultHighlightColor = brightness == Brightness.light
        ? Colors.grey.shade100
        : Colors.grey.shade600;

    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBaseColor,
      highlightColor: highlightColor ?? defaultHighlightColor,
      period: period,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor ?? defaultBaseColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
