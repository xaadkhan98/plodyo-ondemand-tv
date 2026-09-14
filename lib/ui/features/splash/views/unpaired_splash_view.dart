import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';

/// Splash / Unpaired TV Welcome View displayed when the TV app is first opened.
/// Matches the Plodyo on-demand setup design with TV remote D-Pad navigation.
class UnpairedSplashView extends StatefulWidget {
  const UnpairedSplashView({
    super.key,
    this.onSetupTv,
    this.onSignInConsole,
  });

  final VoidCallback? onSetupTv;
  final VoidCallback? onSignInConsole;

  @override
  State<UnpairedSplashView> createState() => _UnpairedSplashViewState();
}

class _UnpairedSplashViewState extends State<UnpairedSplashView> {
  final FocusNode _setupFocusNode = FocusNode();
  final FocusNode _signInFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the primary "Set up this TV" button on startup for TV remote control
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _setupFocusNode.dispose();
    _signInFocusNode.dispose();
    super.dispose();
  }

  void _handleSetupTv() {
    if (widget.onSetupTv != null) {
      widget.onSetupTv!();
    } else {
      context.push('/pair-tv');
    }
  }

  void _handleSignInConsole() {
    if (widget.onSignInConsole != null) {
      widget.onSignInConsole!();
    } else {
      context.push('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCFAFE),
              Color(0xFFFAF6FC),
              Color(0xFFF7F0FA),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // TV Icon with Antenna Outline
                  const _TvIconBadge(),
                  const SizedBox(height: 28),

                  // Main Title
                  Text(
                    'This TV is not set up yet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.baloo2(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF18181B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // First Description Line
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Text(
                      'Pair it with a room to show the story library, or sign in to run the Plodyo TV console from this screen.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF52525B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Second Subtitle / Pairing Hint Line
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Text(
                      "A pairing code comes from the room's page in the console and lasts fifteen minutes.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Interactive TV Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Set up this TV" Primary Action Button
                      _PrimaryGradientTvButton(
                        focusNode: _setupFocusNode,
                        label: 'Set up this TV',
                        onPressed: _handleSetupTv,
                      ),
                      const SizedBox(width: 20),

                      // "Sign in to the console" Secondary Action Button
                      _SecondaryOutlineTvButton(
                        focusNode: _signInFocusNode,
                        label: 'Sign in to the console',
                        onPressed: _handleSignInConsole,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stylized TV Icon Badge with top antenna geometry.
class _TvIconBadge extends StatelessWidget {
  const _TvIconBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 48,
      child: CustomPaint(
        painter: _TvIconPainter(
          color: const Color(0xFF8B5CF6),
        ),
      ),
    );
  }
}

/// Custom painter for the outlined TV icon with antennas.
class _TvIconPainter extends CustomPainter {
  _TvIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Antennas from top center
    final centerX = w / 2;
    final antennaStartY = h * 0.32;
    final leftAntennaX = w * 0.30;
    final rightAntennaX = w * 0.70;
    final antennaTopY = h * 0.08;

    canvas.drawLine(
      Offset(centerX, antennaStartY),
      Offset(leftAntennaX, antennaTopY),
      paint,
    );

    canvas.drawLine(
      Offset(centerX, antennaStartY),
      Offset(rightAntennaX, antennaTopY),
      paint,
    );

    // TV Screen Rounded Rectangle
    final screenRect = Rect.fromLTWH(
      w * 0.08,
      h * 0.30,
      w * 0.84,
      h * 0.62,
    );
    final rrect = RRect.fromRectAndRadius(
      screenRect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _TvIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Primary button with magenta-purple gradient and glowing focus state.
class _PrimaryGradientTvButton extends StatefulWidget {
  const _PrimaryGradientTvButton({
    required this.focusNode,
    required this.label,
    required this.onPressed,
  });

  final FocusNode focusNode;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_PrimaryGradientTvButton> createState() =>
      _PrimaryGradientTvButtonState();
}

class _PrimaryGradientTvButtonState extends State<_PrimaryGradientTvButton> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.gameButtonA ||
          key == LogicalKeyboardKey.numpadEnter) {
        widget.onPressed();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isFocused ? 1.06 : 1.0,
          duration: AppConstants.focusAnimationDuration,
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF831843), // Rich deep magenta / berry
                  Color(0xFF581C87), // Deep purple / violet
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? const Color(0xFFA855F7).withValues(alpha: 0.7)
                      : const Color(0xFF7E22CE).withValues(alpha: 0.4),
                  blurRadius: _isFocused ? 32 : 24,
                  spreadRadius: _isFocused ? 4 : 2,
                  offset: const Offset(0, 6),
                ),
              ],
              border: _isFocused
                  ? Border.all(color: Colors.white, width: 2.0)
                  : Border.all(color: Colors.transparent, width: 2.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button with white background and purple outline.
class _SecondaryOutlineTvButton extends StatefulWidget {
  const _SecondaryOutlineTvButton({
    required this.focusNode,
    required this.label,
    required this.onPressed,
  });

  final FocusNode focusNode;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_SecondaryOutlineTvButton> createState() =>
      _SecondaryOutlineTvButtonState();
}

class _SecondaryOutlineTvButtonState extends State<_SecondaryOutlineTvButton> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.gameButtonA ||
          key == LogicalKeyboardKey.numpadEnter) {
        widget.onPressed();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isFocused ? 1.06 : 1.0,
          duration: AppConstants.focusAnimationDuration,
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: _isFocused
                  ? const Color(0xFFFAF5FF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF8B5CF6),
                width: _isFocused ? 2.5 : 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: const Text(
              'Sign in to the console',
              style: TextStyle(
                color: Color(0xFF18181B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

