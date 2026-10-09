import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/guest_harness.dart';

void main() {
  late FakeDevice device;

  setUp(() => device = FakeDevice());

  testWidgets(
    'the blue button opens This TV: the language first, then the ids support asks for',
    (tester) async {
      await pumpGuestApp(tester, device);

      // The simulator needs a physical key; the shortcut reads the logical one Android sends for blue.
      await tester.sendKeyEvent(
        LogicalKeyboardKey.colorF3Blue,
        physicalKey: PhysicalKeyboardKey.f13,
      );
      await settleFor(tester);

      expect(find.text('This TV'), findsOneWidget);
      expect(find.text('English (room default)'), findsOneWidget);
      expect(find.text('r1'), findsOneWidget);
      expect(find.text('s1'), findsOneWidget);
      // The picker is the first control, so it takes the ring.
      expect(hasFocus(tester, 'As set for this room (English)'), isTrue);
    },
  );

  testWidgets(
    'unpairing takes OK held for three seconds, and letting go early keeps the TV paired',
    (tester) async {
      await pumpGuestApp(tester, device, at: '/room');

      await tester.ensureVisible(find.text('Unpair this TV'));
      await tester.tap(find.text('Unpair this TV'));
      await tester.pump();
      expect(hasFocus(tester, 'Hold OK for 3 seconds'), isTrue);

      // A press is not a hold.
      // A pump to start the fill's ticker, then the time held.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Keep holding…'), findsOneWidget);
      // One chime for Unpair, one as the hold starts, none for the remote's key repeats.
      expect(chimes, 2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump(const Duration(seconds: 3));
      expect(device.isPaired, isTrue);
      expect(find.text('Hold OK for 3 seconds'), findsOneWidget);

      // Done on the first frame past three seconds.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await settleFor(tester);
      expect(device.isPaired, isFalse);
      expect(find.text('Set up this TV'), findsOneWidget);
    },
  );

  testWidgets('cancelling hands the ring back to the unpair button', (
    tester,
  ) async {
    await pumpGuestApp(tester, device, at: '/room');

    await tester.ensureVisible(find.text('Unpair this TV'));
    await tester.tap(find.text('Unpair this TV'));
    await tester.pump();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Hold OK for 3 seconds'), findsNothing);
    expect(hasFocus(tester, 'Unpair this TV'), isTrue);
  });
}
