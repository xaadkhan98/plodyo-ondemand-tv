import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/constants/api_constants.dart';
import 'package:plodyo_ondemand_tv/core/constants/legal.dart';
import 'package:plodyo_ondemand_tv/core/widgets/legal_qr.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/terms_notice_view.dart';

import 'support/guest_harness.dart';

void main() {
  late FakeDevice device;

  setUp(() => device = FakeDevice());

  testWidgets(
    'stands before any content: the wording, the code, the address and the date, with Continue focused',
    (tester) async {
      await pumpGuestApp(tester, device, acceptTerms: false);

      expect(find.text(termsNoticeText), findsOneWidget);
      expect(find.byType(LegalQr), findsOneWidget);
      expect(find.text(legalAddress), findsOneWidget);
      expect(find.text('Terms effective 25 October 2026'), findsOneWidget);
      expect(find.text('Moon Picnic'), findsNothing);
      expect(hasFocus(tester, 'Continue'), isTrue);
      // A third of the screen tall, as drawn: 360 px on a 1080p set.
      expect(tester.getRect(find.byType(SvgPicture)).height, closeTo(1080 / 3, 0.5));
    },
  );

  testWidgets(
    'OK on the remote continues to the catalogue, logging shown and accepted',
    (tester) async {
      await pumpGuestApp(tester, device, acceptTerms: false);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(minutes: 1));
      await settleFor(tester);

      expect(find.byType(TermsNoticeView), findsNothing);
      expect(find.text('Moon Picnic'), findsWidgets);
      expect(device.notices.map((notice) => notice['event']), [
        'notice_shown',
        'notice_accepted',
      ]);
      expect(device.notices.map((notice) => notice['terms_version']).toSet(), {
        '2026-10-25',
      });
    },
  );

  testWidgets('Terms & Privacy in the rail shows the same code, address and date', (
    tester,
  ) async {
    await pumpGuestApp(tester, device, at: '/terms');

    expect(find.text('Terms & Privacy'), findsWidgets);
    expect(find.byType(LegalQr), findsOneWidget);
    expect(find.text(legalAddress), findsWidgets);
    expect(find.text('Terms effective 25 October 2026'), findsOneWidget);
  });

  test('the code encodes the short address, and the app version tracks pubspec', () {
    final svg = File('assets/images/legal_qr.svg').readAsStringSync();
    expect(svg, contains('<title>$legalUrl</title>'));

    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
        .firstMatch(pubspec)!
        .group(1);
    expect(ApiConstants.appVersion, version);
  });
}
