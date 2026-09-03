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
  bool _isHovered = false;

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
    final isHighlighted = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: isHighlighted ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFD946EF),
                          Color(0xFF9333EA),
                        ],
                      )
                    : null,
                color: isHighlighted ? null : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: isHighlighted
                    ? null
                    : Border.all(
                        color: const Color(0xFFE4E4E7),
                        width: 1.0,
                      ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD946EF).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
              ),
              child: Center(
                child: widget.icon != null
                    ? Icon(
                        widget.icon,
                        size: 18,
                        color: isHighlighted
                            ? Colors.white
                            : const Color(0xFF27272A),
                      )
                    : Text(
                        widget.label ?? '',
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                          color: isHighlighted
                              ? Colors.white
                              : const Color(0xFF18181B),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
