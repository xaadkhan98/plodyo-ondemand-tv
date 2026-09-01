import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/views/sign_in_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/search/views/search_view.dart';

void main() {
  group('Physical Keyboard Input Tests', () {
    testWidgets('SignInView captures physical keyboard typing, Tab, and Enter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignInView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type email "admin" via physical key events
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD, character: 'd');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'm');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI, character: 'i');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN, character: 'n');
      await tester.pump();

      expect(find.text('admin'), findsOneWidget);

      // Press Tab to switch to password field
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Type password "pass"
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP, character: 'p');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS, character: 's');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS, character: 's');
      await tester.pump();

      // 4 characters for password renders as 4 dots
      expect(find.text('••••'), findsOneWidget);

      // Press Backspace
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(find.text('•••'), findsOneWidget);
    });

    testWidgets('SearchView captures physical keyboard typing and clear', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchView(onMediaSelected: (_) {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type search query "Neon"
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN, character: 'n');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: 'e');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyO, character: 'o');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN, character: 'n');
      await tester.pump();

      expect(find.text('neon'), findsOneWidget);

      // Press Escape to clear
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Search stories...'), findsOneWidget);
    });
  });
}
