import 'package:flutter/material.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/tv_row.dart';
import '../../../../core/widgets/tv_card.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../data/models/media_item.dart';
import '../view_models/home_view_model.dart';

/// Main Home View for TV Screen displaying Hero and Content Rails.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.viewModel,
    required this.onMediaSelected,
  });

  final HomeViewModel viewModel;
  final ValueChanged<MediaItem> onMediaSelected;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TvColors.primary),
            ),
          );
        }

        final hero = viewModel.featuredHero;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Featured Section
              if (hero != null) _buildHeroBanner(context, hero),

              const SizedBox(height: 12),

              // Continue Watching Rail
              if (viewModel.continueWatching.isNotEmpty)
                TvRow(
                  title: 'Continue Watching',
                  items: viewModel.continueWatching,
                  variant: TvCardVariant.backdrop,
                  onItemTap: onMediaSelected,
                ),

              const SizedBox(height: 16),

              // Trending Movies Rail
              TvRow(
                title: 'Trending Movies',
                items: viewModel.trendingMovies,
                variant: TvCardVariant.poster,
                onItemTap: onMediaSelected,
              ),

              const SizedBox(height: 16),

              // Popular TV Shows Rail
              TvRow(
                title: 'Popular TV Series',
                items: viewModel.popularSeries,
                variant: TvCardVariant.poster,
                onItemTap: onMediaSelected,
              ),

              const SizedBox(height: 16),

              // Sci-Fi Rail
              TvRow(
                title: 'Sci-Fi & Cyberpunk',
                items: viewModel.sciFiCatalog,
                variant: TvCardVariant.backdrop,
                onItemTap: onMediaSelected,
              ),

              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, MediaItem hero) {
    return SizedBox(
      height: AppConstants.heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero Backdrop image
          Image.network(
            hero.backdropUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: TvColors.surfaceElevated,
            ),
          ),

          // Cinematic Vignette & Gradients
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  TvColors.background,
                  Color(0xCC0D0F12),
                  Colors.transparent,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: TvColors.heroGradient,
            ),
          ),

          // Hero Content Details
          Positioned(
            left: 36,
            bottom: 24,
            width: 580,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category & Rating Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: TvColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FEATURED',
                        style: TvTypography.badge.copyWith(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '★ ${hero.rating}',
                      style: TvTypography.cardSubtitle.copyWith(
                        color: TvColors.ratingBadge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${hero.releaseYear} • ${hero.duration}',
                      style: TvTypography.cardSubtitle,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Hero Title
                Text(
                  hero.title,
                  style: TvTypography.heroTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Synopsis
                Text(
                  hero.description,
                  style: TvTypography.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    TvButton(
                      label: 'Play Now',
                      icon: Icons.play_arrow_rounded,
                      autofocus: true,
                      onPressed: () => onMediaSelected(hero),
                    ),
                    const SizedBox(width: 14),
                    TvButton(
                      label: 'Details',
                      icon: Icons.info_outline_rounded,
                      style: TvButtonStyle.secondary,
                      onPressed: () => onMediaSelected(hero),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
