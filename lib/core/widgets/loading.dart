import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';

/// Value of a `[from, to, from]` keyframe loop at [t] (0–1), easing each half like framer-motion does.
double _pingPong(double t, double from, double to, Curve curve) => t < 0.5
    ? from + (to - from) * curve.transform(t * 2)
    : to + (from - to) * curve.transform((t - 0.5) * 2);

/// Three bouncing dots for a busy control or a list still filling. Defaults to the ambient text colour.
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key, this.color});

  final Color? color;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 750);
  // Each dot trails the previous by 0.12s.
  static const _stagger = 0.12 / 0.75;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ??
        DefaultTextStyle.of(context).style.color ??
        TvColors.primary;
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 0.375 * rem,
          children: [
            for (var i = 0; i < 3; i++)
              _dot(color, (_controller.value - i * _stagger) % 1),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, double t) => Transform.translate(
    offset: Offset(0, _pingPong(t, 0, -5 * px, Curves.easeInOut)),
    child: Container(
      width: 0.625 * rem,
      height: 0.625 * rem,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: color.a * _pingPong(t, 0.4, 1, Curves.easeInOut),
        ),
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// The full-pane busy state: the mascot hopping over its shadow, a rotating kid-friendly line and dots.
class Spinner extends StatefulWidget {
  const Spinner({super.key, this.label});

  /// Fixed text instead of the rotating lines.
  final String? label;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  static const _phrases = [
    'Waking up the stories…',
    'Fluffing the pillows…',
    'Counting sleepy sheep…',
    'Tiptoeing to the bookshelf…',
    'Shushing the noisy dragons…',
    'Warming up the moon…',
    'Turning the page…',
  ];
  static const _hopEase = Cubic(0.4, 0, 0.5, 1);

  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();
  Timer? _rotation;
  int _phrase = 0;

  @override
  void initState() {
    super.initState();
    if (widget.label == null) {
      _rotation = Timer.periodic(
        const Duration(milliseconds: 2200),
        (_) => setState(() => _phrase = (_phrase + 1) % _phrases.length),
      );
    }
  }

  @override
  void dispose() {
    _rotation?.cancel();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _hop,
            builder: (context, _) {
              final t = _hop.value;
              return Column(
                children: [
                  Transform.translate(
                    offset: Offset(0, _pingPong(t, 0, -18 * px, _hopEase)),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 3.5 * rem,
                    ),
                  ),
                  const SizedBox(height: 0.75 * rem),
                  // The shadow squashing as the mascot lands is what sells the hop.
                  Transform.scale(
                    scaleX: _pingPong(t, 1, 0.55, _hopEase),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 1 * px,
                        sigmaY: 1 * px,
                      ),
                      child: Container(
                        width: 3 * rem,
                        height: 0.5 * rem,
                        decoration: BoxDecoration(
                          color: TvColors.primary.withValues(
                            alpha: 0.25 * _pingPong(t, 0.55, 0.2, _hopEase),
                          ),
                          borderRadius: BorderRadius.circular(rem),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 1.75 * rem),
          Text(
            widget.label ?? _phrases[_phrase],
            style: TvText.base.copyWith(
              fontFamily: TvText.fredoka,
              fontWeight: FontWeight.w600,
              color: TvColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 0.75 * rem),
          const LoadingDots(color: TvColors.primary),
        ],
      ),
    );
  }
}
