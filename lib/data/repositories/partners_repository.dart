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

  Future<PartnerModel> suspendPartner({
    required String accessToken,
    required String partnerId,
  });

  Future<PartnerModel> createPartner({
    required String accessToken,
    required String name,
    required String partnerType,
    required String contactEmail,
    String? contactName,
    String? phone,
    String? contractReference,
    required int roomLimit,
  });
}

/// Concrete implementation of [PartnersRepository] calling live backend API.
class PartnersRepositoryImpl implements PartnersRepository {
  PartnersRepositoryImpl({PartnersApiService? apiService})
    : _apiService = apiService ?? PartnersApiService();

  final PartnersApiService _apiService;

  @override
  Future<PaginatedResponse<PartnerModel>> getPartners({
    required String accessToken,
    String? status,
    int? page,
    int? pageSize,
  }) {
    return _apiService.getPartners(
      accessToken: accessToken,
      status: status,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<PartnerModel> getPartner({
    required String accessToken,
    required String partnerId,
  }) {
    return _apiService.getPartner(
      accessToken: accessToken,
      partnerId: partnerId,
    );
  }

  @override
  Future<PartnerModel> approvePartner({
    required String accessToken,
    required String partnerId,
    int? roomLimit,
  }) {
    return _apiService.approvePartner(
      accessToken: accessToken,
      partnerId: partnerId,
      roomLimit: roomLimit,
    );
  }

  @override
  Future<PartnerModel> rejectPartner({
    required String accessToken,
    required String partnerId,
    String? rejectionReason,
  }) {
    return _apiService.rejectPartner(
      accessToken: accessToken,
      partnerId: partnerId,
      rejectionReason: rejectionReason,
    );
  }

  @override
  Future<PartnerModel> updateRoomLimit({
    required String accessToken,
    required String partnerId,
    required int roomLimit,
  }) {
    return _apiService.updateRoomLimit(
      accessToken: accessToken,
      partnerId: partnerId,
      roomLimit: roomLimit,
    );
  }

  @override
  Future<PartnerModel> suspendPartner({
    required String accessToken,
    required String partnerId,
  }) {
    return _apiService.suspendPartner(
      accessToken: accessToken,
      partnerId: partnerId,
    );
  }

  @override
  Future<PartnerModel> createPartner({
    required String accessToken,
    required String name,
    required String partnerType,
    required String contactEmail,
    String? contactName,
    String? phone,
    String? contractReference,
    required int roomLimit,
  }) {
    return _apiService.createPartner(
      accessToken: accessToken,
      name: name,
      partnerType: partnerType,
      contactEmail: contactEmail,
      contactName: contactName,
      phone: phone,
      contractReference: contractReference,
      roomLimit: roomLimit,
    );
  }
}
