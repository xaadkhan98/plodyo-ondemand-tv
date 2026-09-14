import '../../core/constants/api_constants.dart';
import '../models/device_models.dart';
import '../models/paginated_response.dart';
import 'api_client.dart';

/// Service communicating with OnDemand Plodyo Device (Room TV) endpoints.
class DeviceApiService {
  DeviceApiService({
    ApiClient? apiClient,
  }) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// POST /ondemand/device/pair
  /// Authenticates a new device using the 8-character pairing code and returns its persistent device token.
  Future<DevicePairResponse> pair({
    required String pairingCode,
  }) async {
    final res = await _client.post(
      ApiConstants.devicePairEndpoint,
      body: {'pairing_code': pairingCode.trim()},
    );
    return DevicePairResponse.fromJson(res as Map<String, dynamic>);
  }

  /// GET /ondemand/device/session
  /// Opens a room_sessions row for this device and returns its session id and room id.
  Future<DeviceSession> getSession({
    required String deviceToken,
  }) async {
    final res = await _client.get(
      ApiConstants.deviceSessionEndpoint,
      deviceToken: deviceToken,
    );
    return DeviceSession.fromJson(res as Map<String, dynamic>);
  }

  /// GET /ondemand/device/config
  /// Retrieves available languages, age-groups, and default language for the room.
  Future<DeviceConfig> getConfig({
    required String deviceToken,
  }) async {
    final res = await _client.get(
      ApiConstants.deviceConfigEndpoint,
      deviceToken: deviceToken,
    );
    return DeviceConfig.fromJson(res as Map<String, dynamic>);
  }

  /// GET /ondemand/device/content
  /// Fetches paginated story catalog, filtered optionally by language and age-group.
  Future<PaginatedResponse<DeviceStoryItem>> getContent({
    required String deviceToken,
    String? language,
    String? ageGroup,
    int? page,
    int? pageSize,
  }) async {
    final queryParams = <String, String>{
      if (language != null && language.isNotEmpty) 'language': language,
      if (ageGroup != null && ageGroup.isNotEmpty) 'age_group': ageGroup,
      if (page != null) 'page': page.toString(),
      if (pageSize != null) 'page_size': pageSize.toString(),
    };

    final res = await _client.get(
      ApiConstants.deviceContentEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      deviceToken: deviceToken,
    );

    return PaginatedResponse<DeviceStoryItem>.fromJson(
      res as Map<String, dynamic>,
      DeviceStoryItem.fromJson,
    );
  }

  /// GET /ondemand/device/content/:storyId
  /// Fetches the story detail with media_url for playback.
  Future<DeviceStoryItem> getStoryDetail({
    required String deviceToken,
    required String storyId,
  }) async {
    final res = await _client.get(
      '${ApiConstants.deviceContentEndpoint}/$storyId',
      deviceToken: deviceToken,
    );
    return DeviceStoryItem.fromJson(res as Map<String, dynamic>);
  }
}
