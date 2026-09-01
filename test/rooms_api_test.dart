import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/repositories/rooms_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/rooms_api_service.dart';

void main() {
  group('RoomsApiService & Repository Tests', () {
    test('getRooms returns paginated room list on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/rooms');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final payload = {
          'data': [
            {
              'id': '88888888-8888-4888-8888-888888888888',
              'property_id': '5d8e2a11-7c44-4b6a-9d31-2e3f4a5b6c7d',
              'room_label': 'Room 214',
              'status': 'UNPROVISIONED',
              'default_language': 'es',
              'provisioned_at': null,
              'last_seen_at': null,
              'created_at': '2026-08-18T10:00:00.000Z',
              'updated_at': '2026-08-18T10:00:00.000Z',
            }
          ],
          'total': 1,
          'page': 1,
          'page_size': 25,
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = RoomsApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = RoomsRepositoryImpl(apiService: service);

      final response = await repo.getRooms(accessToken: 'test_token');
      expect(response.total, 1);
      expect(response.data.length, 1);
      expect(response.data.first.roomLabel, 'Room 214');
      expect(response.data.first.isUnprovisioned, isTrue);
      expect(response.data.first.defaultLanguage, 'es');
    });

    test('createRoom sends POST and returns newly created room', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/rooms');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['room_label'], 'Room 501');
        expect(body['property_id'], 'prop_123');

        final payload = {
          'id': 'room_new_1',
          'property_id': 'prop_123',
          'room_label': 'Room 501',
          'status': 'UNPROVISIONED',
          'default_language': null,
          'created_at': '2026-08-18T10:00:00.000Z',
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = RoomsApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = RoomsRepositoryImpl(apiService: service);

      final room = await repo.createRoom(
        accessToken: 'token',
        propertyId: 'prop_123',
        roomLabel: 'Room 501',
      );

      expect(room.id, 'room_new_1');
      expect(room.roomLabel, 'Room 501');
      expect(room.isUnprovisioned, isTrue);
    });

    test('deleteRoom sends DELETE and returns success message', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/ondemand/admin/rooms/room_123');

        return http.Response(jsonEncode({'message': 'Room deleted.'}), 200);
      });

      final service = RoomsApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = RoomsRepositoryImpl(apiService: service);

      final msg = await repo.deleteRoom(
        accessToken: 'token',
        roomId: 'room_123',
      );

      expect(msg, 'Room deleted.');
    });
  });
}
