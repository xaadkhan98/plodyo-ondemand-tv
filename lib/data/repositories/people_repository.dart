import '../models/paginated_response.dart';
import '../models/person_model.dart';
import '../services/people_api_service.dart';

/// Global shared instance of [PeopleRepository].
final PeopleRepository sharedPeopleRepository = PeopleRepositoryImpl();

/// Abstract repository for managing people / users in the organization scope.
abstract class PeopleRepository {
  Future<PaginatedResponse<PersonModel>> getPeople({
    required String accessToken,
    String? status,
    String? role,
    int? page,
    int? pageSize,
  });

  Future<PersonModel> getPerson({
    required String accessToken,
    required String personId,
  });

  Future<PersonModel> updateName({
    required String accessToken,
    required String personId,
    required String fullName,
  });

  Future<PersonModel> updateStatus({
    required String accessToken,
    required String personId,
    required String status,
  });

  /// Ends every session the account holds and stops it signing in; refused for the caller's own account.
  Future<PersonModel> disablePerson({
    required String accessToken,
    required String personId,
  });
}

/// Concrete implementation of [PeopleRepository] calling live backend API.
class PeopleRepositoryImpl implements PeopleRepository {
  PeopleRepositoryImpl({PeopleApiService? apiService})
    : _apiService = apiService ?? PeopleApiService();

  final PeopleApiService _apiService;

  @override
  Future<PaginatedResponse<PersonModel>> getPeople({
    required String accessToken,
    String? status,
    String? role,
    int? page,
    int? pageSize,
  }) {
    return _apiService.getPeople(
      accessToken: accessToken,
      status: status,
      role: role,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<PersonModel> getPerson({
    required String accessToken,
    required String personId,
  }) {
    return _apiService.getPerson(accessToken: accessToken, personId: personId);
  }

  @override
  Future<PersonModel> updateName({
    required String accessToken,
    required String personId,
    required String fullName,
  }) {
    return _apiService.updateName(
      accessToken: accessToken,
      personId: personId,
      fullName: fullName,
    );
  }

  @override
  Future<PersonModel> updateStatus({
    required String accessToken,
    required String personId,
    required String status,
  }) {
    return _apiService.updateStatus(
      accessToken: accessToken,
      personId: personId,
      status: status,
    );
  }

  @override
  Future<PersonModel> disablePerson({
    required String accessToken,
    required String personId,
  }) {
    return _apiService.disableUser(
      accessToken: accessToken,
      personId: personId,
    );
  }
}
