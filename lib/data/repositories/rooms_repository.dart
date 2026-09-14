import '../models/paginated_response.dart';
import '../models/room_model.dart';
import '../services/rooms_api_service.dart';

/// Global shared instance of [RoomsRepository].
final RoomsRepository sharedRoomsRepository = RoomsRepositoryImpl();

/// Abstract repository for managing rooms.
abstract class RoomsRepository {
  Future<PaginatedResponse<RoomModel>> getRooms({
    required String accessToken,
    String? propertyId,
    String? status,
    int? page,
    int? pageSize,
  });

  Future<RoomModel> getRoom({
    required String accessToken,
    required String roomId,
  });

  Future<RoomModel> createRoom({
    required String accessToken,
    required String propertyId,
    required String roomLabel,
    String? defaultLanguage,
  });

  Future<BulkCreateRoomsResponse> createRoomsBulk({
    required String accessToken,
    required String propertyId,
    required List<Map<String, dynamic>> rooms,
    String? defaultLanguage,
  });

  Future<ProvisionRoomResponse> provisionRoom({
    required String accessToken,
    required String roomId,
  });

  Future<String> revokeRoom({
    required String accessToken,
    required String roomId,
  });

  Future<RoomModel> updateRoom({
    required String accessToken,
    required String roomId,
    String? roomLabel,
    String? defaultLanguage,
  });

  Future<String> deleteRoom({
    required String accessToken,
    required String roomId,
  });
}

/// Concrete implementation of [RoomsRepository] calling live backend API.
class RoomsRepositoryImpl implements RoomsRepository {
  RoomsRepositoryImpl({
    RoomsApiService? apiService,
  }) : _apiService = apiService ?? RoomsApiService();

  final RoomsApiService _apiService;

  @override
  Future<PaginatedResponse<RoomModel>> getRooms({
    required String accessToken,
    String? propertyId,
    String? status,
    int? page,
    int? pageSize,
  }) {
    return _apiService.getRooms(
      accessToken: accessToken,
      propertyId: propertyId,
      status: status,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<RoomModel> getRoom({
    required String accessToken,
    required String roomId,
  }) {
    return _apiService.getRoom(
      accessToken: accessToken,
      roomId: roomId,
    );
  }

  @override
  Future<RoomModel> createRoom({
    required String accessToken,
    required String propertyId,
    required String roomLabel,
    String? defaultLanguage,
  }) {
    return _apiService.createRoom(
      accessToken: accessToken,
      propertyId: propertyId,
      roomLabel: roomLabel,
      defaultLanguage: defaultLanguage,
    );
  }

  @override
  Future<BulkCreateRoomsResponse> createRoomsBulk({
    required String accessToken,
    required String propertyId,
    required List<Map<String, dynamic>> rooms,
    String? defaultLanguage,
  }) {
    return _apiService.createRoomsBulk(
      accessToken: accessToken,
      propertyId: propertyId,
      rooms: rooms,
      defaultLanguage: defaultLanguage,
    );
  }

  @override
  Future<ProvisionRoomResponse> provisionRoom({
    required String accessToken,
    required String roomId,
  }) {
    return _apiService.provisionRoom(
      accessToken: accessToken,
      roomId: roomId,
    );
  }

  @override
  Future<String> revokeRoom({
    required String accessToken,
    required String roomId,
  }) {
    return _apiService.revokeRoom(
      accessToken: accessToken,
      roomId: roomId,
    );
  }

  @override
  Future<RoomModel> updateRoom({
    required String accessToken,
    required String roomId,
    String? roomLabel,
    String? defaultLanguage,
  }) {
    return _apiService.updateRoom(
      accessToken: accessToken,
      roomId: roomId,
      roomLabel: roomLabel,
      defaultLanguage: defaultLanguage,
    );
  }

  @override
  Future<String> deleteRoom({
    required String accessToken,
    required String roomId,
  }) {
    return _apiService.deleteRoom(
      accessToken: accessToken,
      roomId: roomId,
    );
  }
}

