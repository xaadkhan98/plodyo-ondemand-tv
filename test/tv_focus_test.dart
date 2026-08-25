import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/widgets/tv_focusable.dart';
import 'package:plodyo_ondemand_tv/core/widgets/tv_row.dart';
import 'package:plodyo_ondemand_tv/data/models/media_item.dart';

void main() {
  group('TV Focus & Remote Control Navigation Tests', () {
    testWidgets('TvFocusable responds to Enter / Select D-pad key events', (tester) async {
      bool actionTriggered = false;
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TvFocusable(
                focusNode: focusNode,
                autofocus: true,
                onPressed: () {
                  actionTriggered = true;
                },
                child: const Text('Focus Target'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      // Simulate remote D-Pad Select key press
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(actionTriggered, isTrue);

      // Simulate Enter key press
      actionTriggered = false;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(actionTriggered, isTrue);

      focusNode.dispose();
    });

    testWidgets('TvRow renders multiple focusable cards', (tester) async {
      final items = [
        const MediaItem(
          id: '1',
          title: 'Movie One',
          category: 'Action',
          posterUrl: 'https://example.com/1.jpg',
          backdropUrl: 'https://example.com/1_b.jpg',
          rating: 8.0,
          duration: '2h',
          releaseYear: 2024,
          description: 'Desc 1',
        ),
        const MediaItem(
          id: '2',
          title: 'Movie Two',
          category: 'Drama',
          posterUrl: 'https://example.com/2.jpg',
          backdropUrl: 'https://example.com/2_b.jpg',
          rating: 7.5,
          duration: '1h 30m',
          releaseYear: 2025,
          description: 'Desc 2',
        ),
      ];

      MediaItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvRow(
              title: 'Test Row',
              items: items,
              onItemTap: (item) {
                selectedItem = item;
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Row'), findsOneWidget);
      expect(find.text('Movie One'), findsOneWidget);
      expect(find.text('Movie Two'), findsOneWidget);

      await tester.tap(find.text('Movie One'));
      await tester.pump();
      expect(selectedItem?.id, '1');
    });
  });
}
