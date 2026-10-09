import '../../core/constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/property_model.dart';
import 'api_client.dart';

/// Service communicating with OnDemand Plodyo Admin Properties endpoints.
class PropertiesApiService {
  PropertiesApiService({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /ondemand/admin/properties
  Future<PaginatedResponse<PropertyModel>> getProperties({
    required String accessToken,
    String? partnerId,
    String? status,
    int? page,
    int? pageSize,
    String? clientSecret,
  }) async {
    final queryParams = <String, String>{
      if (partnerId != null && partnerId.isNotEmpty) 'partner_id': partnerId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (page != null) 'page': page.toString(),
      if (pageSize != null) 'page_size': pageSize.toString(),
    };

    final res = await _client.get(
      ApiConstants.adminPropertiesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );

    return PaginatedResponse<PropertyModel>.fromJson(
      res as Map<String, dynamic>,
      PropertyModel.fromJson,
    );
  }

  /// GET /ondemand/admin/properties/:id
  Future<PropertyModel> getProperty({
    required String accessToken,
    required String propertyId,
    String? clientSecret,
  }) async {
    final res = await _client.get(
      '${ApiConstants.adminPropertiesEndpoint}/$propertyId',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PropertyModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/properties
  Future<PropertyModel> createProperty({
    required String accessToken,
    required String partnerId,
    required String name,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'partner_id': partnerId,
      'name': name,
      if (country != null && country.isNotEmpty) 'country': country,
      if (city != null && city.isNotEmpty) 'city': city,
      if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
      if (defaultLanguage != null && defaultLanguage.isNotEmpty)
        'default_language': defaultLanguage,
    };

    final res = await _client.post(
      ApiConstants.adminPropertiesEndpoint,
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PropertyModel.fromJson(res as Map<String, dynamic>);
  }

  /// PATCH /ondemand/admin/properties/:id — null means unchanged; an empty string clears the field.
  Future<PropertyModel> updateProperty({
    required String accessToken,
    required String propertyId,
    String? name,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'country': ?country,
      'city': ?city,
      'timezone': ?timezone,
      'default_language': ?defaultLanguage,
    };

    final res = await _client.patch(
      '${ApiConstants.adminPropertiesEndpoint}/$propertyId',
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PropertyModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/properties/:id/suspend
  Future<PropertyModel> suspendProperty({
    required String accessToken,
    required String propertyId,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminPropertiesEndpoint}/$propertyId/suspend',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PropertyModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/properties/:id/activate
  Future<PropertyModel> activateProperty({
    required String accessToken,
    required String propertyId,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminPropertiesEndpoint}/$propertyId/activate',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PropertyModel.fromJson(res as Map<String, dynamic>);
  }
}
