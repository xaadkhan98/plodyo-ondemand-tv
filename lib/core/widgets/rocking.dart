import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Rocks [child] from -[tilt]° to [tilt]° while rising [rise], and back, every 2.6s: the one motion an
/// empty or waiting state is given, so it reads as resting rather than broken.
class Rocking extends StatefulWidget {
  const Rocking({
    super.key,
    required this.tilt,
    required this.rise,
    required this.child,
  });

  final double tilt;
  final double rise;
  final Widget child;

  @override
  State<Rocking> createState() => _RockingState();
}

class _RockingState extends State<Rocking> with SingleTickerProviderStateMixin {
  late final AnimationController _rock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);
  late final Animation<double> _swing = CurvedAnimation(
    parent: _rock,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _rock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _swing,
      builder: (context, child) {
        final t = _swing.value;
        return Transform.translate(
          offset: Offset(0, -widget.rise * t),
          child: Transform.rotate(
            angle: widget.tilt * (2 * t - 1) * math.pi / 180,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
