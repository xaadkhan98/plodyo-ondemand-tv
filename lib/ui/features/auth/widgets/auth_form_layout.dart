import 'package:flutter/material.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';

/// The auth screens' two columns: the form, then the keyboard that feeds it.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.form,
    required this.keyboard,
    this.keyboardLabel,
    this.keyboardOffset = 0,
    this.maxWidth = 87.5 * rem,
    this.alignTop = false,
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

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        crossAxisAlignment: alignTop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        spacing: 4 * rem,
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

/// An auth screen's heading: Fredoka at the largest step.
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TvText.x3l.copyWith(
        fontFamily: TvText.fredoka,
        fontWeight: FontWeight.w600,
        height: TvText.tight,
      ),
    );
  }
}

/// The line of context under an [AuthTitle], capped at [maxCh] characters like the reference.
class AuthSubtitle extends StatelessWidget {
  const AuthSubtitle(this.text, {super.key, required this.maxCh});

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
