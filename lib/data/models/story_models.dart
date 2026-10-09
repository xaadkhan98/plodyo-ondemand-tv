/// Omitted from a query, the catalogue mixes standalone stories and series episodes.
enum StoryType {
  standalone('STANDALONE'),
  entertainmentSeries('ENTERTAINMENT_SERIES'),
  learningSeries('LEARNING_SERIES');

  const StoryType(this.code);

  final String code;
}

enum SeriesType {
  entertainment('ENTERTAINMENT'),
  learning('LEARNING');

  const SeriesType(this.code);

  final String code;

  static SeriesType? parse(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// One catalogue row. Rows carry no media URL, so a grid never mints a signed URL per unwatched tile.
class Story {
  const Story({
    required this.id,
    required this.title,
    this.description,
    this.artworkUrl,
    this.duration,
    this.language,
    this.ageGroup,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    artworkUrl: json['artwork_url'] as String?,
    duration: json['duration'] as String?,
    language: json['language'] as String?,
    ageGroup: json['age_group'] as String?,
  );

  final String id;
  final String title;
  final String? description;
  final String? artworkUrl;

  /// A bucket such as "short", not a number of seconds; a series card puts its episode count here.
  final String? duration;
  final String? language;
  final String? ageGroup;
}

class StoryPage {
  const StoryPage({
    required this.pageNumber,
    required this.text,
    this.title,
    this.imageUrl,
    this.audioUrl,
  });

  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
    pageNumber: (json['page_number'] as num).toInt(),
    title: json['title'] as String?,
    text: json['text'] as String,
    imageUrl: json['image_url'] as String?,
    audioUrl: json['audio_url'] as String?,
  );

  final int pageNumber;
  final String? title;
  final String text;
  final String? imageUrl;

  /// Null until the page has been narrated.
  final String? audioUrl;
}

/// The playable story, fetched at the moment of playback.
class StoryDetail {
  const StoryDetail({
    required this.story,
    this.mediaUrl,
    this.pages = const [],
  });

  factory StoryDetail.fromJson(Map<String, dynamic> json) => StoryDetail(
    story: Story.fromJson(json),
    mediaUrl: json['media_url'] as String?,
    pages: [
      for (final page
          in (json['pages'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        StoryPage.fromJson(page),
    ],
  );

  final Story story;

  /// Null when the story has no generated video yet.
  final String? mediaUrl;

  /// The picture book, present whether or not a video was ever made.
  final List<StoryPage> pages;
}

class Series {
  const Series({
    required this.id,
    required this.title,
    required this.category,
    required this.ageGroup,
    required this.language,
    required this.episodeCount,
    this.description,
    this.learningObjective,
    this.seriesType,
    this.artworkUrl,
  });

  factory Series.fromJson(Map<String, dynamic> json) => Series(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    learningObjective: json['learning_objective'] as String?,
    seriesType: SeriesType.parse(json['series_type'] as String?),
    category: json['category'] as String,
    ageGroup: json['age_group'] as String,
    language: json['language'] as String,
    artworkUrl: json['artwork_url'] as String?,
    episodeCount: (json['episode_count'] as num).toInt(),
  );

  final String id;
  final String title;
  final String? description;
  final String? learningObjective;
  final SeriesType? seriesType;
  final String category;
  final String ageGroup;
  final String language;
  final String? artworkUrl;

  /// Episodes planned, which can exceed the episodes actually servable.
  final int episodeCount;
}

/// An episode is a story keyed by its story id, since playback is per story.
class SeriesEpisode {
  const SeriesEpisode({required this.episodeNumber, required this.story});

  factory SeriesEpisode.fromJson(Map<String, dynamic> json) => SeriesEpisode(
    episodeNumber: (json['episode_number'] as num).toInt(),
    story: Story(
      id: json['story_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      artworkUrl: json['artwork_url'] as String?,
      duration: json['duration'] as String?,
    ),
  );

  final int episodeNumber;
  final Story story;
}

class SeriesDetail {
  const SeriesDetail({required this.series, required this.episodes});

  factory SeriesDetail.fromJson(Map<String, dynamic> json) => SeriesDetail(
    series: Series.fromJson(json),
    episodes: [
      for (final episode
          in (json['episodes'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        SeriesEpisode.fromJson(episode),
    ],
  );

  final Series series;

  /// Servable episodes only, in order: never the full planned run.
  final List<SeriesEpisode> episodes;
}
