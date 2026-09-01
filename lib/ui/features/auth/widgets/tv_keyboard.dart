import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// D-Pad and remote navigable on-screen virtual keyboard for TV with special characters support.
class TvKeyboard extends StatefulWidget {
  const TvKeyboard({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    required this.onSpace,
    required this.onClear,
    this.statusText = 'Entering password',
    this.showSpecialCharacters = true,
  });

  final ValueChanged<String> onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onSpace;
  final VoidCallback onClear;
  final String statusText;
  final bool showSpecialCharacters;

  @override
  State<TvKeyboard> createState() => _TvKeyboardState();
}

class _TvKeyboardState extends State<TvKeyboard> {
  bool _isUpperCase = false;

  final List<List<String>> _standardKeyRows = const [
    ['a', 'b', 'c', 'd', 'e', 'f'],
    ['g', 'h', 'i', 'j', 'k', 'l'],
    ['m', 'n', 'o', 'p', 'q', 'r'],
    ['s', 't', 'u', 'v', 'w', 'x'],
    ['y', 'z', '0', '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9'],
    ['@', '.', '_', '-', '!', '#'],
  ];

  @override
  Widget build(BuildContext context) {
    final keyRows = widget.showSpecialCharacters
        ? _standardKeyRows
        : _standardKeyRows.sublist(0, 6);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status header text (e.g. "Entering password")
          if (widget.statusText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child: Text(
                widget.statusText,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF71717A),
                  letterSpacing: 0.1,
                ),
              ),
            ),

          // Grid Rows (6 columns)
          ...keyRows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: row.map((char) {
                  final displayChar = _isUpperCase ? char.toUpperCase() : char;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TvKeyButton(
                      label: displayChar,
                      width: 44,
                      height: 44,
                      onPressed: () => widget.onKeyPress(displayChar),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom Action Keys Row (Shift/Caps, Space, Backspace, Clear)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shift / Caps toggle
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TvKeyButton(
                  label: _isUpperCase ? '↑ ABC' : '↑ abc',
                  width: 66,
                  height: 44,
                  fontSize: 12.5,
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
                  label: '— Space',
                  width: 82,
                  height: 44,
                  fontSize: 12.5,
                  onPressed: widget.onSpace,
                ),
              ),
              // Backspace key
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TvKeyButton(
                  icon: Icons.backspace_outlined,
                  width: 50,
                  height: 44,
                  onPressed: widget.onBackspace,
                ),
              ),
              // Clear key
              _TvKeyButton(
                label: 'Clear',
                width: 56,
                height: 44,
                fontSize: 12.5,
                onPressed: widget.onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TvKeyButton extends StatefulWidget {
  const _TvKeyButton({
    this.label,
    this.icon,
    this.width = 44,
    this.height = 44,
    this.fontSize = 15,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final double height;
  final double fontSize;
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
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFFC084FC)
                    : const Color(0xFFF1F5F9),
                width: _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (_isFocused)
                  BoxShadow(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
              ],
            ),
            child: Center(
              child: widget.icon != null
                  ? Icon(
                      widget.icon,
                      size: 17,
                      color: _isFocused
                          ? const Color(0xFF7E22CE)
                          : const Color(0xFF27272A),
                    )
                  : Text(
                      widget.label ?? '',
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: _isFocused ? FontWeight.w700 : FontWeight.w500,
                        color: _isFocused
                            ? const Color(0xFF7E22CE)
                            : const Color(0xFF27272A),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
