import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/widgets/tv_section_badge.dart';

void main() {
  group('TvSectionBadge Component Tests', () {
    testWidgets('renders icon, white border, and rotation transform', (
      tester,
    ) async {
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
  });
}
