import 'package:flutter/material.dart';
import '../../data/models/media_item.dart';
import '../theme/tv_typography.dart';
import '../constants/app_constants.dart';
import 'tv_card.dart';

/// Horizontal TV media rail with category header and D-pad navigable cards.
class TvRow extends StatelessWidget {
  const TvRow({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    this.variant = TvCardVariant.poster,
    this.onItemFocusChange,
  });

  final String title;
  final List<MediaItem> items;
  final ValueChanged<MediaItem> onItemTap;
  final TvCardVariant variant;
  final void Function(MediaItem item, bool isFocused)? onItemFocusChange;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final rowHeight = variant == TvCardVariant.backdrop
        ? AppConstants.backdropHeight + 32
        : AppConstants.posterHeight + 32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8),
          child: Text(
            title,
            style: TvTypography.sectionTitle,
          ),
        ),
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return TvCard(
                item: item,
                variant: variant,
                onTap: () => onItemTap(item),
                onFocusChange: (isFocused) {
                  onItemFocusChange?.call(item, isFocused);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
