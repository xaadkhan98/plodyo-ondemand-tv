import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';

/// A text-entry screen's two columns: the form, then the keyboard that feeds it.
class KeyboardFormLayout extends StatelessWidget {
  const KeyboardFormLayout({
    super.key,
    required this.form,
    required this.keyboard,
    this.keyboardLabel,
    this.keyboardOffset = 0,
    this.maxWidth = 87.5 * rem,
    this.alignTop = false,
    this.gap = 4 * rem,
  });

  final Widget form;
  final Widget keyboard;

  /// "Entering …", naming the field the keys type into.
  final String? keyboardLabel;

  /// Nudges the keyboard right into the outer margin without moving the form.
  final double keyboardOffset;
  final double maxWidth;

  /// Top-align a form too tall to centre against the keyboard.
  final bool alignTop;

  /// Between the form and the keyboard.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        crossAxisAlignment: alignTop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        spacing: gap,
        children: [
          Expanded(child: form),
          Transform.translate(
            offset: Offset(keyboardOffset, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (keyboardLabel != null) ...[
                  Text(
                    keyboardLabel!,
                    style: TvText.sm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: TvColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 0.75 * rem),
                ],
                keyboard,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A form or detail screen's `h1`: Fredoka at the largest step.
class ScreenHeading extends StatelessWidget {
  const ScreenHeading(this.text, {super.key, this.tight = false});

  final String text;

  /// Tailwind's `leading-tight`, which the auth screens set.
  final bool tight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TvText.x3l.copyWith(
        fontFamily: TvText.fredoka,
        fontWeight: FontWeight.w600,
        height: tight ? TvText.tight : null,
      ),
    );
  }
}

/// The line of context under a [ScreenHeading], capped at [maxCh] characters like the reference.
class ScreenSubtitle extends StatelessWidget {
  const ScreenSubtitle(this.text, {super.key, required this.maxCh});

  final String text;
  final int maxCh;

  @override
  Widget build(BuildContext context) {
    final style = TvText.base.copyWith(color: TvColors.mutedForeground);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCh * TvText.ch(style)),
        child: Text(text, style: style),
      ),
    );
  }
}
