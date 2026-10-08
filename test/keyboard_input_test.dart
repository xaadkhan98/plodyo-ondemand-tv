import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/views/sign_in_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/search/views/search_view.dart';

void main() {
  group('Physical Keyboard Input Tests', () {
    testWidgets('SignInView: typing, D-pad into TvKeyboard, and down to Forgot password', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var forgotPressed = false;
      await tester.pumpWidget(
        MaterialApp(home: SignInView(onForgotPassword: () => forgotPressed = true)),
      );
      await tester.pumpAndSettle();

      // Physical typing + backspace go to the autofocused email field.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD, character: 'd');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'm');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(find.text('ad'), findsOneWidget);

      // OK on the field jumps into the keyboard; OK there types a key.
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(find.textContaining(RegExp(r'^ad.$')), findsOneWidget);

      // Down stays inside the keyboard (used to yank focus back to the form).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(find.textContaining(RegExp(r'^ad..$')), findsOneWidget);

      // Email -> Password -> Sign in -> Forgot password (used to get stuck on Sign in).
      await tester.tap(find.text('Email'));
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(forgotPressed, isTrue);
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
