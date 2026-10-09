import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_shadows.dart';
import '../theme/tv_typography.dart';
import 'blinking_caret.dart';
import 'tv_focusable.dart';

/// One line of remote-entered text. Never a native field: that summons the TV's IME, which covers half
/// the screen and swallows the D-pad. The value comes from a TextEntryController fed by OnScreenKeyboard.
class TvTextField extends StatelessWidget {
  const TvTextField({
    super.key,
    required this.label,
    required this.value,
    this.active = false,
    this.onSelect,
    this.icon,
    this.placeholder = '—',
    this.mask = false,
    this.focusNode,
    this.autofocus = false,
    this.keyboardFocusNode,
  });

  final String label;
  final String value;

  /// Receiving typed characters: draws the caret and the primary border.
  final bool active;

  /// Omit for a read-only row the D-pad skips.
  final VoidCallback? onSelect;
  final IconData? icon;
  final String placeholder;

  /// Bullets instead of the value, for passwords.
  final bool mask;
  final FocusNode? focusNode;
  final bool autofocus;

  /// The keyboard's entry key: on a remote, OK on the field also carries focus there; a touch only picks the field.
  final FocusNode? keyboardFocusNode;

  static const _radius = BorderRadius.all(Radius.circular(rem));

  @override
  Widget build(BuildContext context) {
    if (onSelect == null) return _row(focused: false);
    return TvFocusable(
      focusNode: focusNode,
      autofocus: autofocus,
      onSelect: () {
        onSelect!();
        if (FocusManager.instance.highlightMode ==
            FocusHighlightMode.traditional) {
          keyboardFocusNode?.requestFocus();
        }
      },
      borderRadius: _radius,
      semanticLabel: label,
      builder: (context, focused) => _row(focused: focused),
    );
  }

  Widget _row({required bool focused}) {
    final shown = mask ? '•' * value.length : value;
    final valueStyle = TvText.base.copyWith(fontWeight: FontWeight.w500);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 4.625 * rem,
      padding: const EdgeInsets.symmetric(horizontal: 1.5 * rem),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
        border: Border.all(
          color: active || focused ? TvColors.primary : TvColors.border,
          width: 2 * px,
        ),
        boxShadow: focused ? TvShadows.lg() : null,
      ),
      child: Row(
        spacing: rem,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 1.5 * rem,
              color: active ? TvColors.primary : TvColors.mutedForeground,
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TvText.sm.copyWith(color: TvColors.mutedForeground),
                ),
                // The caret sits right after the text, not parked at the row's edge.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shown.isEmpty ? placeholder : shown,
                        style: shown.isEmpty
                            ? valueStyle.copyWith(
                                color: TvColors.mutedForeground,
                              )
                            : valueStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (active)
                      Padding(
                        padding: const EdgeInsets.only(left: 0.25 * rem),
                        child: BlinkingCaret(
                          height: valueStyle.fontSize! * 1.1,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
