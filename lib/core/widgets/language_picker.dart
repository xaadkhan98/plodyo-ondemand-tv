import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/languages.dart';
import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_shadows.dart';
import '../theme/tv_typography.dart';
import 'language_flag.dart';
import 'tv_focusable.dart';

/// Picks a catalogue language. A grid rather than a list, so every option is on screen and the D-pad has two
/// axes; not free text, because the API rejects anything but its own codes. Null means "none": [noneLabel]
/// says what that means here, e.g. "Not set" or "Follows the property".
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.noneLabel,
    this.label = 'Default language',
    this.options = languages,
    this.columns = 5,
    this.disabled = false,
    this.autofocus = false,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String noneLabel;
  final String? label;
  final List<Language> options;

  /// Four beside a form, five where the picker owns the screen.
  final int columns;
  final bool disabled;

  /// Opens where the viewer left it: the chosen tile takes first focus. Off inside a form, whose first field leads.
  final bool autofocus;

  static const double _gap = 0.625 * rem;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (var i = 0; i < options.length; i += columns)
        options.sublist(i, (i + columns).clamp(0, options.length)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Row(
            spacing: 0.5 * rem,
            children: [
              const Icon(
                LucideIcons.languages,
                size: 1.25 * rem,
                color: TvColors.mutedForeground,
              ),
              Text(
                label!,
                style: TvText.sm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: TvColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 0.75 * rem),
        ],
        // A full row of its own: "none" or "inherit" is a different kind of answer from a language.
        _Tile(
          label: noneLabel,
          selected: value == null,
          autofocus: autofocus && value == null,
          disabled: disabled,
          onSelect: () => onChanged(null),
        ),
        for (final row in rows) ...[
          const SizedBox(height: _gap),
          Row(
            spacing: _gap,
            children: [
              for (final language in row)
                Expanded(
                  child: _Tile(
                    label: language.name,
                    code: language.code,
                    selected: value == language.code,
                    autofocus: autofocus && value == language.code,
                    disabled: disabled,
                    onSelect: () => onChanged(language.code),
                  ),
                ),
              // Keep a short last row on the grid's columns.
              for (var i = row.length; i < columns; i++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onSelect,
    this.code,
    this.autofocus = false,
  });

  final String label;
  final String? code;
  final bool selected;
  final bool disabled;
  final bool autofocus;
  final VoidCallback onSelect;

  static const _radius = BorderRadius.all(Radius.circular(rem));

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      disabled: disabled,
      // The tile fills on focus; in a grid this tight an outset ring would crowd its neighbours.
      ring: false,
      borderRadius: _radius,
      semanticLabel: label,
      onSelect: onSelect,
      builder: (context, focused) {
        final lit = focused && !disabled;
        final ink = lit
            ? Colors.white
            : (selected ? TvColors.primary : TvColors.foreground);
        return AnimatedScale(
          scale: lit ? 1.04 : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4.25 * rem,
            padding: const EdgeInsets.symmetric(horizontal: rem),
            decoration: BoxDecoration(
              color: lit
                  ? null
                  : (selected
                        ? TvColors.primary.withValues(alpha: 0.1)
                        : Colors.white),
              gradient: lit ? TvColors.brand : null,
              borderRadius: _radius,
              border: Border.all(
                color: lit
                    ? Colors.transparent
                    : (selected ? TvColors.primary : TvColors.border),
                width: 2 * px,
              ),
              boxShadow: lit
                  ? TvShadows.lg(TvColors.primary.withValues(alpha: 0.25))
                  : null,
            ),
            child: Row(
              spacing: 0.75 * rem,
              children: [
                if (code != null)
                  LanguageFlag(
                    code: code,
                    width: 2.6 * rem,
                    height: 1.75 * rem,
                    fallback: _CodeChip(code!, lit: lit),
                  ),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvText.base.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
                // Reserved even when unselected, so a check appearing never reflows the name.
                Container(
                  width: 1.75 * rem,
                  height: 1.75 * rem,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? (lit
                              ? Colors.white.withValues(alpha: 0.25)
                              : TvColors.primary)
                        : null,
                  ),
                  child: selected
                      ? const Icon(
                          LucideIcons.check600,
                          size: 1.25 * rem,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Stands in for a flag where a language has none mapped.
class _CodeChip extends StatelessWidget {
  const _CodeChip(this.code, {required this.lit});

  final String code;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 0.5 * rem,
        vertical: 0.125 * rem,
      ),
      decoration: BoxDecoration(
        color: lit ? Colors.white.withValues(alpha: 0.2) : TvColors.secondary,
        borderRadius: BorderRadius.circular(0.65 * rem),
      ),
      child: Text(
        code,
        style: TvText.sm.copyWith(
          fontWeight: FontWeight.w600,
          color: lit ? Colors.white : TvColors.mutedForeground,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
