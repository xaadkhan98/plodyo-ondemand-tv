import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/actor.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_response.dart';

void main() {
  group('Actor Model Tests', () {
    test('parses JSON correctly into Actor model', () {
      final json = {
        'user_id': '9f1c7d2e-3b4a-4c5d-8e6f-0a1b2c3d4e5f',
        'email': 'ops@grandhotel.com',
        'full_name': 'Dana Okafor',
        'role': 'PARTNER_ADMIN',
        'partner_id': '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
        'property_id': null,
      };

      final actor = Actor.fromJson(json);

      expect(actor.userId, '9f1c7d2e-3b4a-4c5d-8e6f-0a1b2c3d4e5f');
      expect(actor.email, 'ops@grandhotel.com');
      expect(actor.fullName, 'Dana Okafor');
      expect(actor.role, 'PARTNER_ADMIN');
      expect(actor.partnerId, '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b');
      expect(actor.propertyId, isNull);
      expect(actor.isPartnerAdmin, isTrue);
      expect(actor.isSuperAdmin, isFalse);
      expect(actor.isPropertyAdmin, isFalse);
    });

    test('Actor toJson serializes correctly', () {
      const actor = Actor(
        userId: '123',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'SUPER_ADMIN',
        partnerId: null,
        propertyId: null,
      );

      final json = actor.toJson();
      expect(json['user_id'], '123');
      expect(json['role'], 'SUPER_ADMIN');
      expect(actor.isSuperAdmin, isTrue);
    });
  });

  group('AuthResponse Model Tests', () {
    test('parses login 200 response JSON correctly', () {
      final json = {
        'access_token': 'test_access_jwt',
        'refresh_token': 'test_refresh_token_opaque',
        'token_type': 'Bearer',
        'expires_in': 900,
        'actor': {
          'user_id': 'uid-123',
          'email': 'admin@plodyo.com',
          'full_name': 'Admin User',
          'role': 'SUPER_ADMIN',
          'partner_id': null,
          'property_id': null,
        },
      };

      final authResponse = AuthResponse.fromJson(json);

      expect(authResponse.accessToken, 'test_access_jwt');
      expect(authResponse.refreshToken, 'test_refresh_token_opaque');
      expect(authResponse.tokenType, 'Bearer');
      expect(authResponse.expiresIn, 900);
      expect(authResponse.actor.fullName, 'Admin User');
      expect(authResponse.actor.role, 'SUPER_ADMIN');
    });
  });

  group('AuthException Parsing Tests', () {
    test('parses 401 NestJS unauthorized error', () {
      final body = jsonEncode({
        'statusCode': 401,
        'message': 'Invalid credentials',
        'error': 'Unauthorized',
      });

      final exception = AuthException.fromResponseBody(body, 401);

      expect(exception.statusCode, 401);
      expect(exception.message, 'Invalid credentials');
      expect(exception.error, 'Unauthorized');
    });

    test('parses 400 validation error with array of strings', () {
      final body = jsonEncode({
        'statusCode': 400,
        'message': [
          'email must be an email',
          'password must be at least 12 characters',
        ],
        'error': 'Bad Request',
      });

      final exception = AuthException.fromResponseBody(body, 400);

      expect(exception.statusCode, 400);
      expect(exception.validationErrors.length, 2);
      expect(exception.message, contains('email must be an email'));
      expect(exception.message, contains('password must be at least 12 characters'));
    });

    test('parses 429 rate limit error', () {
      final body = jsonEncode({
        'statusCode': 429,
        'message': 'Rate limit exceeded, back off and retry',
        'error': 'Too Many Requests',
      });

      final exception = AuthException.fromResponseBody(body, 429);

      expect(exception.statusCode, 429);
      expect(exception.message, 'Rate limit exceeded, back off and retry');
    });

    test('creates network error with fallback message', () {
      final exception = AuthException.network();
      expect(exception.message, 'Cannot reach Plodyo TV. Check the network connection.');
      expect(exception.statusCode, 0);
    });
  });
}
