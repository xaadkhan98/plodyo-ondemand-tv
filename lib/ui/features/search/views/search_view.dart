import 'package:flutter/material.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/tv_card.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/models/media_item.dart';
import '../../../../data/repositories/mock_vod_repository.dart';

/// TV Search View with category quick-filters and results grid.
class SearchView extends StatefulWidget {
  const SearchView({
    super.key,
    required this.onMediaSelected,
  });

  final ValueChanged<MediaItem> onMediaSelected;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final VodRepository _repository = MockVodRepository();
  final TextEditingController _searchController = TextEditingController();

  List<MediaItem> _results = [];
  bool _isLoading = false;
  String _selectedGenre = 'All';

  final List<String> _genres = [
    'All',
    'Action',
    'Sci-Fi',
    'Thriller',
    'Drama',
    'Mystery',
    'Series',
  ];

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    final allItems = await _repository.searchCatalog(query);

    if (mounted) {
      setState(() {
        if (_selectedGenre == 'All') {
          _results = allItems;
        } else if (_selectedGenre == 'Series') {
          _results = allItems.where((i) => i.type == MediaType.series).toList();
        } else {
          _results = allItems.where((i) => i.genres.contains(_selectedGenre)).toList();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search & Explore',
            style: TvTypography.sectionTitle.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 16),

          // Search Field & Quick Filter Pills
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: TvColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _performSearch,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Search movies, shows, actors...',
                      hintStyle: TextStyle(color: TvColors.textMuted),
                      prefixIcon: Icon(Icons.search_rounded, color: TvColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Genre filter row
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _genres.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final genre = _genres[index];
                final isSelected = _selectedGenre == genre;

                return TvFocusable(
                  onPressed: () {
                    setState(() {
                      _selectedGenre = genre;
                    });
                    _performSearch(_searchController.text);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? TvColors.primary : TvColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: isSelected ? Colors.black : TvColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Results Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(TvColors.primary),
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.movie_filter_outlined, size: 48, color: TvColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No matching titles found', style: TvTypography.body),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return TvCard(
                            item: item,
                            variant: TvCardVariant.poster,
                            onTap: () => widget.onMediaSelected(item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
