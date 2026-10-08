import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_motion.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_shadows.dart';
import '../theme/tv_typography.dart';
import 'loading.dart';
import 'tv_focusable.dart';

enum TvButtonVariant { primary, outline, quiet, danger }

enum TvButtonSize { lg, md, sm }

/// The one pill button every screen uses, so focus styling cannot drift. Each variant changes its fill on
/// focus, not only its border: a control that only gains an outline is invisible from the bed.
class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    required this.label,
    required this.onSelect,
    this.variant = TvButtonVariant.primary,
    this.size = TvButtonSize.lg,
    this.icon,
    this.disabled = false,
    this.busy = false,
    this.busyLabel,
    this.fullWidth = false,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback onSelect;
  final TvButtonVariant variant;
  final TvButtonSize size;
  final IconData? icon;
  final bool disabled;

  /// Shows the loading dots and [busyLabel], and swallows selection without giving up focus.
  final bool busy;
  final String? busyLabel;
  final bool fullWidth;
  final bool autofocus;
  final FocusNode? focusNode;

  static const _pill = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      focusNode: focusNode,
      autofocus: autofocus,
      disabled: disabled,
      borderRadius: _pill,
      // Busy is guarded here rather than disabling: a disabled control hands focus away mid-submit.
      onSelect: busy ? null : onSelect,
      builder: (context, focused) {
        final style = _VariantStyle.of(variant, focused: focused && !busy);
        final (minHeight, padding, text) = switch (size) {
          TvButtonSize.lg => (
            64 * px,
            const EdgeInsets.symmetric(horizontal: 2.5 * rem, vertical: rem),
            TvText.base,
          ),
          TvButtonSize.md => (
            56 * px,
            const EdgeInsets.symmetric(
              horizontal: 2 * rem,
              vertical: 0.875 * rem,
            ),
            TvText.base,
          ),
          TvButtonSize.sm => (
            48 * px,
            const EdgeInsets.symmetric(
              horizontal: 1.5 * rem,
              vertical: 0.75 * rem,
            ),
            TvText.sm,
          ),
        };
        final foreground = text.copyWith(
          fontWeight: FontWeight.w600,
          color: style.foreground,
        );

        return AnimatedScale(
          scale: focused && !busy && !disabled ? 1.03 : 1,
          duration: TvMotion.focusDuration,
          curve: TvMotion.focus,
          child: Opacity(
            opacity: disabled ? 0.5 : 1,
            child: AnimatedContainer(
              duration: TvMotion.focusDuration,
              curve: TvMotion.focus,
              constraints: BoxConstraints(minHeight: minHeight),
              // CSS border-box: a border adds to the padding box, so bordered variants stand 2px taller.
              padding:
                  padding +
                  EdgeInsets.all(
                    style.border == null ? 0 : _VariantStyle.borderWidth,
                  ),
              decoration: BoxDecoration(
                color: style.fill,
                gradient: style.gradient,
                border: style.border == null
                    ? null
                    : Border.all(
                        color: style.border!,
                        width: _VariantStyle.borderWidth,
                      ),
                borderRadius: _pill,
                boxShadow: style.shadow,
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: style.foreground, size: 1.25 * rem),
                child: DefaultTextStyle(
                  style: foreground,
                  child: Row(
                    mainAxisSize: fullWidth
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 0.75 * rem,
                    children: [
                      if (busy)
                        const LoadingDots()
                      else if (icon != null)
                        Icon(icon),
                      Flexible(
                        child: Text(
                          busy ? busyLabel ?? label : label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VariantStyle {
  const _VariantStyle({
    required this.foreground,
    this.fill,
    this.gradient,
    this.border,
    this.shadow,
  });

  static const double borderWidth = 2 * px;

  final Color foreground;
  final Color? fill;
  final Gradient? gradient;
  final Color? border;
  final List<BoxShadow>? shadow;

  static _VariantStyle of(
    TvButtonVariant variant, {
    required bool focused,
  }) => switch ((variant, focused)) {
    // Focus darkens the same ramp rather than swapping hue.
    (TvButtonVariant.primary, true) => _VariantStyle(
      foreground: Colors.white,
      gradient: TvColors.brandBold,
      shadow: TvShadows.lg(TvColors.primary.withValues(alpha: 0.3)),
    ),
    (TvButtonVariant.primary, false) => _VariantStyle(
      foreground: Colors.white,
      gradient: TvColors.brand,
      shadow: TvShadows.lg(TvColors.primary.withValues(alpha: 0.25)),
    ),
    (TvButtonVariant.outline, true) => _VariantStyle(
      foreground: TvColors.primary,
      fill: TvColors.primary.withValues(alpha: 0.1),
      border: TvColors.primary,
    ),
    // Solid, not a tint: a faint outline read as no button at all until focus arrived.
    (TvButtonVariant.outline, false) => const _VariantStyle(
      foreground: TvColors.foreground,
      fill: Colors.white,
      border: TvColors.primary,
    ),
    (TvButtonVariant.quiet, true) => const _VariantStyle(
      foreground: TvColors.foreground,
      fill: TvColors.muted,
    ),
    (TvButtonVariant.quiet, false) => const _VariantStyle(
      foreground: TvColors.foreground,
      fill: Color(0xB3FFFFFF),
    ),
    (TvButtonVariant.danger, true) => const _VariantStyle(
      foreground: Colors.white,
      fill: TvColors.destructive,
      border: TvColors.destructive,
    ),
    (TvButtonVariant.danger, false) => _VariantStyle(
      foreground: TvColors.destructive,
      fill: Colors.white,
      border: TvColors.destructive.withValues(alpha: 0.3),
    ),
  };
}
