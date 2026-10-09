import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/device_models.dart';
import 'package:plodyo_ondemand_tv/data/models/paginated_response.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';

import 'support/guest_harness.dart';

/// [total] standalone stories, served [pageSize] at a time.
PaginatedResponse<Story> _shelf(int page, int pageSize, int total) {
  final first = (page - 1) * pageSize;
  return PaginatedResponse(
    data: [
      for (var i = first; i < first + pageSize && i < total; i++)
        Story(id: 'g$i', title: 'Story $i'),
    ],
    total: total,
    page: page,
    pageSize: pageSize,
  );
}

void main() {
  late FakeDevice device;

  setUp(() => device = FakeDevice());

  testWidgets(
    'stories load a page at a time, and "Load more" appends the next',
    (tester) async {
      device.shelf = (query) => _shelf(query.page!, query.pageSize!, 30);
      await pumpGuestApp(tester, device, at: '/stories');

      expect(
        find.text("Pick a story and let's go somewhere magical ✨"),
        findsOneWidget,
      );
      expect(find.text('Story 23'), findsOneWidget);
      expect(find.text('Story 24'), findsNothing);

      await tester.ensureVisible(find.text('Load more'));
      await tester.tap(find.text('Load more'));
      await settleFor(tester);
      expect(find.text('Story 29'), findsOneWidget);
      // Everything is served, so the button goes.
      expect(find.text('Load more'), findsNothing);
      expect(device.shelfQueries.map((q) => q.page), [1, 2]);
    },
  );

  testWidgets(
    'picking an age titles the screen with it and reloads the grid under it, keeping the card open',
    (tester) async {
      device.shelf = (query) => _shelf(query.page!, query.pageSize!, 2);
      await pumpGuestApp(tester, device, at: '/stories');
      // Closed, the card shows the current pick.
      expect(find.text('All ages'), findsOneWidget);

      await tester.tap(find.text('Filters'));
      await settleFor(tester, 2);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text("Who's watching"), findsOneWidget);

      await tester.tap(find.text('Preschool'));
      await settleFor(tester);
      expect(find.text('Done'), findsOneWidget);
      expect(device.shelfQueries.last.ageGroup, AgeGroup.preschool);
      // The title and the chip both read Preschool.
      expect(find.text('Preschool'), findsNWidgets(2));
    },
  );

  testWidgets('an empty shelf says what to change', (tester) async {
    device.shelf = (query) => _shelf(1, query.pageSize!, 0);
    await pumpGuestApp(tester, device, at: '/stories');

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Try a different age group or language.'), findsOneWidget);
  });

  testWidgets(
    'series list as cards that open their episodes, with topic chips read off the catalogue',
    (tester) async {
      device.categories = ['bedtime stories', 'math fundamental & logic'];
      await pumpGuestApp(tester, device, at: '/learning');

      expect(find.text('Learning series'), findsOneWidget);
      expect(
        find.text('Learn something brand new today, one giggle at a time 🌟'),
        findsOneWidget,
      );

      await tester.tap(find.text('Filters'));
      await settleFor(tester, 2);
      expect(find.text("What's it about"), findsOneWidget);
      expect(find.text('Bedtime stories'), findsOneWidget);

      await tester.tap(find.text('Math fundamental & logic'));
      await settleFor(tester);
      expect(device.seriesQueries.last.category, 'math fundamental & logic');
      expect(device.seriesQueries.last.seriesType, SeriesType.learning);

      await tester.ensureVisible(find.text('Number Ninjas'));
      await tester.tap(find.text('Number Ninjas'));
      await settleFor(tester);
      expect(find.text('Episodes'), findsOneWidget);
    },
  );

  testWidgets('one topic is no filter at all', (tester) async {
    device.categories = ['bedtime stories'];
    await pumpGuestApp(tester, device, at: '/series');

    expect(find.text('Series'), findsWidgets);
    await tester.tap(find.text('Filters'));
    await settleFor(tester, 2);
    expect(find.text("What's it about"), findsNothing);
  });
}
