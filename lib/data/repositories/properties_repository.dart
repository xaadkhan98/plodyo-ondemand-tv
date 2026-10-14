import '../models/paginated_response.dart';
import '../models/property_model.dart';
import '../services/properties_api_service.dart';

/// Global shared instance of [PropertiesRepository].
final PropertiesRepository sharedPropertiesRepository =
    PropertiesRepositoryImpl();

/// Abstract repository for managing properties.
abstract class PropertiesRepository {
  Future<PaginatedResponse<PropertyModel>> getProperties({
    required String accessToken,
    String? partnerId,
    String? status,
    int? page,
    int? pageSize,
  });

  Future<PropertyModel> getProperty({
    required String accessToken,
    required String propertyId,
  });

  Future<PropertyModel> createProperty({
    required String accessToken,
    required String partnerId,
    required String name,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
  });

  Future<PropertyModel> updateProperty({
    required String accessToken,
    required String propertyId,
    String? name,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
  });

  Future<PropertyModel> suspendProperty({
    required String accessToken,
    required String propertyId,
  });

  Future<PropertyModel> activateProperty({
    required String accessToken,
    required String propertyId,
  });
}

/// Concrete implementation of [PropertiesRepository] calling live backend API.
class PropertiesRepositoryImpl implements PropertiesRepository {
  PropertiesRepositoryImpl({PropertiesApiService? apiService})
    : _apiService = apiService ?? PropertiesApiService();

  final PropertiesApiService _apiService;

  @override
  Future<PaginatedResponse<PropertyModel>> getProperties({
    required String accessToken,
    String? partnerId,
    String? status,
    int? page,
    int? pageSize,
  }) {
    return _apiService.getProperties(
      accessToken: accessToken,
      partnerId: partnerId,
      status: status,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<PropertyModel> getProperty({
    required String accessToken,
    required String propertyId,
  }) {
    return _apiService.getProperty(
      accessToken: accessToken,
      propertyId: propertyId,
    );
  }

  @override
  Future<PropertyModel> createProperty({
    required String accessToken,
    required String partnerId,
    required String name,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
  }) {
    return _apiService.createProperty(
      accessToken: accessToken,
      partnerId: partnerId,
      name: name,
      country: country,
      city: city,
      timezone: timezone,
      defaultLanguage: defaultLanguage,
    );
  }

  @override
  Future<PropertyModel> updateProperty({
    required String accessToken,
    required String propertyId,
    String? name,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
  }) {
    return _apiService.updateProperty(
      accessToken: accessToken,
      propertyId: propertyId,
      name: name,
      country: country,
      city: city,
      timezone: timezone,
      defaultLanguage: defaultLanguage,
    );
  }

  @override
  Future<PropertyModel> suspendProperty({
    required String accessToken,
    required String propertyId,
  }) {
    return _apiService.suspendProperty(
      accessToken: accessToken,
      propertyId: propertyId,
    );
  }

  @override
  Future<PropertyModel> activateProperty({
    required String accessToken,
    required String propertyId,
  }) {
    return _apiService.activateProperty(
      accessToken: accessToken,
      propertyId: propertyId,
    );
  }
}
