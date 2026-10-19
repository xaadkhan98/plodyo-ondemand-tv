import '../../core/constants/api_constants.dart';
import '../models/device_models.dart';
import '../models/paginated_response.dart';
import '../models/story_models.dart';
import 'api_client.dart';

// The API's page sizes: its default, and the most one request may ask for.
const _apiPageSize = 25;
const _apiMaxPageSize = 100;

/// The guest's age pick never leaves the TV: every page is pulled without it, then matched and paged here.
// ponytail: a full pull per page asked for; cache the rows if a room's catalogue outgrows a few hundred.
Future<PaginatedResponse<T>> _matchedHere<T>(
  Future<PaginatedResponse<T>> Function(int page) fetch,
  bool Function(T row) keep, {
  int? page,
  int? pageSize,
}) async {
  final rows = <T>[];
  for (var at = 1; ; at++) {
    final next = await fetch(at);
    rows.addAll(next.data);
    if (next.data.isEmpty || rows.length >= next.total) break;
  }
  final matched = rows.where(keep).toList();
  final number = page ?? 1;
  final size = pageSize ?? _apiPageSize;
  return PaginatedResponse(
    data: matched.skip((number - 1) * size).take(size).toList(),
    total: matched.length,
    page: number,
    pageSize: size,
  );
}

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

  /// POST /ondemand/device/heartbeat: device status only, the app version and any Terms notices.
  Future<void> heartbeat(
    String deviceToken, {
    required String appVersion,
    required List<Map<String, Object?>> notices,
  }) => _client.post(
    ApiConstants.deviceHeartbeatEndpoint,
    deviceToken: deviceToken,
    body: {
      'app_version': appVersion,
      // The API corrects notice times by this, so a TV with a wrong clock is fine.
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      // Omitted when empty, so an idle beat stays tiny.
      if (notices.isNotEmpty) 'notices': notices,
    },
  );

  /// POST /ondemand/device/viewing: slices of plays, added to the property's totals and kept nowhere else.
  Future<void> reportViewing(
    String deviceToken,
    List<Map<String, Object?>> slices,
  ) => _client.post(
    ApiConstants.deviceViewingEndpoint,
    deviceToken: deviceToken,
    body: {
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      // The local id only matches acknowledgements; the API never needs to tell two slices apart.
      'events': [
        for (final slice in slices) {...slice}..remove('id'),
      ],
    },
  );

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
    if (ageGroup != null) {
      return _matchedHere(
        (at) => getStories(
          reader,
          language: language,
          storyType: storyType,
          page: at,
          pageSize: _apiMaxPageSize,
        ),
        (story) => story.ageGroup == ageGroup.code,
        page: page,
        pageSize: pageSize,
      );
    }
    final res = await _client.get(
      reader._content,
      deviceToken: reader.deviceToken,
      accessToken: reader.accessToken,
      queryParameters: {
        'language': ?language,
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
    if (ageGroup != null) {
      return _matchedHere(
        (at) => getSeries(
          reader,
          seriesType: seriesType,
          category: category,
          language: language,
          page: at,
          pageSize: _apiMaxPageSize,
        ),
        (series) => series.ageGroup == ageGroup.code,
        page: page,
        pageSize: pageSize,
      );
    }
    final res = await _client.get(
      reader._series,
      deviceToken: reader.deviceToken,
      accessToken: reader.accessToken,
      queryParameters: {
        'series_type': ?seriesType?.code,
        'category': ?category,
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
