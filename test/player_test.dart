import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';
import 'package:plodyo_ondemand_tv/data/repositories/usage_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/guest_harness.dart';

const _film = StoryDetail(
  story: Story(
    id: 'film',
    title: 'Moon Picnic',
    duration: 'short',
    ageGroup: '2-4',
    language: 'ENG',
    description: 'A picnic on the moon.',
  ),
  mediaUrl: 'https://cdn.example/moon.mp4',
);

const _book = StoryDetail(
  story: Story(id: 'book', title: 'The Sleepy Whale'),
  pages: [
    StoryPage(
      pageNumber: 1,
      text: 'Once upon a tide.',
      audioUrl: 'https://cdn.example/1.mp3',
    ),
    StoryPage(pageNumber: 2, text: 'The whale yawned.'),
    StoryPage(
      pageNumber: 3,
      text: 'And slept.',
      audioUrl: 'https://cdn.example/3.mp3',
    ),
  ],
);

void main() {
  late FakeDevice device;
  late UsageQueue usage;
  late List<FakeMedia> media;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    device = FakeDevice()
      ..stories['film'] = _film
      ..stories['book'] = _book;
    usage = UsageQueue(device);
    media = [];
  });

  List<String> recorded() => [
    for (final event in usage.takeBatch())
      '${event['type']} ${event['watch_seconds'] ?? ''}'.trim(),
  ];

  testWidgets(
    'a film plays from its button, counts only the seconds watched, and celebrates its end',
    (tester) async {
      await pumpGuestApp(
        tester,
        device,
        at: '/story?id=film',
        usage: usage,
        media: media,
      );
      final video = media.single;

      expect(find.text('Moon Picnic'), findsOneWidget);
      expect(find.text('Preschool'), findsOneWidget);
      expect(find.text('Short'), findsOneWidget);
      // The first control takes the ring, as in the reference.
      expect(hasFocus(tester, 'Back'), isTrue);

      // Below the film, as in the reference: the page scrolls to it.
      await tester.ensureVisible(find.text('Play'));
      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(find.text('Pause'), findsOneWidget);

      for (var ms = 500; ms <= 3000; ms += 500) {
        video.reach(Duration(milliseconds: ms));
      }
      // A jump is a seek, not watching.
      video.reach(const Duration(seconds: 20));
      video.end();
      await settleFor(tester, 6);

      expect(find.text('The end!'), findsOneWidget);
      expect(recorded(), ['STORY_PLAY 3', 'STORY_COMPLETE']);

      await tester.tap(find.text('Again'));
      await settleFor(tester, 2);
      expect(find.text('The end!'), findsNothing);
      expect(video.value.isPlaying, isTrue);

      await tester.ensureVisible(find.text('Back'));
      await tester.tap(find.text('Back'));
      await settleFor(tester);
      expect(video.disposed, isTrue);
      await usage.persistNow();
    },
  );

  testWidgets('the remote\'s play key drives the film', (tester) async {
    await pumpGuestApp(
      tester,
      device,
      at: '/story?id=film',
      usage: usage,
      media: media,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
    await tester.pump();
    expect(media.single.value.isPlaying, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
    await tester.pump();
    expect(media.single.value.isPlaying, isFalse);
  });

  testWidgets(
    'a story with no film opens the book: pages turn, each page\'s voice plays, and reading counts',
    (tester) async {
      await pumpGuestApp(
        tester,
        device,
        at: '/story?id=book',
        usage: usage,
        media: media,
      );

      expect(find.text('Page 1 of 3 🌟'), findsOneWidget);
      expect(find.text('Once upon a tide.'), findsOneWidget);
      expect(find.text('Listen — The Sleepy Whale'), findsOneWidget);

      await tester.tap(find.text('Listen — The Sleepy Whale'));
      await tester.pump();
      expect(media.single.value.isPlaying, isTrue);

      // Time on page one counts as reading.
      await tester.pump(const Duration(seconds: 2));
      final onPageOne = usage.takeBatch().single['watch_seconds']! as int;
      expect(onPageOne, greaterThanOrEqualTo(2));

      await tester.tap(find.text('Next'));
      await settleFor(tester, 2);
      expect(find.text('Page 2 of 3 🌟'), findsOneWidget);
      // A page with no narration has no bar, and the last page's voice is gone.
      expect(find.text('Listen — The Sleepy Whale'), findsNothing);
      expect(media.single.disposed, isTrue);

      // From Next, right is a page turn; the disabled Next hands the ring to Previous.
      expect(hasFocus(tester, 'Next'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settleFor(tester, 2);
      expect(find.text('Page 3 of 3 🌟'), findsOneWidget);
      expect(hasFocus(tester, 'Previous'), isTrue);

      // A second on the last page finishes the story.
      await tester.pump(const Duration(seconds: 1));
      expect(recorded(), ['STORY_PLAY ${onPageOne + 1}', 'STORY_COMPLETE']);

      // From Previous, left is a page back rather than the side rail.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settleFor(tester, 2);
      expect(find.text('Page 2 of 3 🌟'), findsOneWidget);
      await usage.persistNow();
    },
  );

  testWidgets(
    'a film that will not load falls back to the book, or to the art when there is none',
    (tester) async {
      device.stories['book'] = const StoryDetail(
        story: Story(id: 'book', title: 'The Sleepy Whale'),
        mediaUrl: 'https://cdn.example/broken.mp4',
        pages: [StoryPage(pageNumber: 1, text: 'Once upon a tide.')],
      );
      await pumpGuestApp(
        tester,
        device,
        at: '/story?id=book',
        mediaFails: true,
      );
      expect(find.text('Page 1 of 1 🌟'), findsOneWidget);

      device.stories['film'] = const StoryDetail(
        story: Story(id: 'film', title: 'Moon Picnic'),
        mediaUrl: 'https://cdn.example/broken.mp4',
      );
      await pumpGuestApp(
        tester,
        device,
        at: '/story?id=film',
        mediaFails: true,
      );
      expect(
        find.text('The video for this story is still on its way.'),
        findsOneWidget,
      );
      expect(find.text('Play'), findsNothing);
    },
  );

  testWidgets('a missing story says so and leads home', (tester) async {
    await pumpGuestApp(tester, device, at: '/story?id=gone');

    expect(find.text('Story not found'), findsOneWidget);
    expect(
      find.text('It may have been removed, or it has no video yet.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Back to the catalogue'));
    await settleFor(tester);
    expect(find.text('Read now'), findsOneWidget);
  });
}
