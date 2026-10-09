import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_exception.dart';
import '../models/device_models.dart';
import '../models/paginated_response.dart';
import '../models/story_models.dart';
import '../services/device_api_service.dart';

final DeviceRepository sharedDeviceRepository = DeviceRepositoryImpl();

/// This TV's credential and everything read with it. The token never expires or rotates: it is valid until
/// the room is revoked or re-provisioned, so there is no refresh step.
abstract class DeviceRepository {
  /// Reads the token a previous run stored. Called once, before the first frame.
  Future<void> restore();

  bool get isPaired;

  /// Trades a pairing code for this TV's token and keeps it, so the TV survives a power cut.
  Future<void> pair(String pairingCode);

  /// Forgets the token, sending the TV back to pairing.
  Future<void> unpair();

  Future<DeviceSession> openSession();

  Future<DeviceSession> heartbeat({
    required String sessionId,
    required bool active,
    required List<Map<String, Object?>> events,
  });

  Future<DeviceConfig> getConfig();

  Future<PaginatedResponse<Story>> getStories({
    String? language,
    AgeGroup? ageGroup,
    StoryType? storyType,
    int? page,
    int? pageSize,
  });

  Future<StoryDetail> getStory(String storyId);

  Future<PaginatedResponse<Series>> getSeries({
    SeriesType? seriesType,
    String? category,
    AgeGroup? ageGroup,
    String? language,
    int? page,
    int? pageSize,
  });

  Future<SeriesDetail> getSeriesDetail(String seriesId);
}

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({DeviceApiService? apiService})
    : _api = apiService ?? DeviceApiService();

  static const _tokenKey = 'plodyo.ondemand.device-token';

  final DeviceApiService _api;
  String? _token;

  String get _deviceToken =>
      _token ?? (throw StateError('This TV is not paired.'));

  @override
  bool get isPaired => _token != null;

  @override
  Future<void> restore() async {
    try {
      _token = (await SharedPreferences.getInstance()).getString(_tokenKey);
    } on Exception {
      // Unreadable storage reads as unpaired; pairing again is the remedy either way.
      _token = null;
    }
  }

  Future<void> _persist(String? token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, token);
      }
    } on Exception {
      // The session continues in memory; it just will not survive a restart.
    }
  }

  @override
  Future<void> pair(String pairingCode) async {
    final code = normalisePairingCode(pairingCode);
    // Checked here so a half-typed code costs no round trip: /pair is rate limited per property.
    if (code.replaceAll('-', '').length < pairingCodeLength) {
      throw const AuthException(
        message: 'Enter the full 8-character pairing code.',
        statusCode: 400,
      );
    }
    await _persist(await _api.pair(code));
  }

  @override
  Future<void> unpair() => _persist(null);

  @override
  Future<DeviceSession> openSession() => _api.openSession(_deviceToken);

  @override
  Future<DeviceSession> heartbeat({
    required String sessionId,
    required bool active,
    required List<Map<String, Object?>> events,
  }) => _api.heartbeat(
    _deviceToken,
    sessionId: sessionId,
    active: active,
    events: events,
  );

  @override
  Future<DeviceConfig> getConfig() => _api.getConfig(_deviceToken);

  @override
  Future<PaginatedResponse<Story>> getStories({
    String? language,
    AgeGroup? ageGroup,
    StoryType? storyType,
    int? page,
    int? pageSize,
  }) => _api.getStories(
    _deviceToken,
    language: language,
    ageGroup: ageGroup,
    storyType: storyType,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<StoryDetail> getStory(String storyId) =>
      _api.getStory(_deviceToken, storyId);

  @override
  Future<PaginatedResponse<Series>> getSeries({
    SeriesType? seriesType,
    String? category,
    AgeGroup? ageGroup,
    String? language,
    int? page,
    int? pageSize,
  }) => _api.getSeries(
    _deviceToken,
    seriesType: seriesType,
    category: category,
    ageGroup: ageGroup,
    language: language,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<SeriesDetail> getSeriesDetail(String seriesId) =>
      _api.getSeriesDetail(_deviceToken, seriesId);
}
