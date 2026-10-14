import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/repositories/partners_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/partners_api_service.dart';

void main() {
  group('PartnersApiService & Repository Tests', () {
    test('getPartners returns paginated partner list on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/partners');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final payload = {
          'data': [
            {
              'id': '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b',
              'name': 'Grand Hotel Downtown',
              'partner_type': 'INDEPENDENT',
              'status': 'ACTIVE',
              'contact_email': 'owner@grandhotel.com',
              'contact_name': 'Jordan Lee',
              'phone': '+1-555-0100',
              'contract_reference': null,
              'room_limit': 60,
              'reviewed_at': '2026-08-20T10:00:00.000Z',
              'reviewed_by': '9f1c7d2e-3b4a-4c5d-8e6f-0a1b2c3d4e5f',
              'rejection_reason': null,
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

      final service = PartnersApiService(
        apiClient: ApiClient(httpClient: mockClient),
      );
      final repo = PartnersRepositoryImpl(apiService: service);

      final response = await repo.getPartners(accessToken: 'test_token');
      expect(response.total, 1);
      expect(response.data.length, 1);
      expect(response.data.first.name, 'Grand Hotel Downtown');
      expect(response.data.first.isActive, isTrue);
      expect(response.data.first.roomLimit, 60);
    });

    test('approvePartner updates partner status to ACTIVE', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.path,
          '/ondemand/admin/partners/partner_123/approve',
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['room_limit'], 80);

        final payload = {
          'id': 'partner_123',
          'name': 'Boutique Lodge',
          'partner_type': 'INDEPENDENT',
          'status': 'ACTIVE',
          'contact_email': 'contact@lodge.com',
          'room_limit': 80,
          'created_at': '2026-08-18T10:00:00.000Z',
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = PartnersApiService(
        apiClient: ApiClient(httpClient: mockClient),
      );
      final repo = PartnersRepositoryImpl(apiService: service);

      final partner = await repo.approvePartner(
        accessToken: 'token',
        partnerId: 'partner_123',
        roomLimit: 80,
      );

      expect(partner.id, 'partner_123');
      expect(partner.status, 'ACTIVE');
      expect(partner.roomLimit, 80);
    });

    test('rejectPartner updates partner status to REJECTED', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/ondemand/admin/partners/partner_123/reject');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['rejection_reason'], 'Incomplete verification document');

        final payload = {
          'id': 'partner_123',
          'name': 'Pending Inn',
          'partner_type': 'HOST',
          'status': 'REJECTED',
          'contact_email': 'inn@test.com',
          'rejection_reason': 'Incomplete verification document',
          'room_limit': 0,
          'created_at': '2026-08-18T10:00:00.000Z',
        };

        return http.Response(jsonEncode(payload), 200);
      });

      final service = PartnersApiService(
        apiClient: ApiClient(httpClient: mockClient),
      );
      final repo = PartnersRepositoryImpl(apiService: service);

      final partner = await repo.rejectPartner(
        accessToken: 'token',
        partnerId: 'partner_123',
        rejectionReason: 'Incomplete verification document',
      );

      expect(partner.isRejected, isTrue);
      expect(partner.rejectionReason, 'Incomplete verification document');
    });
  });
}
