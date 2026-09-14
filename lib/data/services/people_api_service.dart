import '../../core/constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/person_model.dart';
import 'api_client.dart';

/// Service communicating with OnDemand Plodyo Admin People / Users endpoints.
class PeopleApiService {
  PeopleApiService({
    ApiClient? apiClient,
  }) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /ondemand/admin/people or /ondemand/admin/users
  Future<PaginatedResponse<PersonModel>> getPeople({
    required String accessToken,
    String? status,
    String? role,
    int? page,
    int? pageSize,
    String? clientSecret,
  }) async {
    final queryParams = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (role != null && role.isNotEmpty) 'role': role,
      if (page != null) 'page': page.toString(),
      if (pageSize != null) 'page_size': pageSize.toString(),
    };

    final res = await _client.get(
      ApiConstants.adminPeopleEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );

    return PaginatedResponse<PersonModel>.fromJson(
      res as Map<String, dynamic>,
      PersonModel.fromJson,
    );
  }

  /// PATCH /ondemand/admin/users/:id
  Future<PersonModel> updateUser({
    required String accessToken,
    required String personId,
    String? fullName,
    String? status,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final res = await _client.patch(
      '${ApiConstants.adminUsersEndpoint}/$personId',
      body: body,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PersonModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/admin/users/:id/disable
  Future<PersonModel> disableUser({
    required String accessToken,
    required String personId,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      '${ApiConstants.adminUsersEndpoint}/$personId/disable',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PersonModel.fromJson(res as Map<String, dynamic>);
  }

  /// PATCH /ondemand/admin/users/:id/status
  Future<PersonModel> updateStatus({
    required String accessToken,
    required String personId,
    required String status,
    String? clientSecret,
  }) async {
    return updateUser(
      accessToken: accessToken,
      personId: personId,
      status: status,
      clientSecret: clientSecret,
    );
  }

  /// GET /ondemand/admin/users/:id
  Future<PersonModel> getPerson({
    required String accessToken,
    required String personId,
    String? clientSecret,
  }) async {
    final res = await _client.get(
      '${ApiConstants.adminUsersEndpoint}/$personId',
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PersonModel.fromJson(res as Map<String, dynamic>);
  }

  /// PATCH /ondemand/admin/users/:id (name only)
  Future<PersonModel> updateName({
    required String accessToken,
    required String personId,
    required String fullName,
    String? clientSecret,
  }) async {
    return updateUser(
      accessToken: accessToken,
      personId: personId,
      fullName: fullName,
      clientSecret: clientSecret,
    );
  }

  /// PATCH /ondemand/admin/users/:id/role
  Future<PersonModel> updateRole({
    required String accessToken,
    required String personId,
    required String role,
    String? clientSecret,
  }) async {
    final res = await _client.patch(
      '${ApiConstants.adminUsersEndpoint}/$personId',
      body: {'role': role},
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return PersonModel.fromJson(res as Map<String, dynamic>);
  }

  /// Disable / delete user via POST /ondemand/admin/users/:id/disable
  Future<String> deletePerson({
    required String accessToken,
    required String personId,
    String? clientSecret,
  }) async {
    try {
      await disableUser(
        accessToken: accessToken,
        personId: personId,
        clientSecret: clientSecret,
      );
      return 'Account disabled.';
    } catch (_) {
      final res = await _client.delete(
        '${ApiConstants.adminUsersEndpoint}/$personId',
        accessToken: accessToken,
        clientSecret: clientSecret,
      );
      final map = res as Map<String, dynamic>?;
      return map?['message'] as String? ?? 'Account disabled.';
    }
  }
}
