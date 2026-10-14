import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';

/// CSS `border-dashed` in the border colour: dashes and gaps three border-widths long, as Chrome draws them.
/// A foreground painter, since Flutter's [Border] only draws solid lines.
class DashedBorder extends CustomPainter {
  const DashedBorder({required this.radius, this.width = 2 * px});

  final BorderRadius radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final dash = 3 * width;
    final rect = (Offset.zero & size).deflate(width / 2);
    final paint = Paint()
      ..color = TvColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final PathMetric metric
        in (Path()..addRRect(radius.toRRect(rect))).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 2 * dash) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorder oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.width != width;
}
