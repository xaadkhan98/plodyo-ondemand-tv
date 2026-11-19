import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';
import 'package:plodyo_ondemand_tv/data/repositories/usage_queue.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/videos_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'support/guest_harness.dart';

const _phare = Story(
  id: 'v1',
  title: 'Le Petit Phare',
  language: 'FRA',
  ageGroup: '2-4',
  mediaUrl: 'https://cdn.example/phare.mp4',
);
const _whale = Story(
  id: 'v2',
  title: 'The Sleepy Whale',
  mediaUrl: 'https://cdn.example/whale.mp4',
);

const _film = StoryDetail(
  story: Story(id: 'v1', title: 'Le Petit Phare', language: 'FRA'),
  mediaUrl: 'https://cdn.example/phare.mp4',
);

/// The full-screen buttons whose tooltip shows: a key just drove them, or a pointer is over them.
List<String> _tooltips(WidgetTester tester) => [
  for (final label in const [
    'Back 10 seconds',
    'Play',
    'Pause',
    'Forward 10 seconds',
  ])
    if (find.text(label).evaluate().isNotEmpty &&
        tester
                .widget<AnimatedOpacity>(
                  find
                      .ancestor(
                        of: find.text(label),
                        matching: find.byType(AnimatedOpacity),
                      )
                      .first,
                )
                .opacity ==
            1)
      label,
];

/// The Videos screen's own search toggle, not the side rail's Search.
final _searchToggle = find.descendant(
  of: find.byType(VideosView),
  matching: find.text('Search'),
);

Future<void> _type(WidgetTester tester, String text) async {
  for (final letter in text.split('')) {
    await tester.sendKeyEvent(LogicalKeyboardKey(letter.codeUnitAt(0)));
  }
  await tester.pump();
}

