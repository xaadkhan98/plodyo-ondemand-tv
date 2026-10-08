import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../input/text_entry.dart';
import '../theme/tv_colors.dart';
import '../theme/tv_motion.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_shadows.dart';
import '../theme/tv_typography.dart';
import 'tv_focusable.dart';

/// Symbol sets for [OnScreenKeyboard.extraKeys], putting a field's common characters on the first page.
abstract final class KeySets {
  static const List<String> email = ['@', '.', '-', '_'];
  static const List<String> name = ['-', '.', "'"];
  static const List<String> phone = ['+', '-', '(', ')'];
  static const List<String> sentence = ['.', ',', '-', '/'];

  /// An IANA timezone is "Area/City", and the odd one uses an underscore.
  static const List<String> timezone = ['/', '_', '-', '+'];
}

/// Grid keyboard for remote-driven text entry. Alphabetical, not QWERTY: QWERTY optimises for ten fingers,
/// not four arrows, and a predictable grid is reachable in a bounded number of presses.
/// Shift is sticky, and `!#?` swaps the grid for every printable ASCII symbol.
class OnScreenKeyboard extends StatefulWidget {
  const OnScreenKeyboard({
    super.key,
    required this.controller,
    this.extraKeys = const [],
    this.defaultShift = false,
    this.entryFocusNode,
  });

  final TextEntryController controller;

  /// Appended after the digits on the first page, e.g. [KeySets.email].
  final List<String> extraKeys;

  /// Start in uppercase; a pairing code is printed in capitals.
  final bool defaultShift;

  /// Given to the first key, so a screen can move focus into the keyboard.
  final FocusNode? entryFocusNode;

  static const double _key = 3.5 * rem;
  static const double _gap = 0.625 * rem;
  static const int _columns = 6;

  /// The grid's width, which the control row stretches to.
  static const double width = _columns * _key + (_columns - 1) * _gap;

  @override
  State<OnScreenKeyboard> createState() => _OnScreenKeyboardState();
}

class _OnScreenKeyboardState extends State<OnScreenKeyboard> {
  static const _letters = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _symbols = r'''!@#$%&*()-_+=/\:;?.,'"<>[]{}^~|`''';

  late bool _shift = widget.defaultShift;
  bool _showSymbols = false;

  List<String> get _keys => _showSymbols
      ? _symbols.split('')
      : [
          for (final c in _letters.split('')) _shift ? c.toUpperCase() : c,
          ..._digits.split(''),
          ...widget.extraKeys,
        ];

  @override
  Widget build(BuildContext context) {
    final keys = _keys;
    final controller = widget.controller;

    return SizedBox(
      width: OnScreenKeyboard.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: OnScreenKeyboard._gap,
        children: [
          for (
            var row = 0;
            row * OnScreenKeyboard._columns < keys.length;
            row++
          )
            Row(
              spacing: OnScreenKeyboard._gap,
              children: [
                for (
                  var i = row * OnScreenKeyboard._columns;
                  i < keys.length && i < (row + 1) * OnScreenKeyboard._columns;
                  i++
                )
                  // Keyed by position so focus stays put while shift relabels the grid.
                  _Key(
                    key: ValueKey(i),
                    focusNode: i == 0 ? widget.entryFocusNode : null,
                    width: OnScreenKeyboard._key,
                    onSelect: () => controller.append(keys[i]),
                    scaleOnFocus: true,
                    child: Text(keys[i]),
                  ),
              ],
            ),
          Row(
            spacing: OnScreenKeyboard._gap,
            children: [
              _Key(
                width: 4.5 * rem,
                toggled: _shift,
                onSelect: () => setState(() => _shift = !_shift),
                small: true,
                semanticLabel: 'Shift',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 0.25 * rem,
                  children: [
                    const Icon(LucideIcons.arrowUp500),
                    Text(_shift ? 'ABC' : 'abc'),
                  ],
                ),
              ),
              _Key(
                width: 4.5 * rem,
                toggled: _showSymbols,
                onSelect: () => setState(() => _showSymbols = !_showSymbols),
                small: true,
                child: Text(_showSymbols ? 'abc' : '!#?'),
              ),
              Expanded(
                child: _Key(
                  onSelect: () => controller.append(' '),
                  semanticLabel: 'Space',
                  child: const Icon(LucideIcons.space),
                ),
              ),
              _Key(
                width: 4 * rem,
                onSelect: controller.backspace,
                semanticLabel: 'Delete',
                child: const Icon(LucideIcons.delete),
              ),
              _Key(
                width: 4 * rem,
                onSelect: controller.clear,
                small: true,
                focusFill: TvColors.destructive,
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.onSelect,
    required this.child,
    this.width,
    this.focusNode,
    this.toggled = false,
    this.small = false,
    this.scaleOnFocus = false,
    this.focusFill,
    this.semanticLabel,
  });

  final VoidCallback onSelect;
  final Widget child;
  final double? width;
  final FocusNode? focusNode;

  /// A latched modifier (shift, symbols) shows solid violet while off focus.
  final bool toggled;
  final bool small;
  final bool scaleOnFocus;

  /// Solid fill on focus instead of the brand ramp, e.g. red for Clear.
  final Color? focusFill;
  final String? semanticLabel;

  static const _radius = BorderRadius.all(Radius.circular(0.75 * rem));

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      focusNode: focusNode,
      onSelect: onSelect,
      borderRadius: _radius,
      semanticLabel: semanticLabel,
      builder: (context, focused) {
        final onFill = focused || toggled;
        final text = (small ? TvText.sm : TvText.base).copyWith(
          fontWeight: FontWeight.w600,
          color: onFill ? Colors.white : TvColors.foreground,
        );
        return AnimatedScale(
          scale: focused && scaleOnFocus ? 1.06 : 1,
          duration: const Duration(milliseconds: 150),
          curve: TvMotion.focus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: width,
            height: OnScreenKeyboard._key,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: focused
                  ? focusFill
                  : (toggled ? TvColors.primary : Colors.white),
              gradient: focused && focusFill == null ? TvColors.brand : null,
              borderRadius: _radius,
              boxShadow: focused && scaleOnFocus
                  ? TvShadows.lg(TvColors.primary.withValues(alpha: 0.25))
                  : null,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: text.color, size: 1.25 * rem),
              child: DefaultTextStyle(
                style: text,
                // Keys are fixed-size: content shrinks rather than overflowing if a font runs wide.
                child: FittedBox(fit: BoxFit.scaleDown, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
