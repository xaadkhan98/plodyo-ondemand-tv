import '../models/device_models.dart';
import '../models/media_item.dart';
import '../models/paginated_response.dart';
import '../services/device_api_service.dart';
import 'vod_repository.dart';

/// Global shared instance of [DeviceRepository] for TV device state and catalog.
final DeviceRepository sharedDeviceRepository = DeviceRepositoryImpl();

/// Repository for Room TV device operations (pairing, session, config, and live catalogue).
abstract class DeviceRepository implements VodRepository {
  /// Pairs this TV using the 8-character pairing code from the console.
  Future<DevicePairResponse> pair(String pairingCode);

  /// Opens or retrieves the room session.
  Future<DeviceSession> getSession();

  /// Retrieves language and age group options for this TV.
  Future<DeviceConfig> getConfig();

  /// Retrieves the stories catalog with optional language and age group filtering.
  Future<PaginatedResponse<DeviceStoryItem>> getCatalogue({
    String? language,
    String? ageGroup,
    int? page,
    int? pageSize,
  });

  /// Fetches full story detail with the playback `media_url`.
  Future<DeviceStoryItem> getStoryDetail(String storyId);

  /// Clears the paired device token.
  void unpair();

  /// Current device token if paired.
  String? get deviceToken;

  /// Whether this TV has a stored device token.
  bool get isPaired;

  /// Cached device config (languages, age-groups).
  DeviceConfig? get currentConfig;

  /// Cached device session.
  DeviceSession? get currentSession;
}

/// Concrete implementation of [DeviceRepository] talking directly to [DeviceApiService].
class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({
    DeviceApiService? apiService,
  }) : _apiService = apiService ?? DeviceApiService();

  final DeviceApiService _apiService;

  String? _deviceToken;
  DeviceConfig? _currentConfig;
  DeviceSession? _currentSession;
  List<DeviceStoryItem> _cachedStories = [];

  @override
  String? get deviceToken => _deviceToken;

  @override
  bool get isPaired => _deviceToken != null && _deviceToken!.isNotEmpty;

  @override
  DeviceConfig? get currentConfig => _currentConfig;

  @override
  DeviceSession? get currentSession => _currentSession;

  @override
  Future<DevicePairResponse> pair(String pairingCode) async {
    final response = await _apiService.pair(pairingCode: pairingCode);
    _deviceToken = response.deviceToken;
    return response;
  }

  @override
  Future<DeviceSession> getSession() async {
    final token = _deviceToken ?? '';
    final session = await _apiService.getSession(deviceToken: token);
    _currentSession = session;
    return session;
  }

  @override
  Future<DeviceConfig> getConfig() async {
    final token = _deviceToken ?? '';
    final config = await _apiService.getConfig(deviceToken: token);
    _currentConfig = config;
    return config;
  }

  @override
  Future<PaginatedResponse<DeviceStoryItem>> getCatalogue({
    String? language,
    String? ageGroup,
    int? page,
    int? pageSize,
  }) async {
    final token = _deviceToken ?? '';
    final response = await _apiService.getContent(
      deviceToken: token,
      language: language,
      ageGroup: ageGroup,
      page: page,
      pageSize: pageSize,
    );
    _cachedStories = response.data;
    return response;
  }

  @override
  Future<DeviceStoryItem> getStoryDetail(String storyId) {
    final token = _deviceToken ?? '';
    return _apiService.getStoryDetail(
      deviceToken: token,
      storyId: storyId,
    );
  }

  @override
  void unpair() {
    _deviceToken = null;
    _currentConfig = null;
    _currentSession = null;
    _cachedStories = [];
  }

  // --- VodRepository Implementation backed by live Backend Catalog ---

  Future<List<MediaItem>> _fetchOrGetStories() async {
    if (_cachedStories.isEmpty) {
      try {
        final res = await getCatalogue(pageSize: 50);
        _cachedStories = res.data;
      } catch (_) {
        return [];
      }
    }
    return _cachedStories.map(MediaItem.fromDeviceStory).toList();
  }

  @override
  Future<MediaItem> getHeroFeatured() async {
    final items = await _fetchOrGetStories();
    if (items.isNotEmpty) return items.first;
    return const MediaItem(
      id: 'featured_default',
      title: 'Plodyo OnDemand Stories',
      category: 'Family & Children',
      posterUrl: 'https://picsum.photos/seed/plodyo_poster/400/600',
      backdropUrl: 'https://picsum.photos/seed/plodyo_hero/1280/720',
      rating: 9.5,
      duration: 'Animated Series',
      releaseYear: 2026,
      description: 'Explore the wondrous catalog of multilingual animated stories for children and families.',
      genres: ['Animated', 'Family', 'Educational'],
    );
  }

  @override
  Future<List<MediaItem>> getContinueWatching() async {
    final items = await _fetchOrGetStories();
    return items.take(4).map((i) => MediaItem(
      id: i.id,
      title: i.title,
      category: i.category,
      posterUrl: i.posterUrl,
      backdropUrl: i.backdropUrl,
      rating: i.rating,
      duration: i.duration,
      releaseYear: i.releaseYear,
      description: i.description,
      genres: i.genres,
      mediaUrl: i.mediaUrl,
      progress: 0.5,
    )).toList();
  }

  @override
  Future<List<MediaItem>> getTrendingMovies() async {
    final items = await _fetchOrGetStories();
    return items;
  }

  @override
  Future<List<MediaItem>> getPopularSeries() async {
    final items = await _fetchOrGetStories();
    return items.reversed.toList();
  }

  @override
  Future<List<MediaItem>> getActionMovies() async {
    final items = await _fetchOrGetStories();
    return items;
  }

  @override
  Future<List<MediaItem>> getSciFiCatalog() async {
    final items = await _fetchOrGetStories();
    return items;
  }

  @override
  Future<List<MediaItem>> searchCatalog(String query) async {
    final items = await _fetchOrGetStories();
    if (query.trim().isEmpty) return items;
    final lower = query.toLowerCase();
    return items.where((item) {
      return item.title.toLowerCase().contains(lower) ||
          item.category.toLowerCase().contains(lower) ||
          item.genres.any((g) => g.toLowerCase().contains(lower));
    }).toList();
  }
}
