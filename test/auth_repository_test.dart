import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/auth_api_service.dart';

void main() {
  group('AuthApiService Tests', () {
    test('login returns AuthResponse on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/auth/login');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['email'], 'ops@grandhotel.com');
        expect(body['password'], 'secret123');

        return http.Response(
          jsonEncode({
            'access_token': 'jwt_access_123',
            'refresh_token': 'opaque_refresh_456',
            'token_type': 'Bearer',
            'expires_in': 900,
            'actor': {
              'user_id': 'user_abc',
              'email': 'ops@grandhotel.com',
              'full_name': 'Dana Okafor',
              'role': 'PARTNER_ADMIN',
              'partner_id': 'partner_999',
              'property_id': null,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AuthApiService(httpClient: mockClient);
      final response = await service.login(
        email: 'ops@grandhotel.com',
        password: 'secret123',
      );

      expect(response.accessToken, 'jwt_access_123');
      expect(response.actor.fullName, 'Dana Okafor');
      expect(response.actor.role, 'PARTNER_ADMIN');
    });

    test('login throws AuthException on HTTP 401 Invalid credentials', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'statusCode': 401,
            'message': 'Invalid credentials',
            'error': 'Unauthorized',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(httpClient: mockClient);

      expect(
        () => service.login(email: 'bad@user.com', password: 'wrong'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Invalid credentials',
        )),
      );
    });

    test('login throws AuthException on HTTP 400 validation error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'statusCode': 400,
            'message': ['password must be at least 12 characters'],
            'error': 'Bad Request',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(httpClient: mockClient);

      expect(
        () => service.login(email: 'test@user.com', password: '123'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('password must be at least 12 characters'),
        )),
      );
    });
  });

  group('AuthRepositoryImpl Tests', () {
    test('signIn updates currentAuth and currentUser on success', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'access_token': 'token_xyz',
            'refresh_token': 'ref_xyz',
            'token_type': 'Bearer',
            'expires_in': 900,
            'actor': {
              'user_id': 'u1',
              'email': 'test@plodyo.com',
              'full_name': 'Test User',
              'role': 'SUPER_ADMIN',
              'partner_id': null,
              'property_id': null,
            },
          }),
          200,
        );
      });

      final repo = AuthRepositoryImpl(
        apiService: AuthApiService(httpClient: mockClient),
      );

      expect(repo.isAuthenticated, isFalse);
      expect(repo.currentUser, isNull);

      final auth = await repo.signIn(
        email: 'test@plodyo.com',
        password: 'password123456',
      );

      expect(repo.isAuthenticated, isTrue);
      expect(repo.currentUser?.fullName, 'Test User');
      expect(repo.currentAuth?.accessToken, 'token_xyz');
      expect(auth.accessToken, 'token_xyz');

      await repo.signOut();
      expect(repo.isAuthenticated, isFalse);
      expect(repo.currentUser, isNull);
    });
  });
}
