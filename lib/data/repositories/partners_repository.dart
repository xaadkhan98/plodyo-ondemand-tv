import '../models/auth_exception.dart';
import '../models/paginated_response.dart';
import '../models/partner_model.dart';
import '../services/partners_api_service.dart';

/// Global shared instance of [PartnersRepository].
final PartnersRepository sharedPartnersRepository = PartnersRepositoryImpl();

/// Abstract repository for managing partners.
abstract class PartnersRepository {
  Future<PaginatedResponse<PartnerModel>> getPartners({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
  });

  Future<PartnerModel> getPartner({
    required String accessToken,
    required String partnerId,
  });

  Future<PartnerModel> approvePartner({
    required String accessToken,
    required String partnerId,
    int? roomLimit,
  });

  Future<PartnerModel> rejectPartner({
    required String accessToken,
    required String partnerId,
    String? rejectionReason,
  });

  Future<PartnerModel> updateRoomLimit({
    required String accessToken,
    required String partnerId,
    required int roomLimit,
  });
}

/// Concrete implementation of [PartnersRepository] with live API and graceful offline fallback.
class PartnersRepositoryImpl implements PartnersRepository {
  PartnersRepositoryImpl({
    PartnersApiService? apiService,
  }) : _apiService = apiService ?? PartnersApiService();

  final PartnersApiService _apiService;

  final List<PartnerModel> _localPartners = [
    const PartnerModel(
      id: 'p-1',
      name: 'Indie Test Hotel',
      partnerType: 'INDEPENDENT',
      status: 'PENDING_APPROVAL',
      contactEmail: 'indie-test@example.com',
      contactName: 'Alex Smith',
      phone: '+1-555-0101',
      roomLimit: 0,
      createdAt: '2026-08-18T10:00:00.000Z',
    ),
    const PartnerModel(
      id: 'p-2',
      name: 'rl4',
      partnerType: 'HOST',
      status: 'ACTIVE',
      contactEmail: 'rl4@example.com',
      roomLimit: 25,
      createdAt: '2026-08-19T10:00:00.000Z',
    ),
    const PartnerModel(
      id: 'p-3',
      name: 'rl3',
      partnerType: 'HOST',
      status: 'ACTIVE',
      contactEmail: 'rl3@example.com',
      roomLimit: 15,
      createdAt: '2026-08-20T10:00:00.000Z',
    ),
    const PartnerModel(
      id: 'p-4',
      name: 'rl2',
      partnerType: 'HOST',
      status: 'ACTIVE',
      contactEmail: 'rl2@example.com',
      roomLimit: 10,
      createdAt: '2026-08-21T10:00:00.000Z',
    ),
    const PartnerModel(
      id: 'p-5',
      name: 'rl1',
      partnerType: 'HOST',
      status: 'ACTIVE',
      contactEmail: 'rl1@example.com',
      roomLimit: 5,
      createdAt: '2026-08-22T10:00:00.000Z',
    ),
    const PartnerModel(
      id: 'p-6',
      name: 'Grand Hotel Downtown',
      partnerType: 'INDEPENDENT',
      status: 'ACTIVE',
      contactEmail: 'owner@grandhotel.com',
      contactName: 'Jordan Lee',
      phone: '+1-555-0100',
      roomLimit: 60,
      createdAt: '2026-08-23T10:00:00.000Z',
    ),
  ];

  @override
  Future<PaginatedResponse<PartnerModel>> getPartners({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        return await _apiService.getPartners(
          accessToken: accessToken,
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

    // Local fallback
    var filtered = _localPartners;
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((p) => p.status.toUpperCase() == status.toUpperCase()).toList();
    }
    return PaginatedResponse<PartnerModel>(
      data: List.unmodifiable(filtered),
      total: filtered.length,
      page: page ?? 1,
      pageSize: pageSize ?? 25,
    );
  }

  @override
  Future<PartnerModel> getPartner({
    required String accessToken,
    required String partnerId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        return await _apiService.getPartner(
          accessToken: accessToken,
          partnerId: partnerId,
        );
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    return _localPartners.firstWhere(
      (p) => p.id == partnerId,
      orElse: () => _localPartners.first,
    );
  }

  @override
  Future<PartnerModel> approvePartner({
    required String accessToken,
    required String partnerId,
    int? roomLimit,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.approvePartner(
          accessToken: accessToken,
          partnerId: partnerId,
          roomLimit: roomLimit,
        );
        _updateLocal(res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localPartners.indexWhere((p) => p.id == partnerId);
    if (index != -1) {
      final updated = _localPartners[index].copyWith(
        status: 'ACTIVE',
        roomLimit: roomLimit ?? _localPartners[index].roomLimit,
        reviewedAt: DateTime.now().toIso8601String(),
      );
      _localPartners[index] = updated;
      return updated;
    }
    throw Exception('Partner not found');
  }

  @override
  Future<PartnerModel> rejectPartner({
    required String accessToken,
    required String partnerId,
    String? rejectionReason,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.rejectPartner(
          accessToken: accessToken,
          partnerId: partnerId,
          rejectionReason: rejectionReason,
        );
        _updateLocal(res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localPartners.indexWhere((p) => p.id == partnerId);
    if (index != -1) {
      final updated = _localPartners[index].copyWith(
        status: 'REJECTED',
        rejectionReason: rejectionReason ?? 'Application not approved',
        reviewedAt: DateTime.now().toIso8601String(),
      );
      _localPartners[index] = updated;
      return updated;
    }
    throw Exception('Partner not found');
  }

  @override
  Future<PartnerModel> updateRoomLimit({
    required String accessToken,
    required String partnerId,
    required int roomLimit,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.updateRoomLimit(
          accessToken: accessToken,
          partnerId: partnerId,
          roomLimit: roomLimit,
        );
        _updateLocal(res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localPartners.indexWhere((p) => p.id == partnerId);
    if (index != -1) {
      final updated = _localPartners[index].copyWith(roomLimit: roomLimit);
      _localPartners[index] = updated;
      return updated;
    }
    throw Exception('Partner not found');
  }

  void _updateLocal(PartnerModel updated) {
    final index = _localPartners.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _localPartners[index] = updated;
    } else {
      _localPartners.add(updated);
    }
  }
}
