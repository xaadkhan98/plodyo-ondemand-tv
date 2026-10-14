import 'package:flutter/widgets.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';

/// The text cursor: opacity 1 → 0 → 1 every 1.1s, as in the reference. The one thing on a form allowed
/// to loop, because it is the cursor.
class BlinkingCaret extends StatefulWidget {
  const BlinkingCaret({
    super.key,
    required this.height,
    this.width = 0.125 * rem,
    this.rounded = false,
  });

  final double height;
  final double width;

  /// A pill rather than a hairline, for the pairing tiles' thicker caret.
  final bool rounded;

  @override
  State<BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blink.drive(
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
        ]),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: TvColors.primary,
          borderRadius: widget.rounded ? BorderRadius.circular(999) : null,
        ),
      ),
    );
  }
}
