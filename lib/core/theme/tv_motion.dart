import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Motion tokens from the reference.
abstract final class TvMotion {
  /// `ease-focus`: focus movement should feel immediate but not abrupt.
  static const Curve focus = Cubic(0.2, 0, 0.1, 1);
  static const Duration focusDuration = Duration(milliseconds: 200);

  /// A screen's one entrance: fade and rise.
  static const Duration entrance = Duration(milliseconds: 400);
}

/// framer-motion's `type: "spring"` as a [Curve]; [duration] must be long enough for the spring to settle.
class SpringCurve extends Curve {
  SpringCurve({
    required double stiffness,
    required double damping,
    required this.duration,
  }) : _spring = SpringSimulation(
         SpringDescription(mass: 1, stiffness: stiffness, damping: damping),
         0,
         1,
         0,
       );

  final Duration duration;
  final SpringSimulation _spring;

  @override
  double transformInternal(double t) =>
      _spring.x(t * duration.inMicroseconds / Duration.microsecondsPerSecond);
}
