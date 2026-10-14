import '../../core/constants/api_constants.dart';
import '../models/device_models.dart';
import '../models/paginated_response.dart';
import '../models/story_models.dart';
import 'api_client.dart';

/// Who reads the catalogue, which decides the routes: a paired TV with its token under /device, or the
/// console with its bearer under /admin. The rows are the same, capped by the API to the reader's tier.
class CatalogueReader {
  const CatalogueReader.device(String token)
    : deviceToken = token,
      accessToken = null;

  const CatalogueReader.console(String token)
    : deviceToken = null,
      accessToken = token;

  final String? deviceToken;
  final String? accessToken;

  String get _content => deviceToken != null
      ? ApiConstants.deviceContentEndpoint
      : ApiConstants.adminContentEndpoint;

  String get _series => deviceToken != null
      ? ApiConstants.deviceSeriesEndpoint
      : ApiConstants.adminSeriesEndpoint;
}

/// The room TV's endpoints: X-Device-Token, never a bearer, and no refresh step. The catalogue reads also
/// serve the console, through a [CatalogueReader].
class DeviceApiService {
  DeviceApiService({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// POST /ondemand/device/pair: the only device route with no credential. The token comes back once.
  Future<String> pair(String pairingCode) async {
    final res = await _client.post(
      ApiConstants.devicePairEndpoint,
      body: {'pairing_code': pairingCode},
    );
    return (res as Map<String, dynamic>)['device_token'] as String;
  }

  /// GET /ondemand/device/session: opens a room_sessions row. Called once on startup.
  Future<DeviceSession> openSession(String deviceToken) async {
    final res = await _client.get(
      ApiConstants.deviceSessionEndpoint,
      deviceToken: deviceToken,
    );
    return DeviceSession.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/device/heartbeat: keeps the room online and answers with the session to hold.
  Future<DeviceSession> heartbeat(
    String deviceToken, {
    required String sessionId,
    required bool active,
    required List<Map<String, Object?>> events,
  }) async {
    final res = await _client.post(
      ApiConstants.deviceHeartbeatEndpoint,
      deviceToken: deviceToken,
      body: {
        'session_id': sessionId,
        'active': active,
        // The API corrects event times by this, so a TV with a wrong clock is fine.
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        // Omitted when empty, so an idle beat stays tiny.
        if (events.isNotEmpty) 'events': events,
      },
    );
    return DeviceSession.fromJson(res as Map<String, dynamic>);
  }

  /// GET /ondemand/device/config
  Future<DeviceConfig> getConfig(String deviceToken) async {
    final res = await _client.get(
      ApiConstants.deviceConfigEndpoint,
      deviceToken: deviceToken,
    );
    return DeviceConfig.fromJson(res as Map<String, dynamic>);
  }

  /// GET /content. An unset language is omitted, not sent empty: absent means the room's default, "" is a 400.
  Future<PaginatedResponse<Story>> getStories(
    CatalogueReader reader, {
    String? language,
    AgeGroup? ageGroup,
    StoryType? storyType,
    int? page,
    int? pageSize,
  }) async {
    final res = await _client.get(
      reader._content,
      deviceToken: reader.deviceToken,
      accessToken: reader.accessToken,
      queryParameters: {
        'language': ?language,
        'age_group': ?ageGroup?.code,
        'story_type': ?storyType?.code,
        'page': ?page?.toString(),
        'page_size': ?pageSize?.toString(),
      },
    );
    return PaginatedResponse.fromJson(
      res as Map<String, dynamic>,
      Story.fromJson,
    );
  }

  /// GET /content/:id: the one call that carries the media URL and the pages.
  Future<StoryDetail> getStory(CatalogueReader reader, String storyId) async {
    final res = await _client.get(
      '${reader._content}/${Uri.encodeComponent(storyId)}',
      deviceToken: reader.deviceToken,
      accessToken: reader.accessToken,
    );
    return StoryDetail.fromJson(res as Map<String, dynamic>);
  }

  /// GET /series. Same language rule as the catalogue.
  Future<PaginatedResponse<Series>> getSeries(
    CatalogueReader reader, {
    SeriesType? seriesType,
    String? category,
    AgeGroup? ageGroup,
    String? language,
    int? page,
    int? pageSize,
  }) async {
    final res = await _client.get(
      reader._series,
      deviceToken: reader.deviceToken,
      accessToken: reader.accessToken,
      queryParameters: {
        'series_type': ?seriesType?.code,
        'category': ?category,
        'age_group': ?ageGroup?.code,
        'language': ?language,
        'page': ?page?.toString(),
        'page_size': ?pageSize?.toString(),
      },
    );
    return PaginatedResponse.fromJson(
      res as Map<String, dynamic>,
      Series.fromJson,
    );
  }

  /// GET /series/:id. A 404 covers unknown, unpublished and unservable alike.
  Future<SeriesDetail> getSeriesDetail(
    CatalogueReader reader,
    String seriesId,
  ) async {
    final res = await _client.get(
      '${reader._series}/${Uri.encodeComponent(seriesId)}',
      deviceToken: reader.deviceToken,
      accessToken: reader.accessToken,
    );
    return SeriesDetail.fromJson(res as Map<String, dynamic>);
  }
}
