import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';

import 'support/guest_harness.dart';

/// Every guest screen on every kind of panel. flutter_test fails a test on any overflow the framework
/// reports, so laying a screen out is the check.
void main() {
  final device = FakeDevice()
    ..stories['film'] = const StoryDetail(
      story: Story(id: 'film', title: 'Moon Picnic', description: 'A picnic.'),
      mediaUrl: 'https://cdn.example/moon.mp4',
    )
    ..stories['book'] = const StoryDetail(
      story: Story(id: 'book', title: 'The Sleepy Whale'),
      pages: [
        StoryPage(
          pageNumber: 1,
          text: 'Once upon a tide.',
          audioUrl: 'https://cdn.example/1.mp3',
        ),
      ],
    )
    ..stories['art'] = const StoryDetail(
      story: Story(id: 'art', title: 'Counting Fireflies'),
    );

  const screens = [
    '/',
    '/stories',
    '/series',
    '/learning',
    '/series?id=sr1',
    '/story?id=gone',
    '/story?id=film',
    '/story?id=book',
    '/story?id=art',
  ];

  for (final (name, size, dpr) in tvScreens) {
    testWidgets('the guest screens lay out cleanly on a $name', (tester) async {
      for (final at in screens) {
        await pumpGuestApp(tester, device, at: at, size: size, dpr: dpr);
      }
    });
  }
}
