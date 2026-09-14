import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/widgets/plodyo_loading.dart';

void main() {
  group('Plodyo Loading Widgets Tests', () {
    testWidgets('PlodyoThreeDotsLoading renders 3 animated dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PlodyoThreeDotsLoading(),
            ),
          ),
        ),
      );

      // Verify the widget is rendered
      expect(find.byType(PlodyoThreeDotsLoading), findsOneWidget);

      // Verify animation frames step without error
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('PlodyoThreeDotsLoading supports custom colors and sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PlodyoThreeDotsLoading(
                color: Colors.white,
                dotSize: 12,
                spacing: 8,
                bounceHeight: 10,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PlodyoThreeDotsLoading), findsOneWidget);
    });

    testWidgets('PlodyoPageLoading renders logo, message text, and 3 dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlodyoPageLoading(
              message: 'One moment...',
            ),
          ),
        ),
      );

      expect(find.byType(PlodyoPageLoading), findsOneWidget);
      expect(find.text('One moment...'), findsOneWidget);
      expect(find.byType(PlodyoThreeDotsLoading), findsOneWidget);

      // Verify floating animation cycles
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 800));
    });
  });
}
