import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_scale.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_theme.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/auth_api_service.dart';
import 'package:plodyo_ondemand_tv/ui/features/main_layout.dart';

const _access = 'plodyo.ondemand.access-token';
const _refresh = 'plodyo.ondemand.refresh-token';

const _admin = {
  'user_id': 'u1',
  'email': 'ops@plodyo.example',
  'full_name': 'Ops',
  'role': 'SUPER_ADMIN',
  'partner_id': null,
  'property_id': null,
};

/// A console API whose /auth/me accepts only [valid], and whose refresh hands out [renewed] or refuses.
class _Api {
  _Api({this.valid = 'a2', this.renewed = true, this.actor = _admin});

  String valid;
  bool renewed;
  bool offline = false;
  Map<String, Object?> actor;
  final sent = <http.Request>[];

  late final repo = AuthRepositoryImpl(
    apiService: AuthApiService(
      apiClient: ApiClient(httpClient: MockClient(_answer)),
    ),
  );

  int get refreshes =>
      sent.where((r) => r.url.path == '/ondemand/auth/refresh').length;

  Future<http.Response> _answer(http.Request request) async {
    sent.add(request);
    if (offline) throw const SocketException('offline');
    return switch (request.url.path) {
      '/ondemand/auth/me' =>
        request.headers['Authorization'] == 'Bearer $valid'
            ? http.Response(jsonEncode({'actor': actor}), 200)
            : http.Response('{"statusCode":401}', 401),
      '/ondemand/auth/refresh' =>
        renewed
            ? http.Response(
                jsonEncode({'access_token': valid, 'refresh_token': 'r2'}),
                200,
              )
            : http.Response('{"statusCode":401}', 401),
      '/ondemand/auth/login' => http.Response(
        jsonEncode({
          'access_token': valid,
          'refresh_token': 'r1',
          'actor': actor,
        }),
        200,
      ),
      _ => http.Response('{}', 200),
    };
  }
}

/// Restored from a previous run's storage, holding an access token the API no longer takes.
Future<_Api> _restored(_Api api) async {
  FlutterSecureStorage.setMockInitialValues({_access: 'a1', _refresh: 'r1'});
  await api.repo.restore();
  ApiClient.renewBearer = api.repo.renew;
  addTearDown(() => ApiClient.renewBearer = null);
  return api;
}

Future<Map<String, String>> _stored() => const FlutterSecureStorage().readAll();

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'a session survives a restart, and its actor comes back from /auth/me',
    () async {
      final first = _Api(valid: 'a1');
      await first.repo.signIn(email: 'ops@plodyo.example', password: 'pw');
      expect(await _stored(), {_access: 'a1', _refresh: 'r1'});

      final next = _Api(valid: 'a1');
      await next.repo.restore();
      // Signed in, but no screen may read the actor until /auth/me has answered.
      expect(next.repo.isAuthenticated, isTrue);
      expect(next.repo.currentUser, isNull);

      await next.repo.resume();
      expect(next.repo.currentUser?.fullName, 'Ops');
    },
  );

  test(
    'an expired access token is renewed once for every caller, and the rotated pair is kept',
    () async {
      final api = await _restored(_Api());

      await Future.wait([api.repo.resume(), api.repo.getMe()]);

      // A refresh token is single use: two 401s share one renewal.
      expect(api.refreshes, 1);
      expect(api.repo.currentUser?.fullName, 'Ops');
      expect(await _stored(), {_access: 'a2', _refresh: 'r2'});
    },
  );

  test('a refused renewal ends the session and forgets the pair', () async {
    final api = await _restored(_Api(renewed: false));
    var ended = false;
    api.repo.addListener(() => ended = true);

    await expectLater(
      api.repo.resume(),
      throwsA(isA<AuthException>().having((e) => e.statusCode, 'status', 401)),
    );

    expect(ended, isTrue);
    expect(api.repo.isAuthenticated, isFalse);
    expect(await _stored(), isEmpty);
  });

  test(
    'a scope that does not fit the role is refused at sign-in, and at boot with a notice',
    () async {
      final stray = {..._admin}..['role'] = 'PARTNER_ADMIN';

      final signingIn = _Api(valid: 'a1', actor: stray);
      await expectLater(
        signingIn.repo.signIn(email: 'ops@plodyo.example', password: 'pw'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            incoherentScopeMessage,
          ),
        ),
      );
      expect(signingIn.repo.isAuthenticated, isFalse);

      final booting = await _restored(_Api(actor: stray));
      await booting.repo.resume();
      expect(booting.repo.isAuthenticated, isFalse);
      expect(booting.repo.takeNotice(), incoherentScopeMessage);
      expect(booting.repo.takeNotice(), isNull);
    },
  );

  testWidgets(
    'the console waits for /auth/me, and an unreachable API offers a retry that needs no password',
    (tester) async {
      final api = await tester.runAsync(
        () => _restored(_Api()..offline = true),
      );
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: TvTheme.light,
          builder: (context, child) => TvCanvas(child: child!),
          home: MainTvLayout(
            currentPath: '/overview',
            authRepository: api!.repo,
            child: const Text('Overview screen'),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.text('Cannot reach Plodyo'), findsOneWidget);
      expect(find.text('Overview screen'), findsNothing);
      expect(api.repo.isAuthenticated, isTrue);

      api.offline = false;
      await tester.tap(find.text('Try again'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.text('Overview screen'), findsOneWidget);
      expect(api.repo.currentUser?.fullName, 'Ops');
    },
  );
}
