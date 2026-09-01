import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/auth_api_service.dart';

void main() {
  group('Extended Auth, Public Invites & Registration Tests', () {
    test('forgotPassword sends POST and returns message', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/auth/forgot-password');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'ops@grandhotel.com');

        return http.Response(
          jsonEncode({'message': 'If that email is registered, a reset link has been sent.'}),
          200,
        );
      });

      final service = AuthApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = AuthRepositoryImpl(apiService: service);

      final msg = await repo.forgotPassword(email: 'ops@grandhotel.com');
      expect(msg, 'If that email is registered, a reset link has been sent.');
    });

    test('resetPassword sends token & new password and returns message', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/auth/reset-password');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['token'], 'token_123');
        expect(body['password'], 'new_secure_pwd_123');

        return http.Response(jsonEncode({'message': 'Password updated.'}), 200);
      });

      final service = AuthApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = AuthRepositoryImpl(apiService: service);

      final msg = await repo.resetPassword(token: 'token_123', newPassword: 'new_secure_pwd_123');
      expect(msg, 'Password updated.');
    });

    test('getMe returns actor and memberships list', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/auth/me');

        final payload = {
          'actor': {
            'user_id': 'user_123',
            'email': 'ops@grandhotel.com',
            'full_name': 'Dana Okafor',
            'role': 'PARTNER_ADMIN',
            'partner_id': 'partner_123',
            'property_id': null,
          },
          'memberships': [
            {
              'id': 'membership_1',
              'role': 'PARTNER_ADMIN',
              'partner_id': 'partner_123',
              'property_id': null,
              'created_at': '2026-08-18T10:00:00.000Z',
            }
          ],
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = AuthApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = AuthRepositoryImpl(apiService: service);

      final res = await repo.getMe();
      expect(res.actor.fullName, 'Dana Okafor');
      expect(res.memberships.length, 1);
      expect(res.memberships.first.role, 'PARTNER_ADMIN');
    });

    test('previewInvite and acceptInvite work as specified in API doc', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/accept')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['password'], 'my_secret_pass');
          return http.Response(jsonEncode({'message': 'Invite accepted. You can now sign in.'}), 200);
        } else {
          final payload = {
            'email': 'ops@grandhotel.com',
            'role': 'PROPERTY_ADMIN',
            'partner_name': 'Grand Hotel Downtown',
            'property_name': 'Grand Hotel Downtown - Riverside',
            'account_exists': false,
          };
          return http.Response(jsonEncode(payload), 200);
        }
      });

      final service = AuthApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = AuthRepositoryImpl(apiService: service);

      final preview = await repo.previewInvite('inv_token_abc');
      expect(preview.email, 'ops@grandhotel.com');
      expect(preview.partnerName, 'Grand Hotel Downtown');
      expect(preview.accountExists, isFalse);

      final acceptMsg = await repo.acceptInvite(
        token: 'inv_token_abc',
        password: 'my_secret_pass',
      );
      expect(acceptMsg, 'Invite accepted. You can now sign in.');
    });

    test('registerVenue sends POST /ondemand/public/registrations and returns status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/public/registrations');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Grand Hotel Downtown');
        expect(body['partner_type'], 'INDEPENDENT');

        final payload = {
          'partner_id': 'partner_new_1',
          'status': 'PENDING_APPROVAL',
          'message': 'Registration received. We will email you once it is reviewed.',
        };
        return http.Response(jsonEncode(payload), 200);
      });

      final service = AuthApiService(apiClient: ApiClient(httpClient: mockClient));
      final repo = AuthRepositoryImpl(apiService: service);

      final res = await repo.registerVenue(
        name: 'Grand Hotel Downtown',
        partnerType: 'INDEPENDENT',
        contactEmail: 'owner@grandhotel.com',
      );

      expect(res['partner_id'], 'partner_new_1');
      expect(res['status'], 'PENDING_APPROVAL');
    });
  });
}
