import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/repositories/invites_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/invites_api_service.dart';

void main() {
  group('InvitesApiService & Repository Tests', () {
    test('getInvites returns paginated invites on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/invites');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final payload = {
          'data': [
            {
              'id': '7b6c5d4e-3f2a-1b0c-9d8e-7f6a5b4c3d2e',
              'email': 'staff@grandhotel.com',
              'role': 'PROPERTY_ADMIN',
              'partner_id': '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
              'property_id': '5d8e2a11-7c44-4b6a-9d31-2e3f4a5b6c7d',
              'status': 'PENDING',
              'sent_at': '2026-08-18T10:00:00.000Z',
              'accepted_at': null,
              'expires_at': '2026-08-25T10:00:00.000Z',
              'created_at': '2026-08-18T10:00:00.000Z',
            }
          ],
          'total': 1,
          'page': 1,
          'page_size': 25,
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = InvitesApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = InvitesRepositoryImpl(apiService: service);

      final response = await repo.getInvites(accessToken: 'test_token');
      expect(response.total, 1);
      expect(response.data.length, 1);
      expect(response.data.first.email, 'staff@grandhotel.com');
      expect(response.data.first.isPending, isTrue);
      expect(response.data.first.role, 'PROPERTY_ADMIN');
    });

    test('createInvite sends POST and returns newly created invite', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/invites');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'newmanager@resort.com');
        expect(body['role'], 'PARTNER_ADMIN');

        final payload = {
          'id': 'invite_new_1',
          'email': 'newmanager@resort.com',
          'role': 'PARTNER_ADMIN',
          'partner_id': 'partner_123',
          'property_id': null,
          'status': 'PENDING',
          'created_at': '2026-08-18T10:00:00.000Z',
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = InvitesApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = InvitesRepositoryImpl(apiService: service);

      final invite = await repo.createInvite(
        accessToken: 'token',
        email: 'newmanager@resort.com',
        role: 'PARTNER_ADMIN',
        partnerId: 'partner_123',
      );

      expect(invite.id, 'invite_new_1');
      expect(invite.email, 'newmanager@resort.com');
      expect(invite.role, 'PARTNER_ADMIN');
      expect(invite.isPending, isTrue);
    });

    test('revokeInvite sends DELETE and returns success message', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/ondemand/admin/invites/invite_123');

        return http.Response(jsonEncode({'message': 'Invite revoked.'}), 200);
      });

      final service = InvitesApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = InvitesRepositoryImpl(apiService: service);

      final message = await repo.revokeInvite(
        accessToken: 'token',
        inviteId: 'invite_123',
      );

      expect(message, 'Invite revoked.');
    });
  });
}