void main() {
  late FakeDevice device;
  late UsageQueue usage;
  late List<FakeMedia> media;
  late List<FakeMedia> stills;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    device = FakeDevice()
      ..videos = const [_phare, _whale]
      ..films['v1'] = _film;
    usage = UsageQueue(device);
    media = [];
    stills = [];
  });

  group('Home', () {
    testWidgets(
      'ends with a Videos rail ten deep, whose stills wait until it nears the screen; a card plays its film by the video id',
      (tester) async {
        await pumpGuestApp(tester, device, media: media, stills: stills);

        expect(find.text('Cartoon films to watch together.'), findsOneWidget);
        // The rail's title, and the side rail's entry.
        expect(find.text('Videos'), findsNWidgets(2));
        // Ten is the home screen's promise, in the room's own language.
        expect(device.videoQueries, [
          (language: null, search: null, page: null, pageSize: 10),
        ]);
        // Below the other rails, so nothing is loaded for it yet.
        expect(stills, isEmpty);

        await tester.ensureVisible(find.text('Le Petit Phare'));
        await settleFor(tester);
        expect(stills.map((still) => still.dataSource), [
          'https://cdn.example/phare.mp4',
          'https://cdn.example/whale.mp4',
        ]);
        // Past the film's title card.
        expect(
          stills.map((still) => still.value.position),
          everyElement(const Duration(seconds: 6)),
        );

        await tester.tap(find.text('Le Petit Phare'));
        await settleFor(tester);
        expect(device.filmsAsked, ['v1']);
        expect(media.single.value.isPlaying, isTrue);
        // The remote drives the film at once, with no ring to move first.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(media.single.value.position, const Duration(seconds: 10));
      },
    );

    testWidgets(
      'drops the rail when the room has no films, and asks again in a picked language',
      (tester) async {
        device.videos = const [];
        await pumpGuestApp(tester, device);
        expect(find.text('Cartoon films to watch together.'), findsNothing);

        await tester.tap(find.text('English'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Spanish'));
        await settleFor(tester);
        expect(device.videoQueries.map((query) => query.language), [
          null,
          'SPA',
        ]);
      },
    );

    testWidgets('the side rail opens the Videos tab', (tester) async {
      await pumpGuestApp(tester, device);

      await tester.tap(find.byIcon(LucideIcons.clapperboard));
      await settleFor(tester);
      expect(find.text('Cartoon films to watch together 🎬'), findsOneWidget);
    });
  });

  group('Videos tab', () {
    testWidgets(
      "lists the room's films with a search and no age filter; a card plays its film by the video id",
      (tester) async {
        await pumpGuestApp(tester, device, at: '/videos', media: media);

        expect(find.text('Cartoon films to watch together 🎬'), findsOneWidget);
        expect(_searchToggle, findsOneWidget);
        expect(find.text('Search videos by title…'), findsOneWidget);
        expect(find.text('Filters'), findsNothing);
        // The film's age is stuck on its card; there is no length, as every film is one length.
        expect(find.textContaining('2-4', findRichText: true), findsOneWidget);
        expect(device.videoQueries, [
          (language: null, search: null, page: 1, pageSize: 24),
        ]);

        await tester.tap(find.text('Le Petit Phare'));
        await settleFor(tester);
        expect(device.filmsAsked, ['v1']);
        expect(media.single.dataSource, 'https://cdn.example/phare.mp4');
      },
    );

    testWidgets(
      'a keyboard types into the search: titles match once typing pauses, one letter is no search, and a miss says what to change',
      (tester) async {
        await pumpGuestApp(tester, device, at: '/videos');

        // Straight in, with the keyboard closed and nothing on the screen focused.
        await _type(tester, 'p');
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('p'), findsOneWidget);
        expect(device.videoQueries.map((query) => query.search), [null]);

        await _type(tester, 'hare');
        expect(find.text('phare'), findsOneWidget);
        // The search waits for a pause in typing.
        expect(device.videoQueries, hasLength(1));
        await tester.pump(const Duration(milliseconds: 300));
        await settleFor(tester, 2);
        expect(device.videoQueries.last, (
          language: null,
          search: 'phare',
          page: 1,
          pageSize: 24,
        ));
        expect(find.text('Le Petit Phare'), findsOneWidget);
        expect(find.text('The Sleepy Whale'), findsNothing);

        await _type(tester, 'zz');
        await tester.pump(const Duration(milliseconds: 300));
        await settleFor(tester, 2);
        expect(find.text('Nothing here yet'), findsOneWidget);
        expect(find.text('Try a different word.'), findsOneWidget);
      },
    );

    testWidgets('an empty room says to try another language', (tester) async {
      device.videos = const [];
      await pumpGuestApp(tester, device, at: '/videos');

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('Try a different language.'), findsOneWidget);
    });

    testWidgets(
      'with the keyboard open, Back deletes a letter, then closes it; closed, Back works as usual',
      (tester) async {
        final exits = recordExits(tester);
        await pumpGuestApp(tester, device, at: '/videos');
        await tester.tap(_searchToggle);
        await settleFor(tester, 2);
        expect(find.text('Done'), findsOneWidget);

        await tester.tap(find.text('p'));
        await tester.tap(find.text('h'));
        await tester.pump();
        expect(find.text('ph'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('ph'), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('Search videos by title…'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('Done'), findsNothing);
        expect(Focus.of(tester.element(_searchToggle)).hasFocus, isTrue);
        expect(exits, isEmpty);

        await tester.binding.handlePopRoute();
        await settleFor(tester);
        expect(exits, hasLength(1));
      },
    );

    testWidgets(
      'a film with no artwork shows a still six seconds in, let go while the film plays over it; Back stops the film at once',
      (tester) async {
        await pumpGuestApp(
          tester,
          device,
          at: '/videos',
          media: media,
          stills: stills,
        );

        expect(stills.map((still) => still.dataSource), [
          'https://cdn.example/phare.mp4',
          'https://cdn.example/whale.mp4',
        ]);
        expect(
          stills.map((still) => still.value.position),
          everyElement(const Duration(seconds: 6)),
        );
        expect(find.byType(VideoPlayer), findsNWidgets(2));

        await tester.tap(find.text('Le Petit Phare'));
        await settleFor(tester);
        // The film gets the decoder: the screen under it lets its stills go.
        expect(stills.map((still) => still.disposed), [true, true]);
        final film = media.single;
        expect(film.value.isPlaying, isTrue);
        // Typing over the film leaves the search under it alone.
        await _type(tester, 'zz');

        await tester.binding.handlePopRoute();
        await tester.pump();
        // Screens change without a transition, so the film stops with its screen, at once.
        expect(film.disposed, isTrue);
        expect(find.text('Forward 10 seconds'), findsNothing);
        await settleFor(tester);
        expect(find.text('Cartoon films to watch together 🎬'), findsOneWidget);
        expect(find.text('Search videos by title…'), findsOneWidget);
        // Back on the grid, its stills come back.
        expect(stills, hasLength(4));
        expect(stills.skip(2).map((still) => still.disposed), [false, false]);
      },
    );
  });

  group('Full screen', () {
    testWidgets(
      'opens a film straight into playback: ◀ ▶ skip, OK pauses, each lights its button',
      (tester) async {
        await pumpGuestApp(tester, device, at: '/story?video=v1', media: media);
        final film = media.single;

        // Playing on its own, under its own controls rather than the boxed player's.
        expect(film.value.isPlaying, isTrue);
        expect(find.text('Back'), findsNothing);
        expect(find.text('Le Petit Phare'), findsOneWidget);
        expect(find.text('Forward 10 seconds'), findsOneWidget);
        expect(_tooltips(tester), isEmpty);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(film.value.position, const Duration(seconds: 20));
        expect(_tooltips(tester), ['Forward 10 seconds']);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(film.value.position, const Duration(seconds: 10));
        expect(_tooltips(tester), ['Back 10 seconds']);

        // A click on a button does what its key does.
        await tester.tap(find.byIcon(LucideIcons.rotateCw));
        await tester.pump();
        expect(film.value.position, const Duration(seconds: 20));
        expect(find.text('0:20'), findsOneWidget);
        expect(find.text('0:30'), findsOneWidget);

        // OK on an Android remote.
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();
        expect(film.value.isPlaying, isFalse);
        expect(find.text('Play'), findsOneWidget);
        expect(_tooltips(tester), ['Play']);

        // The remote's transport keys work too.
        await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
        await tester.pump();
        expect(film.value.isPlaying, isTrue);
        expect(_tooltips(tester), ['Pause']);
        await tester.sendKeyEvent(LogicalKeyboardKey.mediaRewind);
        await tester.pump();
        expect(film.value.position, const Duration(seconds: 10));
        expect(_tooltips(tester), ['Back 10 seconds']);
      },
    );

    testWidgets(
      'the controls hide while the film plays, a remote key brings them back, and paused they stay',
      (tester) async {
        await pumpGuestApp(tester, device, at: '/story?video=v1', media: media);
        final film = media.single;

        await tester.pump(const Duration(seconds: 4));
        expect(find.text('Forward 10 seconds'), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(find.text('Forward 10 seconds'), findsOneWidget);
        // Nothing is focused on the film, so the key only showed the controls.
        expect(film.value.position, Duration.zero);
        expect(_tooltips(tester), isEmpty);

        // Volume and the like stay the TV's.
        expect(
          await tester.sendKeyEvent(
            LogicalKeyboardKey.audioVolumeUp,
            platform: 'android',
          ),
          isFalse,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump(const Duration(seconds: 4));
        expect(film.value.isPlaying, isFalse);
        // The lit button goes dark with the timer, but paused, the controls stay.
        expect(find.text('Play'), findsOneWidget);
        expect(_tooltips(tester), isEmpty);
      },
    );

    testWidgets(
      'a skip past the end plays the curtain call, whose buttons keep the ring; Again plays from the start',
      (tester) async {
        await pumpGuestApp(tester, device, at: '/story?video=v1', media: media);
        final film = media.single;

        for (var i = 0; i < 4; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        }
        await settleFor(tester, 6);
        expect(film.value.position, const Duration(seconds: 30));
        expect(find.text('The end!'), findsOneWidget);
        expect(find.text('Forward 10 seconds'), findsNothing);
        expect(hasFocus(tester, 'Again'), isTrue);

        // Nothing left of Again or above it: the rail under the film never takes the ring.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(hasFocus(tester, 'Again'), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(hasFocus(tester, 'Pick another'), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(hasFocus(tester, 'Again'), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await settleFor(tester, 2);
        expect(find.text('The end!'), findsNothing);
        expect(film.value.isPlaying, isTrue);
        expect(film.value.position, Duration.zero);
        // The film has the remote again.
        expect(find.text('Forward 10 seconds'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(film.value.position, const Duration(seconds: 10));
      },
    );

    testWidgets('Pick another on the curtain call goes home', (tester) async {
      await pumpGuestApp(tester, device, at: '/story?video=v1', media: media);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      }
      await settleFor(tester, 6);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await settleFor(tester);
      expect(find.text('The end!'), findsNothing);
      expect(find.text('Read now'), findsOneWidget);
      expect(media.single.disposed, isTrue);
    });

    testWidgets(
      'the blue button waits while the film plays; at the end it opens This TV, which the film steps aside for',
      (tester) async {
        await pumpGuestApp(tester, device, at: '/story?video=v1', media: media);
        Future<void> blue() => tester.sendKeyEvent(
          LogicalKeyboardKey.colorF3Blue,
          physicalKey: PhysicalKeyboardKey.f13,
        );

        await blue();
        await settleFor(tester);
        expect(find.text('This TV'), findsNothing);
        expect(media.single.value.isPlaying, isTrue);

        for (var i = 0; i < 4; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        }
        await settleFor(tester, 6);
        expect(find.text('The end!'), findsOneWidget);

        await blue();
        await settleFor(tester);
        expect(find.text('This TV'), findsOneWidget);
        expect(find.text('The end!'), findsNothing);

        await tester.binding.handlePopRoute();
        await settleFor(tester);
        expect(find.text('This TV'), findsNothing);
        expect(find.text('The end!'), findsOneWidget);
      },
    );

    testWidgets('counts the play under the video id, seconds watched only', (
      tester,
    ) async {
      await pumpGuestApp(
        tester,
        device,
        at: '/story?video=v1',
        usage: usage,
        media: media,
      );
      final film = media.single;

      for (var ms = 500; ms <= 3000; ms += 500) {
        film.reach(Duration(milliseconds: ms));
      }
      // A skip is a seek, not watching.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(
        [
          for (final slice in usage.takeBatch())
            (slice['story_id'], slice['start'], slice['watch_seconds']),
        ],
        [('v1', true, 3)],
      );
      await usage.persistNow();
    });

    testWidgets(
      'covers the side rail: a click at the screen edge lands on the film',
      (tester) async {
        await pumpGuestApp(tester, device, at: '/story?video=v1', media: media);

        await tester.tapAt(const Offset(20, 540));
        await tester.pump();
        expect(media.single.value.isPlaying, isFalse);
      },
    );

    testWidgets('a pointer over a button shows what it does', (tester) async {
      await pumpGuestApp(tester, device, at: '/story?video=v1', media: media);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byIcon(LucideIcons.rotateCcw)));
      await tester.pump();
      expect(_tooltips(tester), ['Back 10 seconds']);
    });

    testWidgets(
      'a TV that will not start the film keeps its poster and says to press OK',
      (tester) async {
        device.films['v1'] = const StoryDetail(
          story: Story(
            id: 'v1',
            title: 'Le Petit Phare',
            artworkUrl: 'https://cdn.example/phare.png',
          ),
          mediaUrl: 'https://cdn.example/phare.mp4',
        );
        await pumpGuestApp(
          tester,
          device,
          at: '/story?video=v1',
          media: media,
          playRefused: true,
        );

        expect(
          find.text('This TV would not start the video. Press OK to play.'),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is NetworkImage &&
                (widget.image as NetworkImage).url ==
                    'https://cdn.example/phare.png',
          ),
          findsOneWidget,
        );
        // Paused, the controls stay up.
        await tester.pump(const Duration(seconds: 4));
        expect(find.text('Play'), findsOneWidget);
      },
    );

    testWidgets(
      'a film that will not load falls back to the boxed screen, with its way out',
      (tester) async {
        await pumpGuestApp(
          tester,
          device,
          at: '/story?video=v1',
          mediaFails: true,
        );

        expect(
          find.text('The video for this story is still on its way.'),
          findsOneWidget,
        );
        expect(find.text('Back'), findsOneWidget);
        expect(find.text('Forward 10 seconds'), findsNothing);
      },
    );

    testWidgets('a film that is gone says so', (tester) async {
      await pumpGuestApp(tester, device, at: '/story?video=gone');

      expect(find.text('Story not found'), findsOneWidget);
      expect(device.filmsAsked, ['gone']);
    });
  });
}
