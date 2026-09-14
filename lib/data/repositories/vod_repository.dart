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
