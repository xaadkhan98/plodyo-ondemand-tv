import 'package:flutter/material.dart';
import '../../data/models/media_item.dart';
import '../theme/tv_colors.dart';
import '../theme/tv_typography.dart';
import '../constants/app_constants.dart';
import 'tv_focusable.dart';

enum TvCardVariant {
  poster,
  backdrop,
}

/// TV Media Card supporting Poster and Backdrop layouts with focus animations.
class TvCard extends StatelessWidget {
  const TvCard({
    super.key,
    required this.item,
    this.onTap,
    this.onFocusChange,
    this.variant = TvCardVariant.poster,
    this.autofocus = false,
  });

  final MediaItem item;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFocusChange;
  final TvCardVariant variant;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isBackdrop = variant == TvCardVariant.backdrop;
    final cardWidth = isBackdrop ? AppConstants.backdropWidth : AppConstants.posterWidth;
    final cardHeight = isBackdrop ? AppConstants.backdropHeight : AppConstants.posterHeight;
    final imageUrl = isBackdrop ? item.backdropUrl : item.posterUrl;

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onTap,
      onFocusChange: onFocusChange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: TvColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with fallback pattern
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallback(isBackdrop);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholder();
              },
            ),

            // Subtle gradient overlay for text readability
            Container(
              decoration: const BoxDecoration(
                gradient: TvColors.cardGradient,
              ),
            ),

            // Badges & Details
            Positioned(
              top: 8,
              right: 8,
              child: _buildRatingBadge(),
            ),

            // Item Title & Category
            Positioned(
              left: 10,
              right: 10,
              bottom: item.isContinueWatching ? 16 : 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: TvTypography.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.releaseYear} • ${item.category}',
                    style: TvTypography.cardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Progress bar for Continue Watching
            if (item.isContinueWatching)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 4,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(TvColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: TvColors.ratingBadge),
          const SizedBox(width: 3),
          Text(
            item.rating.toStringAsFixed(1),
            style: TvTypography.badge,
          ),
        ],
      ),
    );
  }

  Widget _buildFallback(bool isBackdrop) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TvColors.surfaceElevated,
            TvColors.surface,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          isBackdrop ? Icons.movie_creation_outlined : Icons.tv_rounded,
          size: isBackdrop ? 40 : 32,
          color: TvColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: TvColors.surface,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(TvColors.textMuted),
          ),
        ),
      ),
    );
  }
}
