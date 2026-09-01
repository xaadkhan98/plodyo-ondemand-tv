import '../models/auth_exception.dart';
import '../models/invite_model.dart';
import '../models/paginated_response.dart';
import '../services/invites_api_service.dart';

/// Global shared instance of [InvitesRepository].
final InvitesRepository sharedInvitesRepository = InvitesRepositoryImpl();

/// Abstract repository for managing admin invites.
abstract class InvitesRepository {
  Future<PaginatedResponse<InviteModel>> getInvites({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
  });

  Future<InviteModel> createInvite({
    required String accessToken,
    required String email,
    required String role,
    required String partnerId,
    String? propertyId,
  });

  Future<InviteModel> resendInvite({
    required String accessToken,
    required String inviteId,
  });

  Future<String> revokeInvite({
    required String accessToken,
    required String inviteId,
  });
}

/// Concrete implementation of [InvitesRepository] with live API and offline state fallback.
class InvitesRepositoryImpl implements InvitesRepository {
  InvitesRepositoryImpl({
    InvitesApiService? apiService,
  }) : _apiService = apiService ?? InvitesApiService();

  final InvitesApiService _apiService;

  final List<InviteModel> _localInvites = [
    const InviteModel(
      id: 'inv-1',
      email: 'rl4@example.com',
      role: 'PARTNER_ADMIN',
      partnerId: '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
      status: 'PENDING',
      sentAt: '2026-08-20T10:00:00.000Z',
      expiresAt: '2026-09-05T10:00:00.000Z',
      createdAt: '2026-08-20T10:00:00.000Z',
    ),
    const InviteModel(
      id: 'inv-2',
      email: 'rl3@example.com',
      role: 'PARTNER_ADMIN',
      partnerId: '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
      status: 'PENDING',
      sentAt: '2026-08-21T10:00:00.000Z',
      expiresAt: '2026-09-05T10:00:00.000Z',
      createdAt: '2026-08-21T10:00:00.000Z',
    ),
    const InviteModel(
      id: 'inv-3',
      email: 'rl2@example.com',
      role: 'PARTNER_ADMIN',
      partnerId: '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
      status: 'PENDING',
      sentAt: '2026-08-22T10:00:00.000Z',
      expiresAt: '2026-09-05T10:00:00.000Z',
      createdAt: '2026-08-22T10:00:00.000Z',
    ),
    const InviteModel(
      id: 'inv-4',
      email: 'rl1@example.com',
      role: 'PARTNER_ADMIN',
      partnerId: '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
      status: 'PENDING',
      sentAt: '2026-08-23T10:00:00.000Z',
      expiresAt: '2026-09-05T10:00:00.000Z',
      createdAt: '2026-08-23T10:00:00.000Z',
    ),
    const InviteModel(
      id: 'inv-5',
      email: 'a@b.com',
      role: 'PARTNER_ADMIN',
      partnerId: '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
      status: 'PENDING',
      sentAt: '2026-08-24T10:00:00.000Z',
      expiresAt: '2026-09-05T10:00:00.000Z',
      createdAt: '2026-08-24T10:00:00.000Z',
    ),
  ];

  @override
  Future<PaginatedResponse<InviteModel>> getInvites({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        return await _apiService.getInvites(
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

    var filtered = _localInvites;
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((i) => i.status.toUpperCase() == status.toUpperCase()).toList();
    }
    return PaginatedResponse<InviteModel>(
      data: List.unmodifiable(filtered),
      total: filtered.length,
      page: page ?? 1,
      pageSize: pageSize ?? 25,
    );
  }

  @override
  Future<InviteModel> createInvite({
    required String accessToken,
    required String email,
    required String role,
    required String partnerId,
    String? propertyId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.createInvite(
          accessToken: accessToken,
          email: email,
          role: role,
          partnerId: partnerId,
          propertyId: propertyId,
        );
        _localInvites.insert(0, res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final newInvite = InviteModel(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      role: role,
      partnerId: partnerId,
      propertyId: propertyId,
      status: 'PENDING',
      sentAt: DateTime.now().toIso8601String(),
      expiresAt: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );
    _localInvites.insert(0, newInvite);
    return newInvite;
  }

  @override
  Future<InviteModel> resendInvite({
    required String accessToken,
    required String inviteId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.resendInvite(
          accessToken: accessToken,
          inviteId: inviteId,
        );
        _updateLocal(res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localInvites.indexWhere((i) => i.id == inviteId);
    if (index != -1) {
      final updated = _localInvites[index].copyWith(
        sentAt: DateTime.now().toIso8601String(),
        expiresAt: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      );
      _localInvites[index] = updated;
      return updated;
    }
    throw Exception('Invite not found');
  }

  @override
  Future<String> revokeInvite({
    required String accessToken,
    required String inviteId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final msg = await _apiService.revokeInvite(
          accessToken: accessToken,
          inviteId: inviteId,
        );
        final index = _localInvites.indexWhere((i) => i.id == inviteId);
        if (index != -1) {
          _localInvites[index] = _localInvites[index].copyWith(status: 'REVOKED');
        }
        return msg;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localInvites.indexWhere((i) => i.id == inviteId);
    if (index != -1) {
      _localInvites[index] = _localInvites[index].copyWith(status: 'REVOKED');
      return 'Invite revoked.';
    }
    throw Exception('Invite not found');
  }

  void _updateLocal(InviteModel updated) {
    final index = _localInvites.indexWhere((i) => i.id == updated.id);
    if (index != -1) {
      _localInvites[index] = updated;
    } else {
      _localInvites.add(updated);
    }
  }
}
