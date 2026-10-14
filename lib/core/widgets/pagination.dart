import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';
import 'tv_button.dart';

/// Previous / next paging. Page numbers are not individually selectable: on a D-pad, ten numbered targets
/// cost more presses than they save. Hidden when everything fits on one page.
class Pagination extends StatelessWidget {
  const Pagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onChanged,
  });

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onChanged;

  static int lastPageOf(int total, int pageSize) =>
      pageSize <= 0 ? 1 : (total / pageSize).ceil().clamp(1, 1 << 30);

  @override
  Widget build(BuildContext context) {
    final lastPage = lastPageOf(total, pageSize);
    if (total == 0 || lastPage == 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2 * rem),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 1.5 * rem,
        children: [
          TvButton(
            label: 'Previous',
            icon: LucideIcons.chevronLeft,
            variant: TvButtonVariant.outline,
            size: TvButtonSize.sm,
            disabled: page <= 1,
            onSelect: () => onChanged(page - 1),
          ),
          Text(
            'Page $page of $lastPage · $total total',
            style: TvText.sm.copyWith(
              fontWeight: FontWeight.w500,
              color: TvColors.mutedForeground,
            ),
          ),
          TvButton(
            label: 'Next',
            trailingIcon: LucideIcons.chevronRight,
            variant: TvButtonVariant.outline,
            size: TvButtonSize.sm,
            disabled: page >= lastPage,
            onSelect: () => onChanged(page + 1),
          ),
        ],
      ),
    );
  }
}
