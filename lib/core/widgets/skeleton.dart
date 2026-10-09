import 'package:flutter/widgets.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';

/// Tailwind's `animate-pulse`: fades [child] to half opacity and back, two seconds a cycle.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});

  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0.5)
      .animate(
        CurvedAnimation(parent: _pulse, curve: const Cubic(0.4, 0, 0.6, 1)),
      );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

/// A loading placeholder in the brand tint.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(0.375 * rem)),
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Pulse(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: TvColors.primary.withValues(alpha: 0.1),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
