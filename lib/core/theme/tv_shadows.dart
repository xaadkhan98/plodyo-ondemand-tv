import 'package:flutter/painting.dart';

import 'tv_scale.dart';

/// Tailwind's shadow scale. [color] replaces every layer's colour, as `shadow-<color>/<alpha>` does.
abstract final class TvShadows {
  static const Color _black10 = Color(0x1A000000);

  static List<BoxShadow> md([Color color = _black10]) => [
    _css(color, 4, 6, -1),
    _css(color, 2, 4, -2),
  ];

  static List<BoxShadow> lg([Color color = _black10]) => [
    _css(color, 10, 15, -3),
    _css(color, 4, 6, -4),
  ];

  static List<BoxShadow> xl([Color color = _black10]) => [
    _css(color, 20, 25, -5),
    _css(color, 8, 10, -6),
  ];

  static List<BoxShadow> x2l([Color color = const Color(0x40000000)]) => [
    _css(color, 25, 50, -12),
  ];

  /// A CSS `0 <y>px <blur>px <spread>px` shadow. CSS blur is twice the Gaussian sigma; Flutter's blurRadius is not.
  static BoxShadow _css(Color color, double y, double blur, double spread) =>
      BoxShadow(
        color: color,
        offset: Offset(0, y * px),
        blurRadius: blur * px / 2 <= 0.5 ? 0 : (blur * px / 2 - 0.5) / 0.57735,
        spreadRadius: spread * px,
      );
}
