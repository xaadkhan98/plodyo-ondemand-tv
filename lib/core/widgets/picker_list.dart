import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';
import 'loading.dart';
import 'status_message.dart';
import 'tv_focusable.dart';

/// One record a [PickerList] offers.
class PickerOption {
  const PickerOption({required this.id, required this.label, this.hint});

  final String id;
  final String label;

  /// A second line that tells two similarly named records apart.
  final String? hint;
}

/// Picks one record from a list the API supplies. A native picker opens the TV's own UI, and ChoiceGroup's row
/// stops working past a handful of options, so this stacks vertically and carries the async list's three states.
class PickerList extends StatelessWidget {
  const PickerList({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.emptyMessage,
    this.label,
    this.icon,
    this.loading = false,
    this.error,
    this.disabled = false,
  });

  final List<PickerOption> options;

  /// The chosen id, or null while nothing is chosen.
  final String? value;
  final ValueChanged<String> onChanged;
  final String emptyMessage;
  final String? label;
  final IconData? icon;
  final bool loading;
  final String? error;
  final bool disabled;

  static const _radius = BorderRadius.all(Radius.circular(rem));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TvText.sm.copyWith(
              fontWeight: FontWeight.w500,
              color: TvColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 0.5 * rem),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2 * rem),
            child: Center(child: LoadingDots(color: TvColors.primary)),
          )
        else if (error != null)
          StatusMessage(tone: StatusTone.error, message: error!)
        else if (options.isEmpty)
          StatusMessage(tone: StatusTone.info, message: emptyMessage)
        else
          // No inner scroller: the page scrolls already, and rows clipped inside one stay focusable unseen.
          for (final (index, option) in options.indexed) ...[
            if (index > 0) const SizedBox(height: 0.5 * rem),
            _row(option),
          ],
      ],
    );
  }

  Widget _row(PickerOption option) {
    final selected = option.id == value;
    return TvFocusable(
      disabled: disabled,
      borderRadius: _radius,
      semanticLabel: option.label,
      onSelect: () => onChanged(option.id),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 1.25 * rem,
          vertical: 0.875 * rem,
        ),
        decoration: BoxDecoration(
          color: focused
              ? TvColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: _radius,
          border: Border.all(
            color: focused || selected ? TvColors.primary : TvColors.border,
            width: 2 * px,
          ),
        ),
        child: Row(
          spacing: rem,
          children: [
            if (icon != null)
              Icon(icon, size: 1.25 * rem, color: TvColors.mutedForeground),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvText.base.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (option.hint case final hint? when hint.isNotEmpty)
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvText.sm.copyWith(
                        color: TvColors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
