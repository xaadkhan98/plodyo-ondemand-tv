import '../models/device_models.dart';
import '../models/paginated_response.dart';
import '../services/device_api_service.dart';

/// Global shared instance of [DeviceRepository] for TV device state and catalog.
final DeviceRepository sharedDeviceRepository = DeviceRepositoryImpl();

/// Repository for Room TV device operations (pairing, session, config, and live catalogue).
abstract class DeviceRepository {
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
  }

}
