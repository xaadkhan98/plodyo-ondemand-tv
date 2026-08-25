import 'package:flutter/material.dart';
import '../../core/theme/tv_colors.dart';
import '../../core/theme/tv_typography.dart';
import '../../core/widgets/tv_sidebar.dart';
import '../../core/widgets/tv_button.dart';
import '../../core/widgets/tv_row.dart';
import '../../core/widgets/tv_card.dart';
import '../../data/models/media_item.dart';
import '../../data/repositories/mock_vod_repository.dart';
import 'home/view_models/home_view_model.dart';
import 'home/views/home_view.dart';
import 'details/views/details_view.dart';
import 'search/views/search_view.dart';

/// Main TV Application Shell coordinating Sidebar and Screen Navigation.
class MainTvLayout extends StatefulWidget {
  const MainTvLayout({super.key});

  @override
  State<MainTvLayout> createState() => _MainTvLayoutState();
}

class _MainTvLayoutState extends State<MainTvLayout> {
  int _selectedNavIndex = 0;
  MediaItem? _selectedMedia;

  late final HomeViewModel _homeViewModel;
  final VodRepository _repository = MockVodRepository();

  final List<TvNavigationItem> _navItems = const [
    TvNavigationItem(id: 'home', icon: Icons.home_rounded, label: 'Home'),
    TvNavigationItem(id: 'movies', icon: Icons.movie_rounded, label: 'Movies'),
    TvNavigationItem(id: 'series', icon: Icons.tv_rounded, label: 'Series'),
    TvNavigationItem(id: 'search', icon: Icons.search_rounded, label: 'Search'),
    TvNavigationItem(id: 'settings', icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel(repository: _repository)..loadCatalog();
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    super.dispose();
  }

  void _onMediaSelected(MediaItem item) {
    setState(() {
      _selectedMedia = item;
    });
  }

  void _onBackFromDetails() {
    setState(() {
      _selectedMedia = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If a media item is selected, render full-screen Details view
    if (_selectedMedia != null) {
      return DetailsView(
        item: _selectedMedia!,
        onBack: _onBackFromDetails,
        onMediaSelected: _onMediaSelected,
      );
    }

    return Scaffold(
      backgroundColor: TvColors.background,
      body: Row(
        children: [
          // Collapsible/Expandable TV Sidebar Rail
          TvSidebar(
            items: _navItems,
            selectedIndex: _selectedNavIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
          ),

          // Main View Content Canvas
          Expanded(
            child: IndexedStack(
              index: _selectedNavIndex,
              children: [
                // 0: Home
                HomeView(
                  viewModel: _homeViewModel,
                  onMediaSelected: _onMediaSelected,
                ),

                // 1: Movies
                _buildMoviesCatalogView(),

                // 2: Series
                _buildSeriesCatalogView(),

                // 3: Search
                SearchView(
                  onMediaSelected: _onMediaSelected,
                ),

                // 4: Settings
                _buildSettingsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesCatalogView() {
    return FutureBuilder<List<MediaItem>>(
      future: _repository.getTrendingMovies(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TvColors.primary),
            ),
          );
        }

        final movies = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 16),
                child: Text('Movies On Demand', style: TvTypography.sectionTitle.copyWith(fontSize: 28)),
              ),
              TvRow(
                title: 'Blockbusters & Premieres',
                items: movies,
                variant: TvCardVariant.poster,
                onItemTap: _onMediaSelected,
              ),
              const SizedBox(height: 24),
              TvRow(
                title: 'Featured Backdrops',
                items: movies.reversed.toList(),
                variant: TvCardVariant.backdrop,
                onItemTap: _onMediaSelected,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeriesCatalogView() {
    return FutureBuilder<List<MediaItem>>(
      future: _repository.getPopularSeries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TvColors.primary),
            ),
          );
        }

        final series = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 16),
                child: Text('TV Shows & Series', style: TvTypography.sectionTitle.copyWith(fontSize: 28)),
              ),
              TvRow(
                title: 'Binge-Worthy Dramas',
                items: series,
                variant: TvCardVariant.poster,
                onItemTap: _onMediaSelected,
              ),
              const SizedBox(height: 24),
              TvRow(
                title: 'Popular Episodes',
                items: series,
                variant: TvCardVariant.backdrop,
                onItemTap: _onMediaSelected,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings & Preferences', style: TvTypography.sectionTitle.copyWith(fontSize: 28)),
          const SizedBox(height: 24),
          _buildSettingsTile(
            title: 'Streaming Quality',
            subtitle: 'Automatic (Up to 4K Ultra HD)',
            icon: Icons.high_quality_rounded,
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            title: 'Audio & Subtitles',
            subtitle: 'English (Dolby Atmos / 5.1 Surround)',
            icon: Icons.surround_sound_rounded,
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            title: 'TV Device Info',
            subtitle: 'Plodyo OnDemand TV v1.0.0 (Build 1)',
            icon: Icons.tv_rounded,
          ),
          const SizedBox(height: 24),
          TvButton(
            label: 'Check for Updates',
            icon: Icons.system_update_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App is up to date!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: TvColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: TvColors.primary, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TvTypography.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: TvTypography.cardSubtitle),
            ],
          ),
        ],
      ),
    );
  }
}
