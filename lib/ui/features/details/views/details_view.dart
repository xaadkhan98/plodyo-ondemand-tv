import 'package:flutter/material.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_row.dart';
import '../../../../core/widgets/tv_card.dart';
import '../../../../data/models/media_item.dart';
import '../../../../data/repositories/mock_vod_repository.dart';

/// Full-screen VOD Details View with remote back handler and action buttons.
class DetailsView extends StatefulWidget {
  const DetailsView({
    super.key,
    required this.item,
    required this.onBack,
    required this.onMediaSelected,
  });

  final MediaItem item;
  final VoidCallback onBack;
  final ValueChanged<MediaItem> onMediaSelected;

  @override
  State<DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<DetailsView> {
  List<MediaItem> _similarItems = [];
  bool _isLoadingSimilar = true;

  @override
  void initState() {
    super.initState();
    _loadSimilar();
  }

  @override
  void didUpdateWidget(covariant DetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadSimilar();
    }
  }

  Future<void> _loadSimilar() async {
    setState(() {
      _isLoadingSimilar = true;
    });
    final items = await MockVodRepository().getTrendingMovies();
    if (mounted) {
      setState(() {
        _similarItems = items.where((i) => i.id != widget.item.id).toList();
        _isLoadingSimilar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.onBack();
        }
      },
      child: Scaffold(
        backgroundColor: TvColors.background,
        body: Stack(
          children: [
            // Background Backdrop
            Positioned.fill(
              child: Image.network(
                item.backdropUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: TvColors.surfaceElevated),
              ),
            ),

            // Vignette Gradients
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      TvColors.background,
                      Color(0xE60D0F12),
                      Color(0x990D0F12),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: TvColors.heroGradient,
                ),
              ),
            ),

            // Scrollable Content
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    TvButton(
                      label: 'Back',
                      icon: Icons.arrow_back_rounded,
                      style: TvButtonStyle.tonal,
                      onPressed: widget.onBack,
                    ),

                    const SizedBox(height: 28),

                    // Badges & Meta
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: TvColors.ratingBadge,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'IMDb ${item.rating}',
                            style: TvTypography.badge.copyWith(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: TvColors.hdBadge,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('4K ULTRA HD', style: TvTypography.badge),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${item.releaseYear} • ${item.duration}',
                          style: TvTypography.cardSubtitle.copyWith(fontSize: 15),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      item.title,
                      style: TvTypography.heroTitle.copyWith(fontSize: 48),
                    ),

                    const SizedBox(height: 12),

                    // Genres Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.genres.map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: TvColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(genre, style: TvTypography.cardSubtitle),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Synopsis
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Text(
                        item.description,
                        style: TvTypography.body.copyWith(fontSize: 18),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cast List
                    if (item.cast.isNotEmpty) ...[
                      Text(
                        'Starring: ${item.cast.join(', ')}',
                        style: TvTypography.cardSubtitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        TvButton(
                          label: 'Play',
                          icon: Icons.play_arrow_rounded,
                          autofocus: true,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Starting playback for "${item.title}"...'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        TvButton(
                          label: 'Trailer',
                          icon: Icons.movie_outlined,
                          style: TvButtonStyle.secondary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Playing trailer...')),
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        TvButton(
                          label: 'Add to Watchlist',
                          icon: Icons.add_rounded,
                          style: TvButtonStyle.tonal,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to your Watchlist')),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Similar Titles Rail
                    if (!_isLoadingSimilar && _similarItems.isNotEmpty)
                      TvRow(
                        title: 'More Like This',
                        items: _similarItems,
                        variant: TvCardVariant.poster,
                        onItemTap: widget.onMediaSelected,
                      ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
