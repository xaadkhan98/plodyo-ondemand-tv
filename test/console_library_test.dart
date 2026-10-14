import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_scale.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_theme.dart';
import 'package:plodyo_ondemand_tv/data/models/actor.dart';
import 'package:plodyo_ondemand_tv/data/models/device_models.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/views/stories_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/home/views/console_overview_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/main_layout.dart';

import 'support/guest_harness.dart';

/// Signed in as a property admin, who may not open partners or invites.
class _PropertyAdmin implements AuthRepository {
  @override
  Actor get currentUser => const Actor(
    userId: 'u1',
    email: 'front.desk@grand.example',
    fullName: 'Front Desk',
    role: 'PROPERTY_ADMIN',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'the console browses the TV library under its own rail, and its picks survive the admin screens',
    (tester) async {
      final device = FakeDevice()..isPaired = false;
      final auth = _PropertyAdmin();
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/stories',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainTvLayout(
              currentPath: state.uri.path,
              authRepository: auth,
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/stories',
                builder: (_, _) => StoriesView(deviceRepository: device),
              ),
              GoRoute(
                path: '/overview',
                builder: (_, _) => ConsoleOverviewView(authRepository: auth),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          theme: TvTheme.light,
          routerConfig: router,
          builder: (context, child) => TvCanvas(child: child!),
        ),
      );
      await settleFor(tester);

      // The catalogue leads the rail; a property admin has no partners or invites.
      for (final label in ['Home', 'Learning', 'Overview', 'Rooms']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Partners'), findsNothing);
      // No language asked for, so the admin lane reads English.
      expect(find.text('English'), findsOneWidget);
      expect(device.storyQueries, everyElement(isNull));

      // Every age is on offer, not one room's.
      await tester.tap(find.text('Filters'));
      await settleFor(tester, 2);
      expect(find.text('Early school'), findsOneWidget);
      await tester.tap(find.text('Preschool'));
      await settleFor(tester);

      router.go('/overview');
      await settleFor(tester);
      expect(find.text('Library'), findsOneWidget);
      router.go('/stories');
      await settleFor(tester);
      expect(device.shelfQueries.last.ageGroup, AgeGroup.preschool);
    },
  );
}
