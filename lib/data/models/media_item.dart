import 'device_models.dart';

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
    this.mediaUrl,
    this.language,
    this.ageGroup,
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
  final String? mediaUrl;
  final String? language;
  final String? ageGroup;

  bool get isContinueWatching => progress > 0.0;

  factory MediaItem.fromDeviceStory(DeviceStoryItem story) {
    final artwork = story.artworkUrl ?? '';
    final defaultPoster = 'https://picsum.photos/seed/${story.id.hashCode}/400/600';
    final defaultBackdrop = 'https://picsum.photos/seed/${story.id.hashCode}_wide/1280/720';

    return MediaItem(
      id: story.id,
      title: story.title,
      category: story.ageGroup != null ? 'Ages ${story.ageGroup}' : (story.language ?? 'Stories'),
      posterUrl: artwork.isNotEmpty ? artwork : defaultPoster,
      backdropUrl: artwork.isNotEmpty ? artwork : defaultBackdrop,
      rating: 9.2,
      duration: story.duration ?? 'Short Story',
      releaseYear: 2026,
      description: story.description ?? 'A wonderful animated story on Plodyo OnDemand.',
      genres: [
        if (story.ageGroup != null) 'Ages ${story.ageGroup}',
        if (story.language != null) story.language!,
        'Plodyo Story',
      ],
      mediaUrl: story.mediaUrl,
      language: story.language,
      ageGroup: story.ageGroup,
    );
  }
}

