import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/repositories/device_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/device_api_service.dart';

void main() {
  group('DeviceApiService & DeviceRepository Tests', () {
    test(
      'pair sends POST /ondemand/device/pair and stores deviceToken',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/ondemand/device/pair');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['pairing_code'], '4F7K92QT');

          final payload = {
            'device_token':
                'f3a1c9e2b7d4a6f0e8c1b2a3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
          };
          return http.Response(jsonEncode(payload), 200);
        });

        final service = DeviceApiService(
          apiClient: ApiClient(httpClient: mockClient),
        );
        final repo = DeviceRepositoryImpl(apiService: service);

        expect(repo.isPaired, isFalse);
        final res = await repo.pair('4F7K92QT');
        expect(
          res.deviceToken,
          'f3a1c9e2b7d4a6f0e8c1b2a3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
        );
        expect(repo.isPaired, isTrue);
        expect(repo.deviceToken, res.deviceToken);
      },
    );

    test(
      'getSession sends GET /ondemand/device/session with X-Device-Token',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/ondemand/device/pair') {
            return http.Response(
              jsonEncode({'device_token': 'test_device_token'}),
              200,
            );
          }
          expect(request.url.path, '/ondemand/device/session');
          expect(request.headers['X-Device-Token'], 'test_device_token');

          final payload = {
            'session_id': 'aaaaaaaa-1111-4111-8111-111111111111',
            'room_id': '88888888-8888-4888-8888-888888888888',
            'started_at': '2026-08-28T10:31:00.000Z',
          };
          return http.Response(jsonEncode(payload), 200);
        });

        final service = DeviceApiService(
          apiClient: ApiClient(httpClient: mockClient),
        );
        final repo = DeviceRepositoryImpl(apiService: service);

        await repo.pair('CODE1234');
        final session = await repo.getSession();
        expect(session.sessionId, 'aaaaaaaa-1111-4111-8111-111111111111');
        expect(session.roomId, '88888888-8888-4888-8888-888888888888');
        expect(repo.currentSession, session);
      },
    );

    test(
      'getConfig sends GET /ondemand/device/config and parses languages/age groups',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/ondemand/device/pair') {
            return http.Response(
              jsonEncode({'device_token': 'test_device_token'}),
              200,
            );
          }
          expect(request.url.path, '/ondemand/device/config');
          expect(request.headers['X-Device-Token'], 'test_device_token');

          final payload = {
            'languages': [
              {'code': 'ENG', 'name': 'English'},
              {'code': 'SPA', 'name': 'Spanish'},
            ],
            'age_groups': ['0-2', '2-4', '5-7'],
            'default_language': 'SPA',
          };
          return http.Response(jsonEncode(payload), 200);
        });

        final service = DeviceApiService(
          apiClient: ApiClient(httpClient: mockClient),
        );
        final repo = DeviceRepositoryImpl(apiService: service);

        await repo.pair('CODE1234');
        final config = await repo.getConfig();
        expect(config.languages.length, 2);
        expect(config.languages.first.code, 'ENG');
        expect(config.ageGroups, ['0-2', '2-4', '5-7']);
        expect(config.defaultLanguage, 'SPA');
        expect(repo.currentConfig, config);
      },
    );

    test(
      'getCatalogue sends GET /ondemand/device/content with query parameters',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/ondemand/device/pair') {
            return http.Response(
              jsonEncode({'device_token': 'test_device_token'}),
              200,
            );
          }
          expect(request.url.path, '/ondemand/device/content');
          expect(request.url.queryParameters['language'], 'ENG');
          expect(request.url.queryParameters['age_group'], '2-4');
          expect(request.headers['X-Device-Token'], 'test_device_token');

          final payload = {
            'data': [
              {
                'id': '11111111-2222-4333-8444-555555555555',
                'title': 'The Brave Little Lighthouse',
                'description': 'A lighthouse keeper learns to trust the storm.',
                'artwork_url': 'https://cdn.plodyo.com/covers/lighthouse.jpg',
                'duration': 'short',
                'language': 'ENG',
                'age_group': '2-4',
              },
            ],
            'total': 128,
            'page': 1,
            'page_size': 25,
          };
          return http.Response(jsonEncode(payload), 200);
        });

        final service = DeviceApiService(
          apiClient: ApiClient(httpClient: mockClient),
        );
        final repo = DeviceRepositoryImpl(apiService: service);

        await repo.pair('CODE1234');
        final res = await repo.getCatalogue(language: 'ENG', ageGroup: '2-4');
        expect(res.total, 128);
        expect(res.data.length, 1);
        expect(res.data.first.title, 'The Brave Little Lighthouse');
        expect(
          res.data.first.artworkUrl,
          'https://cdn.plodyo.com/covers/lighthouse.jpg',
        );
      },
    );

    test(
      'getStoryDetail sends GET /ondemand/device/content/:id and returns media_url',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/ondemand/device/pair') {
            return http.Response(
              jsonEncode({'device_token': 'test_device_token'}),
              200,
            );
          }
          expect(request.url.path, '/ondemand/device/content/story_uuid_1');
          expect(request.headers['X-Device-Token'], 'test_device_token');

          final payload = {
            'id': 'story_uuid_1',
            'title': 'The Brave Little Lighthouse',
            'description': 'A lighthouse keeper learns to trust the storm.',
            'artwork_url': 'https://cdn.plodyo.com/covers/lighthouse.jpg',
            'duration': 'short',
            'language': 'ENG',
            'age_group': '2-4',
            'media_url': 'https://cdn.plodyo.com/videos/lighthouse.mp4',
          };
          return http.Response(jsonEncode(payload), 200);
        });

        final service = DeviceApiService(
          apiClient: ApiClient(httpClient: mockClient),
        );
        final repo = DeviceRepositoryImpl(apiService: service);

        await repo.pair('CODE1234');
        final detail = await repo.getStoryDetail('story_uuid_1');
        expect(detail.id, 'story_uuid_1');
        expect(detail.mediaUrl, 'https://cdn.plodyo.com/videos/lighthouse.mp4');
      },
    );
  });
}
