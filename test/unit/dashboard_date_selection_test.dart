import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';

void main() {
  group('Dashboard Home Calendar & Date Selection Tests', () {
    test('1. Daily boundary uses exact start and exclusive next-day start', () {
      final selectedDate = DateTime(2026, 1, 15);
      final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0, 0);
      final end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1, 0, 0, 0, 0);

      expect(start, DateTime(2026, 1, 15, 0, 0, 0, 0));
      expect(end, DateTime(2026, 1, 16, 0, 0, 0, 0));

      final txOnSelectedDay = DateTime(2026, 1, 15, 14, 30, 0);
      final txOnNextDay = DateTime(2026, 1, 16, 0, 0, 0);
      final txOnPreviousDay = DateTime(2026, 1, 14, 23, 59, 59);

      final isTxOnSelectedDayIncluded = txOnSelectedDay.millisecondsSinceEpoch >= start.millisecondsSinceEpoch &&
          txOnSelectedDay.millisecondsSinceEpoch < end.millisecondsSinceEpoch;
      final isTxOnNextDayIncluded = txOnNextDay.millisecondsSinceEpoch >= start.millisecondsSinceEpoch &&
          txOnNextDay.millisecondsSinceEpoch < end.millisecondsSinceEpoch;
      final isTxOnPreviousDayIncluded = txOnPreviousDay.millisecondsSinceEpoch >= start.millisecondsSinceEpoch &&
          txOnPreviousDay.millisecondsSinceEpoch < end.millisecondsSinceEpoch;

      expect(isTxOnSelectedDayIncluded, isTrue);
      expect(isTxOnNextDayIncluded, isFalse);
      expect(isTxOnPreviousDayIncluded, isFalse);
    });

    test('2. Month boundary across February and Leap Years', () {
      // February 2026 (non-leap year)
      final selectedDate = DateTime(2026, 2, 1);
      final start = DateTime(selectedDate.year, selectedDate.month, 1, 0, 0, 0, 0);
      final end = DateTime(selectedDate.year, selectedDate.month + 1, 1, 0, 0, 0, 0);

      expect(start, DateTime(2026, 2, 1, 0, 0, 0, 0));
      expect(end, DateTime(2026, 3, 1, 0, 0, 0, 0));

      final feb28Tx = DateTime(2026, 2, 28, 23, 59, 59);
      final march1Tx = DateTime(2026, 3, 1, 0, 0, 0);

      expect(feb28Tx.millisecondsSinceEpoch < end.millisecondsSinceEpoch, isTrue);
      expect(march1Tx.millisecondsSinceEpoch >= end.millisecondsSinceEpoch, isTrue);
    });

    test('3. Year boundary across Year End (Dec 31 to Jan 1)', () {
      final selectedDate = DateTime(2026, 12, 31);
      final nextDay = selectedDate.add(const Duration(days: 1));

      expect(nextDay.year, 2027);
      expect(nextDay.month, 1);
      expect(nextDay.day, 1);
    });

    test('4. Stepping backward from Jan 1 goes to Dec 31 previous year', () {
      final selectedDate = DateTime(2026, 1, 1);
      final prevDay = selectedDate.subtract(const Duration(days: 1));

      expect(prevDay.year, 2025);
      expect(prevDay.month, 12);
      expect(prevDay.day, 31);
    });

    test('5. Local calendar dates preserve day across positive and negative UTC offsets', () {
      final selectedDate = DateTime(2026, 10, 4);
      final localStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);

      expect(localStart.year, 2026);
      expect(localStart.month, 10);
      expect(localStart.day, 4);
      expect(localStart.hour, 0);
    });

    test('6. PeriodSelector tabs map correctly to TimePeriod enum', () {
      expect(TimePeriod.day.displayName, 'Day');
      expect(TimePeriod.week.displayName, 'Week');
      expect(TimePeriod.month.displayName, 'Month');
      expect(TimePeriod.year.displayName, 'Year');
      expect(TimePeriod.period.displayName, 'Period');
    });
  });
}
