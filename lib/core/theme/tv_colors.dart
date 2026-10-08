import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Colour tokens from the reference app's globals.css. `*Ink` variants carry text; bare hues are fills.
abstract final class TvColors {
  static const Color background = Color(0xFFFAF5FF);
  static const Color backgroundEnd = Color(0xFFFDF2F8);
  static const Color foreground = Color(0xFF171717);
  static const Color mutedForeground = Color(0xFF525252);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryInk = Color(0xFF4D20B6);
  static const Color accent = Color(0xFFEC4899);
  static const Color ring = Color(0xFF8A2CE2);
  static const Color border = Color(0xFF9E87B5);
  static const Color input = Color(0xFFE0DAE7);
  static const Color secondary = Color(0xFFF5EFFB);
  static const Color muted = Color(0xFFF0EBF4);
  static const Color destructive = Color(0xFFEF4444);
  static const Color mint = Color(0xFF36D399);
  static const Color mintInk = Color(0xFF096748);
  static const Color sun = Color(0xFFFBC72D);
  static const Color sunInk = Color(0xFF884C07);
  static const Color sky = Color(0xFF1485F5);
  static const Color skyInk = Color(0xFF093F86);
  static const Color wordmark = Color(0xFFAD46FF);

  /// The wash behind every screen.
  static const LinearGradient canvas = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundEnd],
  );

  /// Brand ramp: wordmark, resting primary control, focused nav item and key.
  static const LinearGradient brand = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFAD46FF), Color(0xFF8B5CF6)],
    transform: CssGradientAngle(135),
  );

  /// Two-stop ramp a primary control takes on focus.
  static const LinearGradient brandBold = LinearGradient(
    colors: [Color(0xFFAD46FF), Color(0xFFF6339A)],
    transform: CssGradientAngle(135),
  );
}

/// Reproduces CSS `linear-gradient(<angle>deg, …)` on a left-to-right [LinearGradient].
/// Flutter's corner-to-corner alignments tilt with the box's aspect ratio; CSS angles do not.
class CssGradientAngle extends GradientTransform {
  const CssGradientAngle(this.degrees);

  final double degrees;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final angle = degrees * math.pi / 180;
    // CSS sizes the gradient line so the corners land exactly on the first and last stops.
    final length =
        (bounds.width * math.sin(angle)).abs() +
        (bounds.height * math.cos(angle)).abs();
    final center = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(angle - math.pi / 2)
      ..scaleByDouble(length / bounds.width, 1, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}
