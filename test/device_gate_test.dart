import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plodyo_ondemand_tv/core/constants/languages.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_scale.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/device_models.dart';
import 'package:plodyo_ondemand_tv/data/models/paginated_response.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';
import 'package:plodyo_ondemand_tv/data/repositories/device_repository.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/device_gate.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/home_view.dart';

/// A room with a catalogue, whose answers each test can change.
class _Device implements DeviceRepository {
  @override
  bool isPaired = true;

  Object? refusal;
  final storyQueries = <String?>[];

  @override
  Future<void> unpair() async => isPaired = false;

  @override
  Future<DeviceConfig> getConfig() async {
    if (refusal case final error?) throw error;
    return const DeviceConfig(
      languages: [Language('ENG', 'English'), Language('SPA', 'Spanish')],
      ageGroups: [AgeGroup.preschool],
      defaultLanguage: 'ENG',
    );
  }

  @override
  Future<DeviceSession> openSession() async => const DeviceSession(
    sessionId: 's1',
    roomId: 'r1',
    startedAt: '2026-10-09T12:00:00Z',
  );

  @override
  Future<PaginatedResponse<Story>> getStories({
    String? language,
    AgeGroup? ageGroup,
    StoryType? storyType,
    int? page,
    int? pageSize,
  }) async {
    storyQueries.add(language);
    return const PaginatedResponse(
      data: [
        Story(
          id: 'st1',
          title: 'Moon Picnic',
          duration: 'short',
          ageGroup: '2-4',
        ),
        Story(id: 'st2', title: 'The Sleepy Whale'),
      ],
      total: 2,
      page: 1,
      pageSize: 10,
    );
  }

  @override
  Future<PaginatedResponse<Series>> getSeries({
    SeriesType? seriesType,
    String? category,
    AgeGroup? ageGroup,
    String? language,
    int? page,
    int? pageSize,
  }) async => PaginatedResponse(
    data: [
      if (seriesType == SeriesType.entertainment)
        const Series(
          id: 'sr1',
          title: 'Counting Club',
          category: 'Fun',
          ageGroup: '5-7',
          language: 'ENG',
          episodeCount: 1,
        ),
    ],
    total: 1,
    page: 1,
    pageSize: 10,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Device device;

  setUp(() => device = _Device());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => DeviceGate(
            currentPath: state.uri.path,
            deviceRepository: device,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => HomeView(deviceRepository: device),
            ),
          ],
        ),
        GoRoute(path: '/sign-in', builder: (_, _) => const Text('sign in')),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => TvCanvas(child: child!),
      ),
    );
    // Animations loop (the spinner, skeletons), so pump time rather than settling.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets(
    'an unpaired TV offers set-up or the console, and set-up opens pairing',
    (tester) async {
      device.isPaired = false;
      await pumpApp(tester);

      expect(find.text('Set up this TV'), findsOneWidget);
      expect(find.text('Sign in to the console'), findsOneWidget);

      await tester.tap(find.text('Set up this TV'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Enter the pairing code'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Set up this TV'), findsOneWidget);
    },
  );

  testWidgets(
    'a paired TV lands on Home: hero first, then the rails, and an empty category hides',
    (tester) async {
      await pumpApp(tester);

      expect(find.text('Picked for this room'), findsOneWidget);
      expect(find.text('Read now'), findsOneWidget);
      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('Series'), findsOneWidget);
      expect(find.text('1 Episode'), findsOneWidget);
      expect(find.text('Learning series'), findsNothing);
      // The hero's call to action takes first focus.
      expect(Focus.of(tester.element(find.text('Read now'))).hasFocus, isTrue);
    },
  );

  testWidgets(
    'the language pill opens the picker, and a pick reloads the catalogue in it',
    (tester) async {
      await pumpApp(tester);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Pick a language'), findsOneWidget);
      expect(find.text('As set for this room (English)'), findsOneWidget);

      await tester.tap(find.text('Spanish'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('Pick a language'), findsNothing);
      expect(find.text('Spanish'), findsOneWidget);
      expect(device.storyQueries, [null, 'SPA']);
    },
  );

  testWidgets(
    'a refused credential is kept, and only setting up again forgets it',
    (tester) async {
      device.refusal = const AuthException(
        message: 'Unauthorized',
        statusCode: 401,
      );
      await pumpApp(tester);

      expect(find.text('This TV cannot reach its room'), findsOneWidget);
      expect(device.isPaired, isTrue);

      await tester.tap(find.text('Set up this TV again'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(device.isPaired, isFalse);
      expect(find.text('Set up this TV'), findsOneWidget);
    },
  );

  testWidgets('a network fault offers a retry that recovers', (tester) async {
    device.refusal = AuthException.network('Cannot reach Plodyo TV.');
    await pumpApp(tester);

    expect(find.text('Cannot reach Plodyo'), findsOneWidget);
    expect(find.text('Cannot reach Plodyo TV.'), findsOneWidget);

    device.refusal = null;
    await tester.tap(find.text('Try again'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Read now'), findsOneWidget);
  });
}
