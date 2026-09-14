import '../../core/constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/room_model.dart';
import 'api_client.dart';

/// Service communicating with OnDemand Plodyo Admin Rooms endpoints.
class RoomsApiService {
  RoomsApiService({
    ApiClient? apiClient,
  }) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /ondemand/admin/rooms
  Future<PaginatedResponse<RoomModel>> getRooms({
    required String accessToken,
    String? propertyId,
    String? status,
    int? page,
    int? pageSize,
    String? clientSecret,
  }) async {
    final queryParams = <String, String>{
      if (propertyId != null && propertyId.isNotEmpty) 'property_id': propertyId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (page != null) 'page': page.toString(),
      if (pageSize != null) 'page_size': pageSize.toString(),
    };

    final res = await _client.get(
      ApiConstants.adminRoomsEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );

    return PaginatedResponse<RoomModel>.fromJson(
      res as Map<String, dynamic>,
      RoomModel.fromJson,
    );
  }

  /// GET /ondemand/admin/rooms/:id
  Future<RoomModel> getRoom({
    required String accessToken,
    required String roomId,
    String? clientSecret,
  }) async {
    final res = await _client.get(
      '${ApiConstants.adminRoomsEndpoint}/$roomId',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return RoomModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/rooms
  Future<RoomModel> createRoom({
    required String accessToken,
    required String propertyId,
    required String roomLabel,
    String? defaultLanguage,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'property_id': propertyId,
      'room_label': roomLabel,
      if (defaultLanguage != null && defaultLanguage.isNotEmpty)
        'default_language': defaultLanguage,
    };

    final res = await _client.post(
      ApiConstants.adminRoomsEndpoint,
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return RoomModel.fromJson(res as Map<String, dynamic>);
  }

  /// PATCH /ondemand/admin/rooms/:id
  Future<RoomModel> updateRoom({
    required String accessToken,
    required String roomId,
    String? roomLabel,
    String? defaultLanguage,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      if (roomLabel != null && roomLabel.isNotEmpty) 'room_label': roomLabel,
      if (defaultLanguage != null && defaultLanguage.isNotEmpty)
        'default_language': defaultLanguage,
    };

    final res = await _client.patch(
      '${ApiConstants.adminRoomsEndpoint}/$roomId',
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return RoomModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/rooms/bulk
  Future<BulkCreateRoomsResponse> createRoomsBulk({
    required String accessToken,
    required String propertyId,
    required List<Map<String, dynamic>> rooms,
    String? defaultLanguage,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'property_id': propertyId,
      'rooms': rooms,
      if (defaultLanguage != null && defaultLanguage.isNotEmpty)
        'default_language': defaultLanguage,
    };

    final res = await _client.post(
      ApiConstants.adminRoomsBulkEndpoint,
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return BulkCreateRoomsResponse.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/rooms/:id/provision
  Future<ProvisionRoomResponse> provisionRoom({
    required String accessToken,
    required String roomId,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminRoomsEndpoint}/$roomId/provision',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return ProvisionRoomResponse.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/rooms/:id/revoke
  Future<String> revokeRoom({
    required String accessToken,
    required String roomId,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminRoomsEndpoint}/$roomId/revoke',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    final map = res as Map<String, dynamic>?;
    return map?['message'] as String? ?? 'Device revoked.';
  }

  /// DELETE /ondemand/admin/rooms/:id
  Future<String> deleteRoom({
    required String accessToken,
    required String roomId,
    String? clientSecret,
  }) async {
    final res = await _client.delete(
      '${ApiConstants.adminRoomsEndpoint}/$roomId',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    final map = res as Map<String, dynamic>?;
    return map?['message'] as String? ?? 'Room deleted.';
  }
}
