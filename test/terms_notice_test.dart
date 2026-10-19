import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/constants/api_constants.dart';
import 'package:plodyo_ondemand_tv/core/constants/legal.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_scale.dart';
import 'package:plodyo_ondemand_tv/core/widgets/tv_button.dart';
import 'package:plodyo_ondemand_tv/data/models/device_models.dart';
import 'package:plodyo_ondemand_tv/data/models/story_models.dart';
import 'package:plodyo_ondemand_tv/core/widgets/legal_qr.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/device_controller.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/terms_notice_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/terms_view.dart';

import 'support/guest_harness.dart';

// Made-up wording: only that it switches matters here.
const spanish = TermsNotice(
  language: 'SPA',
  locale: 'es',
  notice: 'Aviso en español',
  dateLine: 'Vigentes desde el 25 de octubre de 2026',
  menuItem: 'Condiciones del servicio',
  continueLabel: 'Continuar',
);

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
      expect(
        tester
            .getRect(
              find.descendant(
                of: find.byType(LegalQr),
                matching: find.byType(SvgPicture),
              ),
            )
            .height,
        closeTo(1080 / 3, 0.5),
      );
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

  testWidgets(
    "shows the room's language when it is approved, right to left for Arabic, and logs it",
    (tester) async {
      device
        ..defaultLanguage = 'ARA'
        ..termsNotices = [arabic];
      await pumpGuestApp(tester, device, acceptTerms: false);

      final text = find.text(arabic.notice);
      expect(text, findsOneWidget);
      expect(Directionality.of(tester.element(text)), TextDirection.rtl);
      expect(tester.widget<Text>(text).locale, const Locale('ar'));
      expect(find.text(arabic.dateLine!), findsOneWidget);
      expect(find.text(legalAddress), findsOneWidget);
      expect(hasFocus(tester, 'متابعة'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump(const Duration(minutes: 1));
      await settleFor(tester);
      expect(device.notices.map((notice) => notice['language']), [
        'ARA',
        'ARA',
      ]);
    },
  );

  testWidgets(
    'beside Continue, a guest can read it in another language: shown is logged once, accepted in the pick, which carries on',
    (tester) async {
      device.termsNotices = [spanish];
      await pumpGuestApp(tester, device, acceptTerms: false);
      expect(hasFocus(tester, 'Continue'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(hasFocus(tester, 'English'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Pick a language'), findsOneWidget);
      await tester.tap(find.text('Spanish'));
      await settleFor(tester);

      expect(find.text(spanish.notice), findsOneWidget);
      await tester.tap(find.text(spanish.continueLabel));
      await tester.pump(const Duration(minutes: 1));
      await settleFor(tester);

      expect(find.byType(TermsNoticeView), findsNothing);
      expect(
        device.notices.map((notice) => [notice['event'], notice['language']]),
        [
          ['notice_shown', 'ENG'],
          ['notice_accepted', 'SPA'],
        ],
      );
      expect(device.storyQueries.last, 'SPA');
    },
  );

  testWidgets(
    "Back in the notice's language picker closes it, and the notice stays up",
    (tester) async {
      final exits = recordExits(tester);
      await pumpGuestApp(tester, device, acceptTerms: false);
      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Pick a language'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settleFor(tester);

      expect(find.text('Pick a language'), findsNothing);
      expect(find.byType(TermsNoticeView), findsOneWidget);
      expect(exits, isEmpty);
    },
  );

  testWidgets(
    "falls back to English when the room's language has no approved translation",
    (tester) async {
      device
        ..defaultLanguage = 'SPA'
        ..termsNotices = [arabic];
      await pumpGuestApp(tester, device, acceptTerms: false);

      final text = find.text(termsNoticeText);
      expect(text, findsOneWidget);
      expect(Directionality.of(tester.element(text)), TextDirection.ltr);
      expect(hasFocus(tester, 'Continue'), isTrue);
    },
  );

  testWidgets(
    "Terms of Service on the rail and its screen follow the TV's current language, right to left",
    (tester) async {
      device.termsNotices = [arabic];
      await pumpGuestApp(tester, device, at: '/terms');
      expect(find.text('Terms of Service'), findsNWidgets(2));

      DeviceScope.of(
        tester.element(find.byType(TermsView)),
      ).chooseLanguage('ARA');
      await settleFor(tester);

      // The screen's title and the rail's item.
      expect(find.text(arabic.menuItem), findsNWidgets(2));
      expect(find.text(arabic.dateLine!), findsOneWidget);
      final title = find.descendant(
        of: find.byType(TermsView),
        matching: find.text(arabic.menuItem),
      );
      expect(Directionality.of(tester.element(title)), TextDirection.rtl);
    },
  );

  for (final (name, size, dpr) in tvScreens.take(3)) {
    for (final served in [null, french, arabic]) {
      testWidgets(
        'fits one screen on a $name in ${served?.language ?? 'English'}, Continue focused inside the overscan margin',
        (tester) async {
          if (served != null) {
            device
              ..defaultLanguage = served.language
              ..termsNotices = [served];
          }
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
          final label = served?.continueLabel ?? 'Continue';
          final button = tester.getRect(find.widgetWithText(TvButton, label));
          expect(safe.expandToInclude(button), safe);
          expect(hasFocus(tester, label), isTrue);
        },
      );
    }
  }

  testWidgets(
    'Back or Escape on the notice leaves the app; the film behind it never opens',
    (tester) async {
      final exits = recordExits(tester);
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

  testWidgets(
    'Terms of Service in the rail shows the same code, address and date',
    (tester) async {
      await pumpGuestApp(tester, device, at: '/terms');

      expect(find.text('Terms of Service'), findsWidgets);
      expect(find.text('Terms & Privacy'), findsNothing);
      expect(find.byType(LegalQr), findsOneWidget);
      expect(find.text(legalAddress), findsWidgets);
      expect(find.text('Terms effective 25 October 2026'), findsOneWidget);
    },
  );

  test(
    'the code encodes the short address, and the app version tracks pubspec',
    () {
      final svg = File('assets/images/legal_qr.svg').readAsStringSync();
      expect(svg, contains('<title>$legalUrl</title>'));

      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1);
      expect(ApiConstants.appVersion, version);
    },
  );
}
