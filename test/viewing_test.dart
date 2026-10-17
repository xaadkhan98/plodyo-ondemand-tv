import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_scale.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_response.dart';
import 'package:plodyo_ondemand_tv/data/models/paginated_response.dart';
import 'package:plodyo_ondemand_tv/data/models/property_model.dart';
import 'package:plodyo_ondemand_tv/data/models/room_model.dart';
import 'package:plodyo_ondemand_tv/data/models/viewing_model.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/properties_repository.dart';
import 'package:plodyo_ondemand_tv/data/services/api_client.dart';
import 'package:plodyo_ondemand_tv/data/services/properties_api_service.dart';
import 'package:plodyo_ondemand_tv/ui/features/viewing/views/viewing_view.dart';

const _totals = {
  'property_id': 'p1',
  'from': '2026-09-26',
  'to': '2026-10-25',
  'plays': 12,
  'watch_seconds': 3900,
  'top_stories': [
    {'story_id': 's1', 'title': 'Moon Picnic', 'plays': 8, 'watch_seconds': 3000},
    {'story_id': 's2', 'title': 'The Sleepy Whale', 'plays': 4, 'watch_seconds': 900},
  ],
  'age_groups': [
    {'age_group': '2-4', 'plays': 9, 'watch_seconds': 3300},
    {'age_group': 'all', 'plays': 3, 'watch_seconds': 600},
  ],
  'hidden_days': 2,
  'min_devices': 5,
};

PropertyModel _property(String id, String name) => PropertyModel.fromJson({
  'id': id,
  'partner_id': 'partner-1',
  'name': name,
  'status': 'ACTIVE',
  'created_at': '2026-08-18T10:00:00.000Z',
});

class _Auth implements AuthRepository {
  @override
  AuthResponse? get currentAuth => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Properties implements PropertiesRepository {
  final asked = <({String propertyId, String from, String to})>[];

  @override
  Future<PaginatedResponse<PropertyModel>> getProperties({
    required String accessToken,
    String? partnerId,
    String? status,
    int? page,
    int? pageSize,
  }) async => PaginatedResponse(
    data: [_property('p1', 'Hotel Riverside'), _property('p2', 'Hotel Hill')],
    total: 2,
    page: 1,
    pageSize: pageSize ?? 25,
  );

  @override
  Future<ViewingTotals> getViewing({
    required String accessToken,
    required String propertyId,
    required String from,
    required String to,
  }) async {
    asked.add((propertyId: propertyId, from: from, to: to));
    return ViewingTotals.fromJson(_totals);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('asks for one property and a date range, with the bearer, and reads the totals', () async {
    late http.Request sent;
    final service = PropertiesApiService(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          sent = request;
          return http.Response(jsonEncode(_totals), 200);
        }),
      ),
    );

    final totals = await PropertiesRepositoryImpl(apiService: service).getViewing(
      accessToken: 'token',
      propertyId: 'p1',
      from: '2026-09-26',
      to: '2026-10-25',
    );

    expect(sent.url.path, '/ondemand/admin/viewing');
    expect(sent.url.queryParameters, {'property_id': 'p1', 'from': '2026-09-26', 'to': '2026-10-25'});
    expect(sent.headers['Authorization'], 'Bearer token');
    expect(totals.plays, 12);
    expect(totals.topStories.first.label, 'Moon Picnic');
    expect(totals.ageGroups.last.label, 'all');
    expect(totals.hiddenDays, 2);
  });

  test('watch time reads in hours and minutes', () {
    expect(formatWatchTime(0), '0 min');
    expect(formatWatchTime(42), 'under a minute');
    expect(formatWatchTime(45 * 60), '45 min');
    expect(formatWatchTime(2 * 3600), '2 h');
    expect(formatWatchTime(3900), '1 h 5 min');
  });

  test('a room carries the app version its TV last reported', () {
    final room = RoomModel.fromJson({'id': 'r1', 'app_version': '1.0.0+5'});

    expect(room.appVersion, '1.0.0+5');
    expect(room.toJson()['app_version'], '1.0.0+5');
  });

  testWidgets(
    'shows property totals, the age split and the hidden days, and re-asks for another range',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final properties = _Properties();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TvCanvas(child: child!),
          home: ViewingView(
            propertiesRepository: properties,
            authRepository: _Auth(),
            today: () => DateTime(2026, 10, 25),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(properties.asked.single, (propertyId: 'p1', from: '2026-09-26', to: '2026-10-25'));
      expect(find.text('12'), findsOneWidget);
      expect(find.text('1 h 5 min'), findsOneWidget);
      expect(find.text('Moon Picnic'), findsOneWidget);
      expect(find.text('Preschool'), findsOneWidget);
      expect(find.text('No age picked'), findsOneWidget);
      expect(find.textContaining('2 days are left out'), findsOneWidget);

      await tester.tap(find.text('Last 7 days'));
      await tester.pump();
      await tester.pump();
      expect(properties.asked.last, (propertyId: 'p1', from: '2026-10-19', to: '2026-10-25'));

      await tester.tap(find.text('Hotel Hill'));
      await tester.pump();
      await tester.pump();
      expect(properties.asked.last.propertyId, 'p2');
    },
  );
}
