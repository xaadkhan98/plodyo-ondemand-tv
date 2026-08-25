/// Type of media asset.
enum MediaType {
  movie,
  series,
  live,
}

/// Represents a VOD / TV media item in the catalog.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.category,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.duration,
    required this.releaseYear,
    required this.description,
    this.type = MediaType.movie,
    this.progress = 0.0, // 0.0 to 1.0 for "Continue Watching"
    this.genres = const [],
    this.cast = const [],
  });

  final String id;
  final String title;
  final String category;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final String duration;
  final int releaseYear;
  final String description;
  final MediaType type;
  final double progress;
  final List<String> genres;
  final List<String> cast;

  bool get isContinueWatching => progress > 0.0;
}
