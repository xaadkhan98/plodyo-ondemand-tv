import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/repositories/properties_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/properties_api_service.dart';

void main() {
  group('PropertiesApiService & Repository Tests', () {
    test('getProperties returns paginated properties on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/properties');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final payload = {
          'data': [
            {
              'id': '5d8e2a11-7c44-4b6a-9d31-2e3f4a5b6c7d',
              'partner_id': '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
              'name': 'Grand Hotel Downtown - Riverside',
              'status': 'ACTIVE',
              'country': 'US',
              'city': 'Austin',
              'timezone': 'America/Chicago',
              'default_language': 'en',
              'created_at': '2026-08-18T10:00:00.000Z',
              'updated_at': '2026-08-20T10:00:00.000Z',
            },
          ],
          'total': 1,
          'page': 1,
          'page_size': 25,
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = PropertiesApiService(
        apiClient: ApiClient(httpClient: mockClient),
      );
      final repo = PropertiesRepositoryImpl(apiService: service);

      final response = await repo.getProperties(accessToken: 'test_token');
      expect(response.total, 1);
      expect(response.data.length, 1);
      expect(response.data.first.name, 'Grand Hotel Downtown - Riverside');
      expect(response.data.first.city, 'Austin');
      expect(response.data.first.isActive, isTrue);
    });

    test(
      'createProperty sends POST and returns newly created property',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/ondemand/admin/properties');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['name'], 'Seaside Villas');
          expect(body['country'], 'US');
          expect(body['city'], 'Miami');

          final payload = {
            'id': 'prop_new_1',
            'partner_id': 'partner_123',
            'name': 'Seaside Villas',
            'status': 'ACTIVE',
            'country': 'US',
            'city': 'Miami',
            'timezone': 'America/New_York',
            'default_language': 'en',
            'created_at': '2026-08-18T10:00:00.000Z',
          };

          return http.Response(jsonEncode(payload), 200);
        });

        final service = PropertiesApiService(
          apiClient: ApiClient(httpClient: mockClient),
        );
        final repo = PropertiesRepositoryImpl(apiService: service);

        final property = await repo.createProperty(
          accessToken: 'token',
          partnerId: 'partner_123',
          name: 'Seaside Villas',
          country: 'US',
          city: 'Miami',
          timezone: 'America/New_York',
          defaultLanguage: 'en',
        );

        expect(property.id, 'prop_new_1');
        expect(property.name, 'Seaside Villas');
        expect(property.city, 'Miami');
        expect(property.isActive, isTrue);
      },
    );

    test('suspendProperty and activateProperty toggle status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/suspend')) {
          return http.Response(
            jsonEncode({
              'id': 'prop_123',
              'partner_id': 'partner_123',
              'name': 'Seaside Villas',
              'status': 'SUSPENDED',
              'created_at': '2026-08-18T10:00:00.000Z',
            }),
            200,
          );
        } else if (request.url.path.endsWith('/activate')) {
          return http.Response(
            jsonEncode({
              'id': 'prop_123',
              'partner_id': 'partner_123',
              'name': 'Seaside Villas',
              'status': 'ACTIVE',
              'created_at': '2026-08-18T10:00:00.000Z',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = PropertiesApiService(
        apiClient: ApiClient(httpClient: mockClient),
      );
      final repo = PropertiesRepositoryImpl(apiService: service);

      final suspended = await repo.suspendProperty(
        accessToken: 'token',
        propertyId: 'prop_123',
      );
      expect(suspended.isSuspended, isTrue);

      final activated = await repo.activateProperty(
        accessToken: 'token',
        propertyId: 'prop_123',
      );
      expect(activated.isActive, isTrue);
    });
  });
}
