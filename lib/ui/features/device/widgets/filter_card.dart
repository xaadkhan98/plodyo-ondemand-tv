import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/outset_shadow.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/models/device_models.dart';
import '../device_controller.dart';

/// One chip in a filter group. A null value is "any": no filter at all, which the API takes as omission.
class FilterOption {
  const FilterOption({required this.value, required this.label, this.emoji});

  final String? value;
  final String label;

  /// Picked before the label is read: the chips are for kids too.
  final String? emoji;
}

class FilterGroup {
  const FilterGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChange,
  });

  final String label;
  final String? value;
  final List<FilterOption> options;
  final ValueChanged<String?> onChange;
}

/// "Who's watching": the room's age buckets, held by the session so the pick survives moving between
/// screens. Null when the room offers none.
FilterGroup? ageFilter(LibrarySession device) {
  final groups = device.config?.ageGroups ?? const [];
  if (groups.isEmpty) return null;
  return FilterGroup(
    label: "Who's watching",
    value: device.ageGroup?.code,
    options: [
      const FilterOption(value: null, label: 'All ages', emoji: '✨'),
      for (final group in groups)
        FilterOption(value: group.code, label: group.label, emoji: group.emoji),
    ],
    onChange: (code) => device.chooseAgeGroup(AgeGroup.parse(code)),
  );
}

/// Every filter behind one pill. Closed, the current picks stay on show so nobody has to open it to know
/// what they are looking at; open, it is one card of chips the D-pad walks straight down into.
class FilterCard extends StatefulWidget {
  const FilterCard({super.key, required this.groups});

  final List<FilterGroup> groups;

  @override
  State<FilterCard> createState() => _FilterCardState();
}

class _FilterCardState extends State<FilterCard> {
  static final _shadow = [TvShadows.css(const Color(0x994C1D95), 14, 34, -24)];
  static const _radius = BorderRadius.all(Radius.circular(2 * rem));

  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return const SizedBox.shrink();
    final picked = [
      for (final group in widget.groups)
        ...group.options.where((option) => option.value == group.value),
    ];
    // No backdrop blur: over the canvas's smooth gradient it changes nothing but the frame rate.
    // The shadow is outset only, or it would tint the translucent fill.
    return OutsetShadow(
      shadows: _shadow,
      borderRadius: _radius,
      child: Container(
        padding: const EdgeInsets.all(0.75 * rem),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: _radius,
          border: Border.all(color: Colors.white, width: 2 * px),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 0.75 * rem,
              runSpacing: 0.75 * rem,
              children: [
                _Toggle(
                  open: _open,
                  onSelect: () => setState(() => _open = !_open),
                ),
                if (!_open)
                  for (final option in picked) _Picked(option),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: TvMotion.focus,
              switchOutCurve: TvMotion.focus,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  alignment: AlignmentDirectional.topStart,
                  child: child,
                ),
              ),
              child: _open
                  ? Padding(
                      key: const ValueKey(true),
                      padding: const EdgeInsets.fromLTRB(
                        0.25 * rem,
                        rem,
                        0.25 * rem,
                        0.25 * rem,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: rem,
                        children: [
                          for (final group in widget.groups)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 0.5 * rem,
                              children: [
                                Text(
                                  group.label,
                                  style: TvText.sm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: TvColors.mutedForeground,
                                  ),
                                ),
                                Wrap(
                                  spacing: 0.75 * rem,
                                  runSpacing: 0.75 * rem,
                                  children: [
                                    for (final option in group.options)
                                      _Chip(group: group, option: option),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey(false),
                      width: double.infinity,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

const _pill = BorderRadius.all(Radius.circular(999));

/// A floor in px: these are a child's targets too.
const _minHeight = BoxConstraints(minHeight: 48 * px);

/// The emoji and label every pill in the card carries, in the ambient text style.
class _Label extends StatelessWidget {
  const _Label(this.option, {this.emojiSize = 1.125 * rem});

  final FilterOption option;
  final double emojiSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 0.5 * rem,
    children: [
      if (option.emoji case final face?)
        ExcludeSemantics(
          child: Text(face, style: TextStyle(fontSize: emojiSize)),
        ),
      Text(option.label),
    ],
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.open, required this.onSelect});

  final bool open;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      borderRadius: _pill,
      semanticLabel: open ? 'Done' : 'Filters',
      onSelect: onSelect,
      builder: (context, focused) {
        final lit = focused || open;
        final ink = lit ? Colors.white : TvColors.primaryInk;
        return AnimatedContainer(
          duration: TvMotion.focusDuration,
          constraints: _minHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: 1.5 * rem,
            vertical: 0.5 * rem,
          ),
          decoration: BoxDecoration(
            color: lit ? null : TvColors.secondary,
            gradient: lit ? TvColors.brandBold : null,
            borderRadius: _pill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 0.5 * rem,
            children: [
              Text(
                open ? 'Done' : 'Filters',
                style: TvText.sm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: TvMotion.focusDuration,
                child: Icon(
                  LucideIcons.chevronDown500,
                  size: 1.25 * rem,
                  color: ink,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A current pick, on show while the card is closed. Not focusable: the toggle is the way in.
class _Picked extends StatelessWidget {
  const _Picked(this.option);

  final FilterOption option;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: _minHeight,
      padding: const EdgeInsets.symmetric(horizontal: 1.25 * rem),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: _pill,
        boxShadow: [BoxShadow(color: Color(0x0F000000), spreadRadius: px)],
      ),
      child: DefaultTextStyle(
        style: TvText.sm.copyWith(fontWeight: FontWeight.w600),
        child: _Label(option),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.group, required this.option});

  final FilterGroup group;
  final FilterOption option;

  static const _border = 2 * px;
  static final _spring = SpringCurve(
    stiffness: 340,
    damping: 24,
    duration: const Duration(milliseconds: 400),
  );

  @override
  Widget build(BuildContext context) {
    final selected = option.value == group.value;
    return Semantics(
      selected: selected,
      child: TvFocusable(
        borderRadius: _pill,
        semanticLabel: option.label,
        onSelect: () => group.onChange(option.value),
        builder: (context, focused) {
          final (fill, gradient, edge, ink) = switch ((selected, focused)) {
            (true, _) => (
              null,
              TvColors.brandBold,
              Colors.transparent,
              Colors.white,
            ),
            (false, true) => (
              TvColors.primary.withValues(alpha: 0.1),
              null,
              TvColors.primary,
              TvColors.primaryInk,
            ),
            _ => (Colors.white, null, TvColors.border, TvColors.foreground),
          };
          return AnimatedScale(
            scale: focused ? 1.06 : 1,
            duration: _spring.duration,
            curve: _spring,
            child: AnimatedContainer(
              duration: TvMotion.focusDuration,
              constraints: _minHeight,
              // CSS border-box: the border sits outside the padding.
              padding: const EdgeInsets.symmetric(
                horizontal: 1.5 * rem + _border,
                vertical: 0.5 * rem + _border,
              ),
              decoration: BoxDecoration(
                color: fill,
                gradient: gradient,
                borderRadius: _pill,
                border: Border.all(color: edge, width: _border),
              ),
              child: DefaultTextStyle(
                style: TvText.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
                child: _Label(option, emojiSize: 1.375 * rem),
              ),
            ),
          );
        },
      ),
    );
  }
}
