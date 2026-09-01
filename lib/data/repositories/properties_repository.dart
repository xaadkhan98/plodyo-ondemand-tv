import '../models/auth_exception.dart';
import '../models/paginated_response.dart';
import '../models/property_model.dart';
import '../services/properties_api_service.dart';

/// Global shared instance of [PropertiesRepository].
final PropertiesRepository sharedPropertiesRepository = PropertiesRepositoryImpl();

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

/// Concrete implementation of [PropertiesRepository] with live API and fallback state handling.
class PropertiesRepositoryImpl implements PropertiesRepository {
  PropertiesRepositoryImpl({
    PropertiesApiService? apiService,
  }) : _apiService = apiService ?? PropertiesApiService();

  final PropertiesApiService _apiService;

  final List<PropertyModel> _localProperties = [
    const PropertyModel(
      id: '5d8e2a11-7c44-4b6a-9d31-2e3f4a5b6c7d',
      partnerId: '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
      name: 'Grand Hotel Downtown - Riverside',
      status: 'ACTIVE',
      country: 'US',
      city: 'Austin',
      timezone: 'America/Chicago',
      defaultLanguage: 'en',
      createdAt: '2026-08-18T10:00:00.000Z',
    ),
    const PropertyModel(
      id: '5d8e2a11-7c44-4b6a-9d31-2e3f4a5b6c7e',
      partnerId: '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
      name: 'Grand Hotel Downtown - Uptown Tower',
      status: 'ACTIVE',
      country: 'US',
      city: 'Austin',
      timezone: 'America/Chicago',
      defaultLanguage: 'en',
      createdAt: '2026-08-19T10:00:00.000Z',
    ),
  ];

  @override
  Future<PaginatedResponse<PropertyModel>> getProperties({
    required String accessToken,
    String? partnerId,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        return await _apiService.getProperties(
          accessToken: accessToken,
          partnerId: partnerId,
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

    var filtered = _localProperties;
    if (partnerId != null && partnerId.isNotEmpty) {
      filtered = filtered.where((p) => p.partnerId == partnerId).toList();
    }
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((p) => p.status.toUpperCase() == status.toUpperCase()).toList();
    }
    return PaginatedResponse<PropertyModel>(
      data: List.unmodifiable(filtered),
      total: filtered.length,
      page: page ?? 1,
      pageSize: pageSize ?? 25,
    );
  }

  @override
  Future<PropertyModel> getProperty({
    required String accessToken,
    required String propertyId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        return await _apiService.getProperty(
          accessToken: accessToken,
          propertyId: propertyId,
        );
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    return _localProperties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => _localProperties.first,
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
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.createProperty(
          accessToken: accessToken,
          partnerId: partnerId,
          name: name,
          country: country,
          city: city,
          timezone: timezone,
          defaultLanguage: defaultLanguage,
        );
        _localProperties.insert(0, res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final newProp = PropertyModel(
      id: 'prop-${DateTime.now().millisecondsSinceEpoch}',
      partnerId: partnerId,
      name: name,
      status: 'ACTIVE',
      country: country ?? 'US',
      city: city ?? 'Austin',
      timezone: timezone ?? 'America/Chicago',
      defaultLanguage: defaultLanguage ?? 'en',
      createdAt: DateTime.now().toIso8601String(),
    );
    _localProperties.insert(0, newProp);
    return newProp;
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
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.updateProperty(
          accessToken: accessToken,
          propertyId: propertyId,
          name: name,
          country: country,
          city: city,
          timezone: timezone,
          defaultLanguage: defaultLanguage,
        );
        _updateLocal(res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localProperties.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      final updated = _localProperties[index].copyWith(
        name: name,
        country: country,
        city: city,
        timezone: timezone,
        defaultLanguage: defaultLanguage,
        updatedAt: DateTime.now().toIso8601String(),
      );
      _localProperties[index] = updated;
      return updated;
    }
    throw Exception('Property not found');
  }

  @override
  Future<PropertyModel> suspendProperty({
    required String accessToken,
    required String propertyId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.suspendProperty(
          accessToken: accessToken,
          propertyId: propertyId,
        );
        _updateLocal(res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localProperties.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      final updated = _localProperties[index].copyWith(
        status: 'SUSPENDED',
        updatedAt: DateTime.now().toIso8601String(),
      );
      _localProperties[index] = updated;
      return updated;
    }
    throw Exception('Property not found');
  }

  @override
  Future<PropertyModel> activateProperty({
    required String accessToken,
    required String propertyId,
  }) async {
    if (accessToken.isNotEmpty) {
      try {
        final res = await _apiService.activateProperty(
          accessToken: accessToken,
          propertyId: propertyId,
        );
        _updateLocal(res);
        return res;
      } on AuthException catch (e) {
        if (!e.isNetworkError && e.statusCode != null && e.statusCode! > 0) {
          rethrow;
        }
      } catch (_) {}
    }

    final index = _localProperties.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      final updated = _localProperties[index].copyWith(
        status: 'ACTIVE',
        updatedAt: DateTime.now().toIso8601String(),
      );
      _localProperties[index] = updated;
      return updated;
    }
    throw Exception('Property not found');
  }

  void _updateLocal(PropertyModel updated) {
    final index = _localProperties.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _localProperties[index] = updated;
    } else {
      _localProperties.add(updated);
    }
  }
}
