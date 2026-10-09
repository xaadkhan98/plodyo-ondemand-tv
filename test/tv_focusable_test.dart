import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_scale.dart';
import 'package:plodyo_ondemand_tv/core/widgets/tv_focusable.dart';

void main() {
  // iOS stands in for Apple TV, whose bouncing lists would overshoot an unclamped reveal.
  testWidgets(
    'a D-pad move reveals the target with room for its ring, and never past the end',
    (tester) async {
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final scroll = ScrollController();
      var furthest = 0.0;
      scroll.addListener(
        () => furthest = scroll.offset > furthest ? scroll.offset : furthest,
      );

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TvCanvas(child: child!),
          home: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                for (var i = 0; i < 10; i++)
                  TvFocusable(
                    autofocus: i == 0,
                    builder: (_, _) => const SizedBox(height: 100),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      Future<void> down(int times) async {
        for (var i = 0; i < times; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      // The sixth box ends at 600: the viewport's 540 plus a rem of margin.
      await down(5);
      expect(scroll.offset, 600 + rem - 540);

      // The last box ends the list: its margin would need 470, the list stops at 460.
      await down(4);
      expect(scroll.offset, 460);
      expect(furthest, 460);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
