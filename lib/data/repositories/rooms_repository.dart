import '../models/auth_exception.dart';
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

/// Concrete implementation of [RoomsRepository] with live API and graceful offline fallback.
class RoomsRepositoryImpl implements RoomsRepository {
  RoomsRepositoryImpl({
    RoomsApiService? apiService,
  }) : _apiService = apiService ?? RoomsApiService();

  final RoomsApiService _apiService;

  final List<RoomModel> _localRooms = [
    const RoomModel(
      id: '88888888-8888-4888-8888-888888888881',
      propertyId: '5d8e2a11-7c44-4b6a-9d31-2e3f4a5b6c7d',
      roomLabel: 'Room 101 - King Suite',
      status: 'ACTIVE',
      defaultLanguage: 'en',
      provisionedAt: '2026-08-18T12:00:00.000Z',
      lastSeenAt: '2026-08-25T08:30:00.000Z',
      createdAt: '2026-08-18T10:00:00.000Z',
    ),
    const RoomModel(
      id: '88888888-8888-4888-8888-888888888882',
      propertyId: '5d8e2a11-7c44-4b6a-9d31-2e3f4a5b6c7d',
      roomLabel: 'Room 214 - Riverside Deluxe',
      status: 'UNPROVISIONED',
      defaultLanguage: 'es',
      createdAt: '2026-08-18T10:00:00.000Z',
    ),
    const RoomModel(
      id: '88888888-8888-4888-8888-888888888883',
      propertyId: '5d8e2a11-7c44-4b6a-9d31-2e3f4a5b6c7e',
      roomLabel: 'Room 305 - Executive Penthouse',
      status: 'ACTIVE',
      defaultLanguage: 'en',
      provisionedAt: '2026-08-19T14:20:00.000Z',
      lastSeenAt: '2026-08-25T09:15:00.000Z',
      createdAt: '2026-08-19T11:00:00.000Z',
    ),
  ];

  @override
  Future<PaginatedResponse<RoomModel>> getRooms({
    required String accessToken,
    String? propertyId,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        return await _apiService.getRooms(
          accessToken: accessToken,
          propertyId: propertyId,
          status: status,
          page: page,
          pageSize: pageSize,
        );
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    var filtered = _localRooms;
    if (propertyId != null && propertyId.isNotEmpty) {
      filtered = filtered.where((r) => r.propertyId == propertyId).toList();
    }
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((r) => r.status.toUpperCase() == status.toUpperCase()).toList();
    }
    return PaginatedResponse<RoomModel>(
      data: List.unmodifiable(filtered),
      total: filtered.length,
      page: page ?? 1,
      pageSize: pageSize ?? 25,
    );
  }

  @override
  Future<RoomModel> getRoom({
    required String accessToken,
    required String roomId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        return await _apiService.getRoom(
          accessToken: accessToken,
          roomId: roomId,
        );
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    return _localRooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => _localRooms.first,
    );
  }

  @override
  Future<RoomModel> createRoom({
    required String accessToken,
    required String propertyId,
    required String roomLabel,
    String? defaultLanguage,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.createRoom(
          accessToken: accessToken,
          propertyId: propertyId,
          roomLabel: roomLabel,
          defaultLanguage: defaultLanguage,
        );
        _localRooms.insert(0, res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final newRoom = RoomModel(
      id: 'room-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      roomLabel: roomLabel,
      status: 'UNPROVISIONED',
      defaultLanguage: defaultLanguage,
      createdAt: DateTime.now().toIso8601String(),
    );
    _localRooms.insert(0, newRoom);
    return newRoom;
  }

  @override
  Future<RoomModel> updateRoom({
    required String accessToken,
    required String roomId,
    String? roomLabel,
    String? defaultLanguage,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.updateRoom(
          accessToken: accessToken,
          roomId: roomId,
          roomLabel: roomLabel,
          defaultLanguage: defaultLanguage,
        );
        _updateLocal(res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localRooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final updated = _localRooms[index].copyWith(
        roomLabel: roomLabel,
        defaultLanguage: defaultLanguage,
        updatedAt: DateTime.now().toIso8601String(),
      );
      _localRooms[index] = updated;
      return updated;
    }
    throw Exception('Room not found');
  }

  @override
  Future<String> deleteRoom({
    required String accessToken,
    required String roomId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.deleteRoom(
          accessToken: accessToken,
          roomId: roomId,
        );
        _localRooms.removeWhere((r) => r.id == roomId);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localRooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = _localRooms[index];
      if (room.status != 'UNPROVISIONED') {
        throw AuthException(
          message: 'Only an unprovisioned room can be deleted.',
          statusCode: 400,
        );
      }
      _localRooms.removeAt(index);
      return 'Room deleted.';
    }
    throw Exception('Room not found');
  }

  void _updateLocal(RoomModel updated) {
    final index = _localRooms.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _localRooms[index] = updated;
    } else {
      _localRooms.add(updated);
    }
  }
}
