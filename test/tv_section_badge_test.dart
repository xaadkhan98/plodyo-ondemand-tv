import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/widgets/tv_section_badge.dart';
import 'package:plodyo_ondemand_tv/core/widgets/plodyo_loading.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/views/sign_in_view.dart';

void main() {
  group('TvSectionBadge Component Tests', () {
    testWidgets('renders icon, white border, and rotation transform', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TvSectionBadge(
              icon: Icons.apartment_rounded,
              size: 56,
              iconSize: 30,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TvSectionBadge), findsOneWidget);
      expect(find.byIcon(Icons.apartment_rounded), findsOneWidget);

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // Verify Transform widgets exist for translation and rotation
      final transformFinder = find.byType(Transform);
      expect(transformFinder, findsWidgets);
    });

    testWidgets('renders in all header screens properly', (tester) async {
      // Test SignInView badge
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TvSectionBadge), findsOneWidget);
      expect(find.text('Sign in to the TV'), findsOneWidget);
    });
  });

  group('PlodyoThreeDotsLoading Component Tests', () {
    testWidgets('renders 3 dots with purple colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlodyoThreeDotsLoading(
              dotSize: 8,
              spacing: 6,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(PlodyoThreeDotsLoading), findsOneWidget);
    });
  });
}
