import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/device_models.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';
import 'package:plodyo_ondemand_tv/data/repositories/device_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/device_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = 'plodyo.ondemand.device-token';
const _token = 'f3a1c9e2b7d4a6f0';

const _session = {
  'session_id': 'aaaaaaaa-1111-4111-8111-111111111111',
  'room_id': '88888888-8888-4888-8888-888888888888',
  'started_at': '2026-08-28T10:31:00.000Z',
};

/// A repository over a fake API that answers by path and records every request.
(DeviceRepositoryImpl, List<http.Request>) _api(
  Map<String, (int, Object)> routes, {
  String consoleBearer = '',
}) {
  final sent = <http.Request>[];
  final client = MockClient((request) async {
    sent.add(request);
    final (status, body) =
        routes[request.url.path] ?? (404, {'message': 'Not found'});
    return http.Response(jsonEncode(body), status);
  });
  final service = DeviceApiService(apiClient: ApiClient(httpClient: client));
  return (
    DeviceRepositoryImpl(
      apiService: service,
      consoleBearer: () => consoleBearer,
    ),
    sent,
  );
}

/// The same, restored from storage holding [token].
Future<(DeviceRepositoryImpl, List<http.Request>)> _pairedApi(
  Map<String, (int, Object)> routes, {
  String token = _token,
}) async {
  SharedPreferences.setMockInitialValues({_tokenKey: token});
  final api = _api(routes);
  await api.$1.restore();
  return api;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('pairing', () {
    test(
      'normalises the code, sends no credential, and survives a restart',
      () async {
        final (repo, sent) = _api({
          '/ondemand/device/pair': (200, {'device_token': _token}),
        });

        await repo.pair('4f7k92qt');

        expect(jsonDecode(sent.single.body), {'pairing_code': '4F7K-92QT'});
        expect(sent.single.headers['X-Device-Token'], isNull);
        expect(sent.single.headers['Authorization'], isNull);
        final restarted = DeviceRepositoryImpl();
        await restarted.restore();
        expect(restarted.isPaired, isTrue);
      },
    );

    test('refuses a short code without spending a request', () async {
      final (repo, sent) = _api({});

      await expectLater(
        repo.pair('4F7K'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Enter the full 8-character pairing code.',
          ),
        ),
      );
      expect(sent, isEmpty);
    });

    test('re-pairs without offering the credential it replaces', () async {
      final (repo, sent) = await _pairedApi({
        '/ondemand/device/pair': (200, {'device_token': 'new-token'}),
      }, token: 'stale-token');

      await repo.pair('4F7K-92QT');

      expect(sent.single.headers['X-Device-Token'], isNull);
    });

    test('keeps the API wording for a bad code and stores nothing', () async {
      final (repo, _) = _api({
        '/ondemand/device/pair': (
          401,
          {'statusCode': 401, 'message': 'Pairing code is invalid or expired'},
        ),
      });

      await expectLater(
        repo.pair('4F7K-92QT'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Pairing code is invalid or expired',
          ),
        ),
      );
      expect(repo.isPaired, isFalse);
    });

    test('unpairing forgets the token for good', () async {
      final (repo, _) = await _pairedApi({});

      await repo.unpair();

      final restarted = DeviceRepositoryImpl();
      await restarted.restore();
      expect(repo.isPaired, isFalse);
      expect(restarted.isPaired, isFalse);
    });
  });

  group('device lane', () {
    test('sends X-Device-Token and never a bearer or client secret', () async {
      final (repo, sent) = await _pairedApi({
        '/ondemand/device/session': (200, _session),
      });

      final session = await repo.openSession();

      expect(sent.single.headers['X-Device-Token'], _token);
      expect(sent.single.headers['Authorization'], isNull);
      expect(sent.single.headers['x-client-secret'], isNull);
      expect(session.sessionId, _session['session_id']);
      expect(session.roomId, _session['room_id']);
    });

    test('a refused credential throws a 401 and is kept', () async {
      final (repo, _) = await _pairedApi({
        '/ondemand/device/session': (401, {'statusCode': 401}),
      });

      await expectLater(
        repo.openSession(),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
      expect(repo.isPaired, isTrue);
    });

    test(
      'a heartbeat sends the session, activity and clock, and events only when there are some',
      () async {
        final (repo, sent) = await _pairedApi({
          '/ondemand/device/heartbeat': (200, _session),
        });

        await repo.heartbeat(sessionId: 's1', active: true, events: const []);
        await repo.heartbeat(
          sessionId: 's1',
          active: false,
          events: const [
            {'id': 'e1', 'type': 'LANGUAGE_SELECT'},
          ],
        );

        final idle = jsonDecode(sent[0].body) as Map<String, dynamic>;
        expect(idle['session_id'], 's1');
        expect(idle['active'], isTrue);
        expect(DateTime.tryParse(idle['sent_at'] as String), isNotNull);
        expect(idle.containsKey('events'), isFalse);
        expect((jsonDecode(sent[1].body) as Map)['events'], [
          {'id': 'e1', 'type': 'LANGUAGE_SELECT'},
        ]);
      },
    );

    test('config drops an age group /content would refuse', () async {
      final (repo, _) = await _pairedApi({
        '/ondemand/device/config': (
          200,
          {
            'languages': [
              {'code': 'ENG', 'name': 'English'},
            ],
            'age_groups': ['0-2', '3-5', '5-7'],
            'default_language': 'ENG',
          },
        ),
      });

      final config = await repo.getConfig();

      expect(config.languages.single.name, 'English');
      expect(config.ageGroups, [AgeGroup.toddler, AgeGroup.earlySchool]);
      expect(config.defaultLanguage, 'ENG');
    });
  });

  group('catalogue', () {
    const page = {'data': <Object>[], 'total': 0, 'page': 1, 'page_size': 20};

    test(
      'omits unset filters, so the room default applies, and passes set ones',
      () async {
        final (repo, sent) = await _pairedApi({
          '/ondemand/device/content': (200, page),
        });

        await repo.getStories();
        await repo.getStories(
          language: 'SPA',
          ageGroup: AgeGroup.preschool,
          storyType: StoryType.standalone,
          page: 2,
        );

        expect(sent[0].url.queryParameters, isEmpty);
        expect(sent[1].url.queryParameters, {
          'language': 'SPA',
          'age_group': '2-4',
          'story_type': 'STANDALONE',
          'page': '2',
        });
      },
    );

    test(
      'a story detail carries the media URL and pages; a missing video stays null',
      () async {
        final (repo, _) = await _pairedApi({
          '/ondemand/device/content/s1': (
            200,
            {
              'id': 's1',
              'title': 'Moon Picnic',
              'media_url': null,
              'pages': [
                {
                  'page_number': 1,
                  'title': null,
                  'text': 'Once upon a time',
                  'image_url': null,
                  'audio_url': 'https://cdn/1.mp3',
                },
              ],
            },
          ),
        });

        final detail = await repo.getStory('s1');

        expect(detail.story.title, 'Moon Picnic');
        expect(detail.mediaUrl, isNull);
        expect(detail.pages.single.audioUrl, 'https://cdn/1.mp3');
      },
    );

    test(
      'unpaired, the console reads the same rows under /admin with its bearer',
      () async {
        final (repo, sent) = _api({
          '/ondemand/admin/content': (200, page),
          '/ondemand/admin/series': (200, page),
        }, consoleBearer: 'console');

        await repo.getStories(ageGroup: AgeGroup.toddler);
        await repo.getSeries(seriesType: SeriesType.learning);

        expect(sent.map((r) => r.url.path), [
          '/ondemand/admin/content',
          '/ondemand/admin/series',
        ]);
        expect(sent.first.url.queryParameters, {'age_group': '0-2'});
        for (final request in sent) {
          expect(request.headers['Authorization'], 'Bearer console');
          expect(request.headers['X-Device-Token'], isNull);
        }
      },
    );

    test('series episodes are keyed by their story id', () async {
      final (repo, _) = await _pairedApi({
        '/ondemand/device/series/sr1': (
          200,
          {
            'id': 'sr1',
            'title': 'Counting Club',
            'series_type': 'LEARNING',
            'category': 'Math Fundamental & Logic',
            'age_group': '5-7',
            'language': 'ENG',
            'episode_count': 10,
            'episodes': [
              {'episode_number': 1, 'story_id': 'st9', 'title': 'One'},
            ],
          },
        ),
      });

      final detail = await repo.getSeriesDetail('sr1');

      expect(detail.series.seriesType, SeriesType.learning);
      expect(detail.episodes.single.story.id, 'st9');
      expect(detail.episodes.single.episodeNumber, 1);
    });
  });
}
