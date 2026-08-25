import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tv_colors.dart';
import '../constants/app_constants.dart';

/// Reusable TV Focusable Wrapper.
///
/// Features:
/// - Smooth scale up on focus
/// - Glow border / shadow
/// - Automatic scroll-into-view when focused
/// - Remote control select/enter key trigger
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.child,
    this.onPressed,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.scaleFactor = 1.05,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.showFocusBorder = true,
    this.focusColor,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final double scaleFactor;
  final BorderRadius borderRadius;
  final bool showFocusBorder;
  final Color? focusColor;
  final EdgeInsetsGeometry padding;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
  }

  @override
  void didUpdateWidget(covariant TvFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_isInternalFocusNode) {
        _focusNode.dispose();
      }
      if (widget.focusNode == null) {
        _focusNode = FocusNode();
        _isInternalFocusNode = true;
      } else {
        _focusNode = widget.focusNode!;
        _isInternalFocusNode = false;
      }
    }
  }

  @override
  void dispose() {
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus) {
      // Ensure the newly focused item scrolls into view smoothly on TV screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    widget.onFocusChange?.call(hasFocus);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.gameButtonA ||
          key == LogicalKeyboardKey.numpadEnter) {
        widget.onPressed?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final activeFocusColor = widget.focusColor ?? TvColors.focusBorder;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isFocused ? widget.scaleFactor : 1.0,
          duration: AppConstants.focusAnimationDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: AppConstants.focusAnimationDuration,
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: _isFocused && widget.showFocusBorder
                  ? [
                      BoxShadow(
                        color: activeFocusColor.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
              border: widget.showFocusBorder && _isFocused
                  ? Border.all(
                      color: activeFocusColor,
                      width: 2.5,
                    )
                  : Border.all(
                      color: Colors.transparent,
                      width: 2.5,
                    ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
