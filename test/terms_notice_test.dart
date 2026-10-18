import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/constants/api_constants.dart';
import 'package:plodyo_ondemand_tv/core/constants/legal.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_scale.dart';
import 'package:plodyo_ondemand_tv/core/widgets/tv_button.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';
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

      // An Android TV remote's OK is select; Enter is pressed by every other test's harness.
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
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

  for (final (name, size, dpr) in tvScreens.take(3)) {
    testWidgets(
      'fits one screen on a $name, Continue focused inside the overscan margin',
      (tester) async {
        await pumpGuestApp(
          tester,
          device,
          size: size,
          dpr: dpr,
          acceptTerms: false,
        );

        final notice = find.byType(TermsNoticeView);
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: notice, matching: find.byType(Scrollable)),
        );
        expect(scroll.position.maxScrollExtent, 0);
        final screen = tester.getRect(notice);
        final scale = screen.width / TvCanvas.designWidth;
        final safe = Rect.fromLTRB(
          screen.left + TvInsets.safeX * scale,
          screen.top + TvInsets.safeY * scale,
          screen.right - TvInsets.safeX * scale,
          screen.bottom - TvInsets.safeY * scale,
        );
        final button = tester.getRect(
          find.widgetWithText(TvButton, 'Continue'),
        );
        expect(safe.expandToInclude(button), safe);
        expect(hasFocus(tester, 'Continue'), isTrue);
      },
    );
  }

  testWidgets(
    'Back or Escape on the notice leaves the app; the film behind it never opens',
    (tester) async {
      final exits = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'SystemNavigator.pop'
            ? exits.add(call.method)
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      device.stories['film'] = const StoryDetail(
        story: Story(id: 'film', title: 'Moon Picnic'),
        mediaUrl: 'https://cdn.example/moon.mp4',
      );
      final media = <FakeMedia>[];
      await pumpGuestApp(
        tester,
        device,
        at: '/story?id=film',
        media: media,
        acceptTerms: false,
      );

      // Android hands an Escape the app leaves alone back as Back, which arrives as a route pop.
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isFalse);
      await tester.binding.handlePopRoute();
      await settleFor(tester);

      expect(exits, ['SystemNavigator.pop']);
      expect(find.byType(TermsNoticeView), findsOneWidget);
      expect(media, isEmpty);
    },
  );

  testWidgets('Terms of Service in the rail shows the same code, address and date', (
    tester,
  ) async {
    await pumpGuestApp(tester, device, at: '/terms');

    expect(find.text('Terms of Service'), findsWidgets);
    expect(find.text('Terms & Privacy'), findsNothing);
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
