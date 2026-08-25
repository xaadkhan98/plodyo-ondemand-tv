import '../models/media_item.dart';

/// Repository interface for catalog operations.
abstract class VodRepository {
  Future<MediaItem> getHeroFeatured();
  Future<List<MediaItem>> getContinueWatching();
  Future<List<MediaItem>> getTrendingMovies();
  Future<List<MediaItem>> getPopularSeries();
  Future<List<MediaItem>> getActionMovies();
  Future<List<MediaItem>> getSciFiCatalog();
  Future<List<MediaItem>> searchCatalog(String query);
}

/// Mock VOD Repository providing rich catalog data for development and testing.
class MockVodRepository implements VodRepository {
  static const List<MediaItem> _catalog = [
    MediaItem(
      id: 'm1',
      title: 'Neon Odyssey 2099',
      category: 'Sci-Fi & Cyberpunk',
      posterUrl: 'https://picsum.photos/seed/neon/400/600',
      backdropUrl: 'https://picsum.photos/seed/neon_hero/1280/720',
      rating: 8.9,
      duration: '2h 18m',
      releaseYear: 2025,
      description: 'In a rain-soaked metropolis ruled by rogue AI corporations, a retired synthetic detective is pulled into one final case that threatens to rewrite human consciousness.',
      genres: ['Sci-Fi', 'Action', 'Thriller'],
      cast: ['Marcus Vance', 'Elena Rostova', 'Kenji Sato'],
      progress: 0.65,
    ),
    MediaItem(
      id: 'm2',
      title: 'Abyssal Horizon',
      category: 'Deep Sea Mystery',
      posterUrl: 'https://picsum.photos/seed/abyss/400/600',
      backdropUrl: 'https://picsum.photos/seed/abyss_wide/1280/720',
      rating: 8.4,
      duration: '1h 55m',
      releaseYear: 2024,
      description: 'A deep-sea research crew discovering an uncharted oceanic trench encounters an ancient bioluminescent structure with inexplicable energy readings.',
      genres: ['Mystery', 'Sci-Fi', 'Adventure'],
      cast: ['Sarah Jenkins', 'David O\'Connor'],
      progress: 0.3,
    ),
    MediaItem(
      id: 'm3',
      title: 'Quantum Drift',
      category: 'High-Octane Action',
      posterUrl: 'https://picsum.photos/seed/drift/400/600',
      backdropUrl: 'https://picsum.photos/seed/drift_wide/1280/720',
      rating: 7.9,
      duration: '2h 04m',
      releaseYear: 2026,
      description: 'Underground pilots race through dimensional rifts using experimental anti-gravity speeders where one wrong turn means falling outside reality.',
      genres: ['Action', 'Sci-Fi'],
      cast: ['Leo Cruz', 'Aria Sterling'],
    ),
    MediaItem(
      id: 's1',
      title: 'The Silent Grid',
      category: 'Tech Espionage',
      posterUrl: 'https://picsum.photos/seed/grid/400/600',
      backdropUrl: 'https://picsum.photos/seed/grid_wide/1280/720',
      rating: 9.1,
      duration: 'Season 2 • 8 Episodes',
      releaseYear: 2025,
      description: 'An elite counter-intelligence operative races against a phantom hacking syndicate executing blackout attacks on global power infrastructure.',
      type: MediaType.series,
      genres: ['Drama', 'Thriller', 'Crime'],
      cast: ['Rachel Zhao', 'Michael Burke'],
      progress: 0.85,
    ),
    MediaItem(
      id: 's2',
      title: 'Chronicles of Solaria',
      category: 'Space Opera',
      posterUrl: 'https://picsum.photos/seed/solaria/400/600',
      backdropUrl: 'https://picsum.photos/seed/solaria_wide/1280/720',
      rating: 8.8,
      duration: 'Season 1 • 10 Episodes',
      releaseYear: 2024,
      description: 'Factions collide over the control of the last remaining Dyson Sphere in the outer spiral arm of the galaxy.',
      type: MediaType.series,
      genres: ['Fantasy', 'Sci-Fi', 'Drama'],
      cast: ['Theron Cole', 'Lyra Belacqua'],
    ),
    MediaItem(
      id: 'm4',
      title: 'Velocity Apex',
      category: 'Motorsport Drama',
      posterUrl: 'https://picsum.photos/seed/apex/400/600',
      backdropUrl: 'https://picsum.photos/seed/apex_wide/1280/720',
      rating: 8.2,
      duration: '2h 10m',
      releaseYear: 2023,
      description: 'Two rival endurance drivers push each other to the extreme limits of human tolerance in the grueling 24 Hours of Le Mans.',
      genres: ['Drama', 'Sport'],
      cast: ['Christian Bell', 'Lucas Wright'],
    ),
    MediaItem(
      id: 'm5',
      title: 'Ghost Protocol 0',
      category: 'Stealth Thriller',
      posterUrl: 'https://picsum.photos/seed/ghost/400/600',
      backdropUrl: 'https://picsum.photos/seed/ghost_wide/1280/720',
      rating: 7.7,
      duration: '1h 48m',
      releaseYear: 2025,
      description: 'When a covert black-ops team is disavowed mid-mission in Geneva, they must rely on outdated analogue techniques to clear their identities.',
      genres: ['Action', 'Thriller'],
      cast: ['Viktor Kozlov', 'Hannah Abbott'],
    ),
    MediaItem(
      id: 'm6',
      title: 'Starlight Requiem',
      category: 'Interstellar Odyssey',
      posterUrl: 'https://picsum.photos/seed/starlight/400/600',
      backdropUrl: 'https://picsum.photos/seed/starlight_wide/1280/720',
      rating: 9.3,
      duration: '2h 45m',
      releaseYear: 2025,
      description: 'A deep space expedition sent to investigate a mysterious beacon orbiting Proxima Centauri uncovers secrets about the birth of the universe.',
      genres: ['Sci-Fi', 'Drama', 'Adventure'],
      cast: ['Gabriel Stone', 'Amara Hayes'],
    ),
  ];

  @override
  Future<MediaItem> getHeroFeatured() async {
    return _catalog.first;
  }

  @override
  Future<List<MediaItem>> getContinueWatching() async {
    return _catalog.where((item) => item.isContinueWatching).toList();
  }

  @override
  Future<List<MediaItem>> getTrendingMovies() async {
    return _catalog.where((item) => item.type == MediaType.movie).toList();
  }

  @override
  Future<List<MediaItem>> getPopularSeries() async {
    return _catalog.where((item) => item.type == MediaType.series).toList();
  }

  @override
  Future<List<MediaItem>> getActionMovies() async {
    return _catalog.where((item) => item.genres.contains('Action')).toList();
  }

  @override
  Future<List<MediaItem>> getSciFiCatalog() async {
    return _catalog.where((item) => item.genres.contains('Sci-Fi')).toList();
  }

  @override
  Future<List<MediaItem>> searchCatalog(String query) async {
    if (query.trim().isEmpty) return _catalog;
    final lower = query.toLowerCase();
    return _catalog.where((item) {
      return item.title.toLowerCase().contains(lower) ||
          item.category.toLowerCase().contains(lower) ||
          item.genres.any((g) => g.toLowerCase().contains(lower));
    }).toList();
  }
}
