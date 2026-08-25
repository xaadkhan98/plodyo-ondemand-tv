import 'package:flutter/material.dart';
import '../theme/tv_colors.dart';
import '../theme/tv_typography.dart';
import 'tv_focusable.dart';

enum TvButtonStyle {
  primary,
  secondary,
  tonal,
}

/// D-Pad focusable TV Action Button (e.g. "Play Now", "Watch Trailer", "Add to List").
class TvButton extends StatefulWidget {
  const TvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = TvButtonStyle.primary,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final TvButtonStyle style;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;

    switch (widget.style) {
      case TvButtonStyle.primary:
        backgroundColor = _isFocused ? Colors.white : TvColors.primary;
        foregroundColor = _isFocused ? Colors.black : Colors.black87;
        break;
      case TvButtonStyle.secondary:
        backgroundColor = _isFocused ? TvColors.primary : TvColors.surfaceElevated;
        foregroundColor = _isFocused ? Colors.black : TvColors.textPrimary;
        break;
      case TvButtonStyle.tonal:
        backgroundColor = _isFocused ? Colors.white24 : Colors.white10;
        foregroundColor = Colors.white;
        break;
    }

    return TvFocusable(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      borderRadius: BorderRadius.circular(10),
      scaleFactor: 1.08,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 20,
                color: foregroundColor,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TvTypography.button.copyWith(
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
