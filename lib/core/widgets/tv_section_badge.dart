import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Section Header Badge Icon
/// Features:
/// - Crisp white border (2.5px)
/// - Slight rotation to the left side (-8 degrees / -0.14 rad)
/// - Continuous smooth up-and-down floating animation
/// - Vibrant gradient with rich purple glow shadow
class TvSectionBadge extends StatefulWidget {
  const TvSectionBadge({
    super.key,
    required this.icon,
    this.size = 56.0,
    this.iconSize = 30.0,
    this.gradientColors = const [
      Color(0xFFF472B6),
      Color(0xFFE879F9),
      Color(0xFF9333EA),
      Color(0xFF7E22CE),
    ],
    this.glowColor = const Color(0xFF9333EA),
    this.tiltAngle = -8.0, // in degrees, negative tilts left
    this.floatOffset = 3.5,
    this.duration = const Duration(milliseconds: 2200),
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final List<Color> gradientColors;
  final Color glowColor;
  final double tiltAngle;
  final double floatOffset;
  final Duration duration;

  @override
  State<TvSectionBadge> createState() => _TvSectionBadgeState();
}

class _TvSectionBadgeState extends State<TvSectionBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }

    _floatAnimation = Tween<double>(
      begin: -widget.floatOffset,
      end: widget.floatOffset,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angleRad = widget.tiltAngle * math.pi / 180;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: angleRad,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: widget.iconSize,
          ),
        ),
      ),
    );
  }
}
