import '../../core/constants/api_constants.dart';
import '../models/invite_model.dart';
import '../models/paginated_response.dart';
import 'api_client.dart';

/// Service communicating with OnDemand Plodyo Admin Invites endpoints.
class InvitesApiService {
  InvitesApiService({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /ondemand/admin/invites
  Future<PaginatedResponse<InviteModel>> getInvites({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
    String? clientSecret,
  }) async {
    final queryParams = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (page != null) 'page': page.toString(),
      if (pageSize != null) 'page_size': pageSize.toString(),
    };

    final res = await _client.get(
      ApiConstants.adminInvitesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );

    return PaginatedResponse<InviteModel>.fromJson(
      res as Map<String, dynamic>,
      InviteModel.fromJson,
    );
  }

  /// POST /ondemand/admin/invites
  Future<InviteModel> createInvite({
    required String accessToken,
    required String email,
    required String role, // "PARTNER_ADMIN" | "PROPERTY_ADMIN"
    required String partnerId,
    String? propertyId,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'role': role,
      'partner_id': partnerId,
      if (propertyId != null && propertyId.isNotEmpty)
        'property_id': propertyId,
    };

    final res = await _client.post(
      ApiConstants.adminInvitesEndpoint,
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return InviteModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/invites/:id/resend
  Future<InviteModel> resendInvite({
    required String accessToken,
    required String inviteId,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminInvitesEndpoint}/$inviteId/resend',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return InviteModel.fromJson(res as Map<String, dynamic>);
  }

  /// DELETE /ondemand/admin/invites/:id
  Future<String> revokeInvite({
    required String accessToken,
    required String inviteId,
    String? clientSecret,
  }) async {
    final res = await _client.delete(
      '${ApiConstants.adminInvitesEndpoint}/$inviteId',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    final map = res as Map<String, dynamic>?;
    return map?['message'] as String? ?? 'Invite revoked.';
  }
}
