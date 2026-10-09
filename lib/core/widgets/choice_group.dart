import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';
import 'tv_focusable.dart';

/// One option in a [ChoiceGroup].
class Choice<T> {
  const Choice({required this.value, required this.label, this.description});

  final T value;
  final String label;

  /// Cards only: the consequence of picking this option.
  final String? description;
}

enum ChoiceLayout {
  /// A decision made once and worth understanding; equal-width cards with a description.
  cards,

  /// A filter flicked through repeatedly; wrapping pills.
  chips,
}

/// Single-select for the D-pad. Radios are too small from 3 metres and a native picker opens the TV's own UI,
/// so options are plain focus targets that apply on select — one press, not open-move-confirm.
class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    this.layout = ChoiceLayout.cards,
    this.disabled = false,
    this.autofocus = false,
  });

  final T value;
  final List<Choice<T>> options;
  final ValueChanged<T> onChanged;
  final String? label;
  final ChoiceLayout layout;
  final bool disabled;

  /// Lands first focus on the selected option.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final items = [for (final option in options) _option(option)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0.5 * rem,
      children: [
        if (label != null)
          Text(
            label!,
            style: TvText.sm.copyWith(
              fontWeight: FontWeight.w500,
              color: TvColors.mutedForeground,
            ),
          ),
        if (layout == ChoiceLayout.cards)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 0.75 * rem,
              children: [for (final item in items) Expanded(child: item)],
            ),
          )
        // Wrapping matters: a chip pushed off-screen is a filter nobody can reach.
        else
          Wrap(spacing: 0.75 * rem, runSpacing: 0.75 * rem, children: items),
      ],
    );
  }

  Widget _option(Choice<T> option) {
    final selected = option.value == value;
    final cards = layout == ChoiceLayout.cards;
    final radius = BorderRadius.circular(cards ? rem : 999);

    return TvFocusable(
      autofocus: autofocus && selected,
      onSelect: () => onChanged(option.value),
      disabled: disabled,
      borderRadius: radius,
      semanticLabel: option.label,
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: cards
            ? const BoxConstraints()
            : const BoxConstraints(minHeight: 48 * px),
        padding: cards
            ? const EdgeInsets.symmetric(horizontal: 1.5 * rem, vertical: rem)
            : const EdgeInsets.symmetric(
                horizontal: 1.5 * rem,
                vertical: 0.625 * rem,
              ),
        decoration: BoxDecoration(
          color: focused
              ? TvColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: radius,
          border: Border.all(
            color: focused || selected ? TvColors.primary : TvColors.border,
            width: 2 * px,
          ),
        ),
        child: cards
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 0.25 * rem,
                children: [
                  Text(
                    option.label,
                    style: TvText.base.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _labelColor(selected),
                    ),
                  ),
                  if (option.description != null)
                    Text(
                      option.description!,
                      style: TvText.sm.copyWith(
                        color: TvColors.mutedForeground,
                      ),
                    ),
                ],
              )
            : Text(
                option.label,
                style: TvText.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _labelColor(selected),
                ),
              ),
      ),
    );
  }

  static Color _labelColor(bool selected) =>
      selected ? TvColors.primary : TvColors.foreground;
}
