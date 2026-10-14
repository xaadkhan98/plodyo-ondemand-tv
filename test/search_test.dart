import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/paginated_response.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';

import 'support/guest_harness.dart';

const _titles = ['Moon Picnic', 'Moonlight Lullaby', 'The Sleepy Whale'];

/// A catalogue of [total] stories, three with real titles first.
PaginatedResponse<Story> Function(ShelfQuery) _catalogue(int total) => (query) {
  // Home asks for its rail without a page.
  final (page, size) = (query.page ?? 1, query.pageSize ?? 10);
  final first = (page - 1) * size;
  return PaginatedResponse(
    data: [
      for (var i = first; i < first + size && i < total; i++)
        Story(id: 's$i', title: i < _titles.length ? _titles[i] : 'Story $i'),
    ],
    total: total,
    page: page,
    pageSize: size,
  );
};

Future<void> _type(WidgetTester tester, String text) async {
  for (final letter in text.split('')) {
    await tester.sendKeyEvent(LogicalKeyboardKey(letter.codeUnitAt(0)));
  }
  await tester.pump();
}

void main() {
  late FakeDevice device;

  setUp(() => device = FakeDevice()..shelf = _catalogue(30));

  testWidgets(
    'prompts until two letters, then matches titles once typing pauses',
    (tester) async {
      await pumpGuestApp(tester, device, at: '/search');
      expect(find.text('What would you like to watch?'), findsOneWidget);
      expect(find.text('Search stories…'), findsOneWidget);

      await _type(tester, 'mo');
      // The query shows each key at once; matching waits for the pause.
      expect(find.text('mo'), findsOneWidget);
      expect(find.text('What would you like to watch?'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await settleFor(tester, 2);
      expect(find.text('2 results'), findsOneWidget);
      expect(find.text('Moonlight Lullaby'), findsOneWidget);
      expect(find.text('The Sleepy Whale'), findsNothing);
      // One short page covers a small room.
      expect(device.shelfQueries.map((q) => (q.page, q.pageSize)), [(1, 100)]);
    },
  );

  testWidgets('reads at most 300 rows, and says so when nothing matches', (
    tester,
  ) async {
    device.shelf = _catalogue(350);
    await pumpGuestApp(tester, device, at: '/search');

    await _type(tester, 'zz');
    await tester.pump(const Duration(milliseconds: 250));
    await settleFor(tester, 2);
    expect(find.text('No results for “zz”'), findsOneWidget);
    expect(
      find.text(
        'Only the first 300 stories in this room are searched. Try narrowing by age or language.',
      ),
      findsOneWidget,
    );
    expect(device.shelfQueries.map((q) => q.page), [1, 2, 3]);
  });

  testWidgets('Back deletes a letter, then leaves once the query is empty', (
    tester,
  ) async {
    await pumpGuestApp(tester, device, at: '/search');
    await _type(tester, 'm');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Search stories…'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleFor(tester);
    expect(find.text('Read now'), findsOneWidget);
  });
}
