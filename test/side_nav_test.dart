import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plodyo_ondemand_tv/core/widgets/side_nav.dart';
import 'package:plodyo_ondemand_tv/core/widgets/tv_button.dart';

void main() {
  // The screen sits in its own Navigator, as under go_router's ShellRoute: its own focus scope.
  Widget shell() => MaterialApp(
    home: Material(
      child: SideNav(
        currentPath: '/b',
        items: const [
          NavItem(path: '/a', label: 'A', icon: LucideIcons.house),
          NavItem(path: '/b', label: 'B', icon: LucideIcons.mail),
        ],
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => Padding(
              padding: const EdgeInsets.only(left: 200, top: 100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvButton(label: 'First', autofocus: true, onSelect: () {}),
                  TvButton(label: 'Second', onSelect: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  String focusedLabel(WidgetTester tester) {
    final context = FocusManager.instance.primaryFocus!.context!;
    final text = find.descendant(
      of: find.byWidget(context.widget),
      matching: find.byType(Text),
    );
    return tester.widget<Text>(text.first).data!;
  }

  testWidgets('Left crosses from the screen into the rail, Right returns', (
    tester,
  ) async {
    await tester.pumpWidget(shell());
    await tester.pump();
    expect(focusedLabel(tester), 'First');

    // Within the screen first: Left from Second lands on First, not the rail.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusedLabel(tester), 'Second');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(focusedLabel(tester), 'First');

    // Nothing further left on the screen: into the rail, at the tile nearest in height.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(focusedLabel(tester), anyOf('A', 'B'));

    // Up and down stay inside the rail, stopping at its ends.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(focusedLabel(tester), 'A');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focusedLabel(tester), 'B');

    // Right goes back to where the screen left off.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusedLabel(tester), 'First');
  });
}
