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

/// Concrete implementation of [InvitesRepository] calling live backend API.
class InvitesRepositoryImpl implements InvitesRepository {
  InvitesRepositoryImpl({
    InvitesApiService? apiService,
  }) : _apiService = apiService ?? InvitesApiService();

  final InvitesApiService _apiService;

  @override
  Future<PaginatedResponse<InviteModel>> getInvites({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
  }) {
    return _apiService.getInvites(
      accessToken: accessToken,
      status: status,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<InviteModel> createInvite({
    required String accessToken,
    required String email,
    required String role,
    required String partnerId,
    String? propertyId,
  }) {
    return _apiService.createInvite(
      accessToken: accessToken,
      email: email,
      role: role,
      partnerId: partnerId,
      propertyId: propertyId,
    );
  }

  @override
  Future<InviteModel> resendInvite({
    required String accessToken,
    required String inviteId,
  }) {
    return _apiService.resendInvite(
      accessToken: accessToken,
      inviteId: inviteId,
    );
  }

  @override
  Future<String> revokeInvite({
    required String accessToken,
    required String inviteId,
  }) {
    return _apiService.revokeInvite(
      accessToken: accessToken,
      inviteId: inviteId,
    );
  }
}

