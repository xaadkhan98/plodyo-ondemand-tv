import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';
import 'tv_focusable.dart';

/// Numeric entry for a remote: stepping costs one press and cannot produce a malformed value, where typing
/// digits costs the travel between keys. Two step sizes keep both 3 and 240 reachable: −10 −1 [value] +1 +10.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.min = 0,
    this.max = 100000,
    this.steps = const [1, 10],
    this.unit,
    this.disabled = false,
    this.autofocus = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String? label;
  final int min;
  final int max;

  /// Offered as −/+ pairs, finest first.
  final List<int> steps;
  final String? unit;
  final bool disabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    // Coarsest decrement first, so the row reads −10 −1 [value] +1 +10 and left/right do what they say.
    final deltas = [
      for (final step in steps.reversed) -step,
      null,
      for (final step in steps) step,
    ];
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
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 0.75 * rem,
          children: [
            for (final delta in deltas)
              if (delta == null)
                _readout()
              else
                _StepButton(
                  delta: delta,
                  autofocus: autofocus && delta == steps.first,
                  disabled:
                      disabled || (delta < 0 ? value <= min : value >= max),
                  onSelect: () => onChanged((value + delta).clamp(min, max)),
                ),
          ],
        ),
      ],
    );
  }

  Widget _readout() => Semantics(
    liveRegion: true,
    child: Container(
      height: 3.5 * rem,
      constraints: const BoxConstraints(minWidth: 7 * rem),
      padding: const EdgeInsets.symmetric(horizontal: 1.25 * rem),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rem),
        border: Border.all(color: TvColors.border, width: 2 * px),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: 0.5 * rem,
        children: [
          Text(
            '$value',
            style: TvText.lg.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (unit != null)
            Text(
              unit!,
              style: TvText.sm.copyWith(color: TvColors.mutedForeground),
            ),
        ],
      ),
    ),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.delta,
    required this.disabled,
    required this.onSelect,
    this.autofocus = false,
  });

  final int delta;
  final bool disabled;
  final VoidCallback onSelect;
  final bool autofocus;

  static const _radius = BorderRadius.all(Radius.circular(rem));

  @override
  Widget build(BuildContext context) {
    final magnitude = delta.abs();
    return TvFocusable(
      autofocus: autofocus,
      disabled: disabled,
      onSelect: onSelect,
      borderRadius: _radius,
      semanticLabel: '${delta > 0 ? 'Increase' : 'Decrease'} by $magnitude',
      builder: (context, focused) {
        final color = focused ? TvColors.primary : TvColors.mutedForeground;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 4 * rem,
          height: 3.5 * rem,
          decoration: BoxDecoration(
            color: focused
                ? TvColors.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: _radius,
            border: Border.all(
              color: focused ? TvColors.primary : TvColors.border,
              width: 2 * px,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 0.125 * rem,
            children: [
              Icon(
                delta > 0 ? LucideIcons.plus600 : LucideIcons.minus600,
                size: rem,
                color: color,
              ),
              if (magnitude > 1)
                Text(
                  '$magnitude',
                  style: TvText.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
