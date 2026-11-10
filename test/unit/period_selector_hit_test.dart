import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';

void main() {
  group('PeriodSelector Arrow vs Calendar Hit-Testing Tests', () {
    testWidgets('Tapping left arrow anywhere on its 48x44 bounds always invokes onPrevious and never onTapDate', (tester) async {
      int previousCount = 0;
      int nextCount = 0;
      int datePickerCount = 0;
      int todayCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: PeriodSelector(
                selectedPeriod: TimePeriod.day,
                onPeriodChanged: (_) {},
                dateRangeLabel: '28 October 2026 (Wednesday)',
                onPrevious: () => previousCount++,
                onNext: () => nextCount++,
                onTapDate: () => datePickerCount++,
                onToday: () => todayCount++,
                canJumpToToday: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final previousFinder = find.byKey(const ValueKey('period_selector_previous_button'));
      expect(previousFinder, findsOneWidget);

      // Tap left arrow 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(previousFinder);
        await tester.pump();
      }

      expect(previousCount, 5, reason: 'Previous button should be invoked exactly 5 times');
      expect(datePickerCount, 0, reason: 'Date picker must NEVER be triggered when tapping the left arrow');
      expect(nextCount, 0);
      expect(todayCount, 0);

      // Tap the date text
      final dateFinder = find.byKey(const ValueKey('period_selector_date_picker_button'));
      expect(dateFinder, findsOneWidget);
      await tester.tap(dateFinder);
      await tester.pump();

      expect(datePickerCount, 1, reason: 'Tapping date text triggers date picker');
      expect(previousCount, 5);

      // Tap the next button
      final nextFinder = find.byKey(const ValueKey('period_selector_next_button'));
      expect(nextFinder, findsOneWidget);
      await tester.tap(nextFinder);
      await tester.pump();

      expect(nextCount, 1);
      expect(previousCount, 5);
      expect(datePickerCount, 1);

      // Tap the jump to current period button
      final jumpFinder = find.byKey(const ValueKey('period_selector_jump_current_button'));
      expect(jumpFinder, findsOneWidget);
      await tester.tap(jumpFinder);
      await tester.pump();

      expect(todayCount, 1);
    });

    testWidgets('Narrow screen width (320px) retains isolated, non-overlapping tap targets', (tester) async {
      int previousCount = 0;
      int datePickerCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320, // very narrow device
              child: PeriodSelector(
                selectedPeriod: TimePeriod.week,
                onPeriodChanged: (_) {},
                dateRangeLabel: '19 Oct – 25 Oct 2026',
                onPrevious: () => previousCount++,
                onNext: () {},
                onTapDate: () => datePickerCount++,
                onToday: () {},
                canJumpToToday: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap left arrow
      await tester.tap(find.byKey(const ValueKey('period_selector_previous_button')));
      await tester.pump();

      expect(previousCount, 1);
      expect(datePickerCount, 0);

      // Tap right arrow
      await tester.tap(find.byKey(const ValueKey('period_selector_next_button')));
      await tester.pump();
      expect(previousCount, 1);
      expect(datePickerCount, 0);

      // Tap date
      await tester.tap(find.byKey(const ValueKey('period_selector_date_picker_button')));
      await tester.pump();
      expect(datePickerCount, 1);
    });
  });
}
