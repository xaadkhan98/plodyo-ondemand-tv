import '../../core/constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/partner_model.dart';
import 'api_client.dart';

/// Service communicating with OnDemand Plodyo Admin Partners endpoints.
class PartnersApiService {
  PartnersApiService({
    ApiClient? apiClient,
  }) : _client = apiClient ?? ApiClient();

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
}
