import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';

/// Two columns with equal heights per row, like the reference's `grid grid-cols-2 gap-4`.
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({super.key, required this.children});

  /// Cells in reading order; wrap one in [WideCell] to span both columns.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[];
    for (final child in children) {
      if (child is WideCell ||
          rows.isEmpty ||
          rows.last.length == 2 ||
          rows.last.first is WideCell) {
        rows.add([child]);
      } else {
        rows.last.add(child);
      }
    }
    return Column(
      spacing: rem,
      children: [
        for (final row in rows)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: rem,
              children: [
                for (final cell in row) Expanded(child: cell),
                // A lone cell keeps half the width, as a grid cell would.
                if (row.length == 1 && row.first is! WideCell) const Spacer(),
              ],
            ),
          ),
      ],
    );
  }
}

/// A [TwoColumnGrid] cell spanning both columns (`col-span-2`).
class WideCell extends StatelessWidget {
  const WideCell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// One labelled fact on a detail screen: one fact per card, so support can read them out one at a time.
class DetailCard extends StatelessWidget {
  const DetailCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  /// The common case: a plain text value.
  DetailCard.text({
    Key? key,
    required String label,
    required String value,
    IconData? icon,
  }) : this(key: key, label: label, value: Text(value), icon: icon);

  final String label;
  final Widget value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 1.5 * rem,
        vertical: 1.25 * rem,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rem),
        border: Border.all(color: TvColors.border, width: 2 * px),
      ),
      child: Row(
        spacing: rem,
        children: [
          if (icon != null)
            Icon(icon, size: 1.5 * rem, color: TvColors.mutedForeground),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TvText.sm.copyWith(color: TvColors.mutedForeground),
                ),
                if (icon == null) const SizedBox(height: 0.125 * rem),
                DefaultTextStyle(
                  style: TvText.base.copyWith(fontWeight: FontWeight.w500),
                  child: value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
