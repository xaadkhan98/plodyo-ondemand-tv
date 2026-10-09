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
import 'package:plodyo_ondemand_tv/data/repositories/usage_queue.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/device_gate.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/home_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/player_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/series_detail_view.dart';
import 'package:video_player/video_player.dart';

const notFound = AuthException(message: 'Not found', statusCode: 404);

/// A room with a small catalogue, whose answers each test can change.
class FakeDevice implements DeviceRepository {
  @override
  bool isPaired = true;

  Object? refusal;
  Object? seriesRefusal;
  final storyQueries = <String?>[];
  final seriesAsked = <String>[];

  /// Story details by id; any other id is a 404.
  final stories = <String, StoryDetail>{};

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
  Future<StoryDetail> getStory(String storyId) async =>
      stories[storyId] ?? (throw notFound);

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
  Future<SeriesDetail> getSeriesDetail(String seriesId) async {
    seriesAsked.add(seriesId);
    if (seriesRefusal case final error?) throw error;
    return const SeriesDetail(
      series: Series(
        id: 'sr1',
        title: 'Counting Club',
        category: 'Fun',
        ageGroup: '5-7',
        language: 'ENG',
        episodeCount: 3,
        learningObjective: 'Counting to ten.',
      ),
      episodes: [
        SeriesEpisode(
          episodeNumber: 1,
          story: Story(id: 'story-a', title: 'One Little Duck'),
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A video or voice that plays only when told to, standing in for the platform player tests lack.
class FakeMedia extends VideoPlayerController {
  FakeMedia(super.url, {this.fails = false}) : super.networkUrl();

  final bool fails;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    if (fails) throw PlatformException(code: 'VideoError');
    value = value.copyWith(
      isInitialized: true,
      duration: const Duration(seconds: 30),
      size: const Size(1920, 1080),
    );
  }

  @override
  Future<void> play() async =>
      value = value.copyWith(isPlaying: true, isCompleted: false);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  /// Where the platform would report playback has reached.
  void reach(Duration position) => value = value.copyWith(position: position);

  void end() => value = value.copyWith(
    isPlaying: false,
    isCompleted: true,
    position: value.duration,
  );

  @override
  Future<void> dispose() {
    disposed = true;
    return super.dispose();
  }
}

/// Real TV configurations: 16:9 panels all draw the same canvas, so the aspect ratios are what vary.
const tvScreens = [
  ('720p MiTV', Size(1280, 720), 1.33125),
  ('1080p Google TV', Size(1920, 1080), 2.0),
  ('4K panel', Size(3840, 2160), 3.0),
  ('4:3 set', Size(1024, 768), 1.0),
  ('21:9 set', Size(2560, 1080), 1.0),
];

/// The guest lane as the app routes it, starting at [at], with every media player recorded in [media].
Future<void> pumpGuestApp(
  WidgetTester tester,
  FakeDevice device, {
  String at = '/',
  Size size = const Size(1920, 1080),
  double dpr = 1,
  UsageQueue? usage,
  List<FakeMedia>? media,
  bool mediaFails = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: at,
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
          GoRoute(
            path: '/series',
            builder: (_, state) => SeriesDetailView(
              seriesId: state.uri.queryParameters['id']!,
              deviceRepository: device,
            ),
          ),
          GoRoute(
            path: '/story',
            builder: (_, state) => PlayerView(
              storyId: state.uri.queryParameters['id']!,
              deviceRepository: device,
              usage: usage,
              openMedia: (url) {
                final player = FakeMedia(url, fails: mediaFails);
                media?.add(player);
                return player;
              },
            ),
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
  await settleFor(tester);
}

/// Animations loop (the spinner, skeletons), so pump time rather than settling.
Future<void> settleFor(WidgetTester tester, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

bool hasFocus(WidgetTester tester, String label) =>
    Focus.of(tester.element(find.text(label))).hasFocus;
