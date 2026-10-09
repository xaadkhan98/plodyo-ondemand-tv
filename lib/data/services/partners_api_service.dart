import '../../core/constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/partner_model.dart';
import 'api_client.dart';

/// Service communicating with OnDemand Plodyo Admin Partners endpoints.
class PartnersApiService {
  PartnersApiService({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /ondemand/admin/partners
  Future<PaginatedResponse<PartnerModel>> getPartners({
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
      ApiConstants.adminPartnersEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );

    return PaginatedResponse<PartnerModel>.fromJson(
      res as Map<String, dynamic>,
      PartnerModel.fromJson,
    );
  }

  /// GET /ondemand/admin/partners/:id
  Future<PartnerModel> getPartner({
    required String accessToken,
    required String partnerId,
    String? clientSecret,
  }) async {
    final res = await _client.get(
      '${ApiConstants.adminPartnersEndpoint}/$partnerId',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PartnerModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/partners/:id/approve
  Future<PartnerModel> approvePartner({
    required String accessToken,
    required String partnerId,
    int? roomLimit,
    String? clientSecret,
  }) async {
    final body = roomLimit != null ? {'room_limit': roomLimit} : null;

    final res = await _client.post(
      '${ApiConstants.adminPartnersEndpoint}/$partnerId/approve',
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PartnerModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/partners/:id/reject
  Future<PartnerModel> rejectPartner({
    required String accessToken,
    required String partnerId,
    String? rejectionReason,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      if (rejectionReason != null && rejectionReason.isNotEmpty)
        'rejection_reason': rejectionReason,
    };

    final res = await _client.post(
      '${ApiConstants.adminPartnersEndpoint}/$partnerId/reject',
      body: body.isNotEmpty ? body : null,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PartnerModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/partners/:id/room-limit
  Future<PartnerModel> updateRoomLimit({
    required String accessToken,
    required String partnerId,
    required int roomLimit,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminPartnersEndpoint}/$partnerId/room-limit',
      body: {'room_limit': roomLimit},
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PartnerModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/partners — manual onboarding (super admin). Optional fields are omitted, not sent empty.
  Future<PartnerModel> createPartner({
    required String accessToken,
    required String name,
    required String partnerType,
    required String contactEmail,
    String? contactName,
    String? phone,
    String? contractReference,
    required int roomLimit,
    String? contentTier,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'partner_type': partnerType,
      'contact_email': contactEmail,
      if (contactName != null && contactName.isNotEmpty)
        'contact_name': contactName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (contractReference != null && contractReference.isNotEmpty)
        'contract_reference': contractReference,
      'room_limit': roomLimit,
      'content_tier': ?contentTier,
    };

    final res = await _client.post(
      ApiConstants.adminPartnersEndpoint,
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PartnerModel.fromJson(res as Map<String, dynamic>);
  }

  /// PATCH /ondemand/admin/partners/:id — edits contact details. Null means unchanged; an empty string clears.
  /// [contractReference] and [contentTier] must stay null for a partner admin: their presence alone is a 403.
  Future<PartnerModel> updatePartner({
    required String accessToken,
    required String partnerId,
    String? name,
    String? contactName,
    String? contactEmail,
    String? phone,
    String? contractReference,
    String? contentTier,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'contact_name': ?contactName,
      'contact_email': ?contactEmail,
      'phone': ?phone,
      'contract_reference': ?contractReference,
      'content_tier': ?contentTier,
    };

    final res = await _client.patch(
      '${ApiConstants.adminPartnersEndpoint}/$partnerId',
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PartnerModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/partners/:id/suspend
  Future<PartnerModel> suspendPartner({
    required String accessToken,
    required String partnerId,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminPartnersEndpoint}/$partnerId/suspend',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PartnerModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/partners/:id/activate
  Future<PartnerModel> activatePartner({
    required String accessToken,
    required String partnerId,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminPartnersEndpoint}/$partnerId/activate',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PartnerModel.fromJson(res as Map<String, dynamic>);
  }
}
