import 'package:flutter/widgets.dart';

import '../theme/tv_motion.dart';
import '../theme/tv_scale.dart';

/// Places its child in the screen ([alignment], centred by default), scrolling only when the child outgrows it:
/// the reference's `min-h-full` inside `overflow-y-auto`. Padded by the overscan gutters by default.
class CenteredScrollView extends StatelessWidget {
  const CenteredScrollView({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.symmetric(
      horizontal: TvInsets.safeX,
      vertical: TvInsets.safeY,
    ),
  });

  final Widget child;
  final Alignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: padding,
            child: Align(alignment: alignment, child: child),
          ),
        ),
      ),
    );
  }
}

/// A screen's one entrance: fade in while rising [rise] reference px. Plays once, on first build.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.rise = 16,
    this.duration = TvMotion.entrance,
  });

  final Widget child;
  final double rise;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: TvMotion.focus,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, rise * px * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
