import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/widgets/bottom_navigation_padding.dart';

void main() {
  group('NavigationPadding Utilities Tests', () {
    testWidgets('NavigationPadding.of returns at least baseClearance + extra', (tester) async {
      double? calculatedPadding;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              calculatedPadding = NavigationPadding.of(context, extra: 20.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Default test MediaQuery has 0 bottom inset, so max(0, 16.0) + 20.0 = 36.0
      expect(calculatedPadding, equals(36.0));
    });

    testWidgets('BottomNavSpacing renders with proper height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BottomNavSpacing(extra: 10.0),
          ),
        ),
      );

      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsOneWidget);

      final SizedBox box = tester.widget(sizedBoxFinder);
      expect(box.height, equals(26.0)); // 16 (min) + 10 (extra)
    });

    testWidgets('NavigationPadding.listInsets correctly applies FAB clearance', (tester) async {
      EdgeInsets? insetsWithFab;
      EdgeInsets? insetsWithoutFab;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              insetsWithFab = NavigationPadding.listInsets(context, hasFab: true);
              insetsWithoutFab = NavigationPadding.listInsets(context, hasFab: false);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(insetsWithFab!.bottom, equals(100.0)); // 16 + 84
      expect(insetsWithoutFab!.bottom, equals(40.0)); // 16 + 24
    });
  });
}
