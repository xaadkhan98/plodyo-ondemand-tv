import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// D-Pad and remote navigable on-screen virtual keyboard for TV.
class TvKeyboard extends StatefulWidget {
  const TvKeyboard({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    required this.onSpace,
    required this.onClear,
    this.statusText = 'Entering email address',
  });

  final ValueChanged<String> onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onSpace;
  final VoidCallback onClear;
  final String statusText;

  @override
  State<TvKeyboard> createState() => _TvKeyboardState();
}

class _TvKeyboardState extends State<TvKeyboard> {
  bool _isUpperCase = false;

  final List<List<String>> _keyRows = const [
    ['a', 'b', 'c', 'd', 'e', 'f'],
    ['g', 'h', 'i', 'j', 'k', 'l'],
    ['m', 'n', 'o', 'p', 'q', 'r'],
    ['s', 't', 'u', 'v', 'w', 'x'],
    ['y', 'z', '0', '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9'],
    ['@', '.', '-', '_'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status header text (e.g. "Entering email address")
        Text(
          widget.statusText,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF71717A),
          ),
        ),
        const SizedBox(height: 14),

        // Grid Rows
        ..._keyRows.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: row.map((char) {
                  final displayChar = _isUpperCase ? char.toUpperCase() : char;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TvKeyButton(
                      label: displayChar,
                      onPressed: () => widget.onKeyPress(displayChar),
                    ),
                  );
                }).toList(),
              ),
            )),

        // Bottom Action Keys Row (Shift/Caps, Space, Backspace, Clear)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shift / Caps toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TvKeyButton(
                label: _isUpperCase ? '↑ ABC' : '↑ abc',
                width: 68,
                onPressed: () {
                  setState(() {
                    _isUpperCase = !_isUpperCase;
                  });
                },
              ),
            ),
            // Space key
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TvKeyButton(
                label: '␣ Space',
                width: 88,
                onPressed: widget.onSpace,
              ),
            ),
            // Backspace key
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TvKeyButton(
                icon: Icons.backspace_outlined,
                width: 48,
                onPressed: widget.onBackspace,
              ),
            ),
            // Clear key
            _TvKeyButton(
              label: 'Clear',
              width: 58,
              onPressed: widget.onClear,
            ),
          ],
        ),
      ],
    );
  }
}

class _TvKeyButton extends StatefulWidget {
  const _TvKeyButton({
    this.label,
    this.icon,
    this.width = 46,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final VoidCallback onPressed;

  @override
  State<_TvKeyButton> createState() => _TvKeyButtonState();
}

class _TvKeyButtonState extends State<_TvKeyButton> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
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
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isFocused ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: widget.width,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused ? const Color(0xFFC084FC) : const Color(0xFFF1F5F9),
                width: _isFocused ? 2.2 : 1.0,
              ),
              boxShadow: [
                if (_isFocused)
                  BoxShadow(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.6),
                    blurRadius: 14,
                    spreadRadius: 2,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Center(
              child: widget.icon != null
                  ? Icon(
                      widget.icon,
                      size: 18,
                      color: _isFocused ? const Color(0xFF7E22CE) : const Color(0xFF27272A),
                    )
                  : Text(
                      widget.label ?? '',
                      style: TextStyle(
                        fontSize: widget.label != null && widget.label!.length > 2 ? 13 : 17,
                        fontWeight: _isFocused ? FontWeight.w700 : FontWeight.w500,
                        color: _isFocused ? const Color(0xFF7E22CE) : const Color(0xFF27272A),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
