import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';

import 'support/guest_harness.dart';

void main() {
  late FakeDevice device;

  setUp(() => device = FakeDevice());

  testWidgets(
    'an unpaired TV offers set-up or the console, and set-up opens pairing',
    (tester) async {
      device.isPaired = false;
      await pumpGuestApp(tester, device);

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
      await pumpGuestApp(tester, device);

      expect(find.text('Picked for this room'), findsOneWidget);
      expect(find.text('Read now'), findsOneWidget);
      // By their subtitles: the rail's labels carry the same names.
      expect(
        find.text('One story at a time, start to finish.'),
        findsOneWidget,
      );
      expect(
        find.text('Follow the same friends through every episode.'),
        findsOneWidget,
      );
      expect(find.text('1 Episode'), findsOneWidget);
      expect(find.text('Learning series'), findsNothing);
      // The hero's call to action takes first focus.
      expect(hasFocus(tester, 'Read now'), isTrue);
    },
  );

  testWidgets(
    'the language pill opens the picker, and a pick reloads the catalogue in it',
    (tester) async {
      await pumpGuestApp(tester, device);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Pick a language'), findsOneWidget);
      expect(find.text('As set for this room (English)'), findsOneWidget);

      await tester.tap(find.text('Spanish'));
      await settleFor(tester);
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
      await pumpGuestApp(tester, device);

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
    await pumpGuestApp(tester, device);

    expect(find.text('Cannot reach Plodyo'), findsOneWidget);
    expect(find.text('Cannot reach Plodyo TV.'), findsOneWidget);

    device.refusal = null;
    await tester.tap(find.text('Try again'));
    await settleFor(tester);
    expect(find.text('Read now'), findsOneWidget);
  });

  testWidgets(
    'a series card opens its picture book, and an episode opens its story',
    (tester) async {
      device.stories['story-a'] = const StoryDetail(
        story: Story(id: 'story-a', title: 'One Little Duck'),
      );
      await pumpGuestApp(tester, device);

      await tester.ensureVisible(find.text('Counting Club'));
      await tester.tap(find.text('Counting Club'));
      await settleFor(tester);
      expect(device.seriesAsked, ['sr1']);
      expect(find.text('Episodes'), findsOneWidget);
      expect(find.text('Early school'), findsOneWidget);
      // Counts the episodes servable now, not the three planned.
      expect(find.text('1 episode'), findsOneWidget);
      expect(find.text('Counting to ten.'), findsOneWidget);
      expect(hasFocus(tester, 'Back'), isTrue);

      await tester.ensureVisible(find.text('One Little Duck'));
      await tester.tap(find.text('One Little Duck'));
      await settleFor(tester);
      expect(
        find.text('The video for this story is still on its way.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a missing series says so once, without retrying, and leads home',
    (tester) async {
      device.seriesRefusal = notFound;
      await pumpGuestApp(tester, device, at: '/series?id=gone');

      expect(find.text('Series not found'), findsOneWidget);
      expect(device.seriesAsked, ['gone']);

      await tester.tap(find.text('Back to the catalogue'));
      await settleFor(tester);
      expect(find.text('Read now'), findsOneWidget);
    },
  );
}
