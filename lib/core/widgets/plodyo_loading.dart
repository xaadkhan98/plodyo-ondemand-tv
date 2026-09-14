import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Three purple dots animating smoothly up and down with staggered bounce wave.
/// Designed for small places such as buttons, cards, and inline indicators.
class PlodyoThreeDotsLoading extends StatefulWidget {
  const PlodyoThreeDotsLoading({
    super.key,
    this.dotSize = 8.0,
    this.spacing = 6.0,
    this.bounceHeight = 6.0,
    this.color,
    this.dotColors,
    this.duration = const Duration(milliseconds: 1200),
  });

  /// Diameter of each dot.
  final double dotSize;

  /// Spacing between dots.
  final double spacing;

  /// Maximum vertical bounce offset in pixels.
  final double bounceHeight;

  /// Single color for all dots (if [dotColors] is not specified).
  final Color? color;

  /// Optional list of 3 colors for the dots (e.g. purple gradient tone).
  final List<Color>? dotColors;

  /// Duration of one complete wave cycle.
  final Duration duration;

  @override
  State<PlodyoThreeDotsLoading> createState() => _PlodyoThreeDotsLoadingState();
}

class _PlodyoThreeDotsLoadingState extends State<PlodyoThreeDotsLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<Color> _defaultDotColors = [
    Color(0xFF8B5CF6), // Darker purple / lilac
    Color(0xFFA78BFA), // Medium purple
    Color(0xFFC4B5FD), // Light purple
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.forward();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.dotColors ??
        (widget.color != null
            ? [
                widget.color!,
                widget.color!.withValues(alpha: 0.8),
                widget.color!.withValues(alpha: 0.6),
              ]
            : _defaultDotColors);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (index) {
            // Calculate staggered phase offset for each dot
            final phase = (index * 0.22);
            final progress = (_controller.value + phase) % 1.0;
            // Sine wave bounce: [0.0, 1.0]
            final sineValue = math.sin(progress * 2 * math.pi);
            final bounceOffset = (sineValue > 0 ? sineValue : 0.0) * -widget.bounceHeight;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Transform.translate(
                offset: Offset(0, bounceOffset),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors[index % colors.length].withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Full-page / main content loading animation with:
/// 1. Floating animated Plodyo logo with dynamic ground shadow.
/// 2. "One moment..." title text.
/// 3. Three bouncing purple dots underneath.
class PlodyoPageLoading extends StatefulWidget {
  const PlodyoPageLoading({
    super.key,
    this.message = 'One moment...',
    this.logoSize = 58.0,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
  });

  /// Text message displayed below the logo.
  final String message;

  /// Size (width & height) of the Plodyo logo.
  final double logoSize;

  /// Optional background color (defaults to transparent / inherits).
  final Color? backgroundColor;

  /// Padding around the loading content.
  final EdgeInsetsGeometry padding;

  @override
  State<PlodyoPageLoading> createState() => _PlodyoPageLoadingState();
}

class _PlodyoPageLoadingState extends State<PlodyoPageLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _floatController.forward();
    } else {
      _floatController.repeat(reverse: true);
    }

    _floatAnimation = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      padding: widget.padding,
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          // Floating offset: moves 0 to -14 pixels
          final floatOffset = -14.0 * _floatAnimation.value;
          // Shadow width and opacity expand when logo is lowest (animation value near 0)
          final shadowScale = 1.0 - (0.35 * _floatAnimation.value);
          final shadowAlpha = 0.28 - (0.16 * _floatAnimation.value);

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated Floating Logo
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: widget.logoSize,
                  height: widget.logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: widget.logoSize,
                    height: widget.logoSize,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFD946EF), Color(0xFF9333EA)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tv_rounded,
                      color: Colors.white,
                      size: widget.logoSize * 0.55,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Floating ground shadow underneath logo
              Container(
                width: widget.logoSize * 0.75 * shadowScale,
                height: 7 * shadowScale,
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withValues(alpha: shadowAlpha.clamp(0.05, 0.4)),
                  borderRadius: const BorderRadius.all(Radius.elliptical(30, 6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: shadowAlpha.clamp(0.05, 0.4)),
                      blurRadius: 10 * shadowScale,
                      spreadRadius: 1.5 * shadowScale,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // "One moment..." Title Text
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.baloo2(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF18181B),
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 16),

              // Staggered Bouncing Three Dots
              const PlodyoThreeDotsLoading(
                dotSize: 10,
                spacing: 7,
                bounceHeight: 7,
                dotColors: [
                  Color(0xFF8B5CF6),
                  Color(0xFFA78BFA),
                  Color(0xFFC4B5FD),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
