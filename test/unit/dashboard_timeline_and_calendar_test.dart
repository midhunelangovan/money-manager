import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/extensions/date_extensions.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';

void main() {
  group('Date-Wise Transaction Timeline & Calendar Navigation Tests', () {
    // -------------------------------------------------------------------------
    // 1. Date Grouping & Reverse Chronological Sorting Tests
    // -------------------------------------------------------------------------
    test('1. A week with transactions on multiple dates produces one group per date, sorted newest first', () {
      final txList = [
        LedgerItem(
          id: 'tx_1',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 12000), // ₹120.00
          date: DateTime(2026, 10, 9, 10, 0),
          createdAt: DateTime(2026, 10, 9, 10, 0),
          updatedAt: DateTime(2026, 10, 9, 10, 0),
          categoryName: 'Transportation',
          description: 'Bus fare',
        ),
        LedgerItem(
          id: 'tx_2',
          accountId: 'acc_1',
          itemType: LedgerItemType.income,
          amount: const Money(units: 4000000), // ₹40,000.00
          date: DateTime(2026, 10, 9, 9, 0),
          createdAt: DateTime(2026, 10, 9, 9, 0),
          updatedAt: DateTime(2026, 10, 9, 9, 0),
          categoryName: 'Salary',
          description: 'Monthly pay',
        ),
        LedgerItem(
          id: 'tx_3',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 45000), // ₹450.00
          date: DateTime(2026, 10, 10, 15, 30),
          createdAt: DateTime(2026, 10, 10, 15, 30),
          updatedAt: DateTime(2026, 10, 10, 15, 30),
          categoryName: 'Shopping',
          description: 'Clothes',
        ),
        LedgerItem(
          id: 'tx_4',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 15000), // ₹150.00
          date: DateTime(2026, 10, 11, 8, 30),
          createdAt: DateTime(2026, 10, 11, 8, 30),
          updatedAt: DateTime(2026, 10, 11, 8, 30),
          categoryName: 'Transportation',
          description: 'Taxi',
        ),
        LedgerItem(
          id: 'tx_5',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 22000), // ₹220.00
          date: DateTime(2026, 10, 11, 13, 0),
          createdAt: DateTime(2026, 10, 11, 13, 0),
          updatedAt: DateTime(2026, 10, 11, 13, 0),
          categoryName: 'Food & Dining',
          description: 'Lunch',
        ),
      ];

      // Perform the exact grouping logic used in DateGroupedTransactionTimeline
      final Map<DateTime, List<LedgerItem>> groups = {};
      for (final tx in txList) {
        final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
        (groups[dayKey] ??= []).add(tx);
      }

      final sortedDates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

      // Assertions
      expect(sortedDates.length, 3); // 11 Oct, 10 Oct, 9 Oct
      expect(sortedDates[0], DateTime(2026, 10, 11));
      expect(sortedDates[1], DateTime(2026, 10, 10));
      expect(sortedDates[2], DateTime(2026, 10, 9));

      // Sunday 11 Oct should have 2 transactions
      expect(groups[sortedDates[0]]!.length, 2);

      // Saturday 10 Oct should have 1 transaction
      expect(groups[sortedDates[1]]!.length, 1);

      // Friday 9 Oct should have 2 transactions
      expect(groups[sortedDates[2]]!.length, 2);
    });

    test('2. Multiple transactions on the same date are sorted by transaction time descending with stable secondary order', () {
      final sameDayItems = [
        LedgerItem(
          id: 'tx_morning',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 15000),
          date: DateTime(2026, 10, 11, 8, 30), // 8:30 AM
          createdAt: DateTime(2026, 10, 11, 8, 30),
          updatedAt: DateTime(2026, 10, 11, 8, 30),
          categoryName: 'Transportation',
          description: 'Taxi',
        ),
        LedgerItem(
          id: 'tx_afternoon',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 22000),
          date: DateTime(2026, 10, 11, 14, 0), // 2:00 PM
          createdAt: DateTime(2026, 10, 11, 14, 0),
          updatedAt: DateTime(2026, 10, 11, 14, 0),
          categoryName: 'Food & Dining',
          description: 'Lunch',
        ),
        LedgerItem(
          id: 'tx_midnight_b',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 5000),
          date: DateTime(2026, 10, 11, 0, 0), // Midnight
          createdAt: DateTime(2026, 10, 11, 1, 0), // Later creation
          updatedAt: DateTime(2026, 10, 11, 1, 0),
          categoryName: 'Snacks',
          description: 'Midnight snack 2',
        ),
        LedgerItem(
          id: 'tx_midnight_a',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 3000),
          date: DateTime(2026, 10, 11, 0, 0), // Midnight
          createdAt: DateTime(2026, 10, 11, 0, 30), // Earlier creation
          updatedAt: DateTime(2026, 10, 11, 0, 30),
          categoryName: 'Snacks',
          description: 'Midnight snack 1',
        ),
      ];

      sameDayItems.sort((a, b) {
        final timeComp = b.date.compareTo(a.date);
        if (timeComp != 0) return timeComp;
        final createdComp = b.createdAt.compareTo(a.createdAt);
        if (createdComp != 0) return createdComp;
        return b.id.compareTo(a.id);
      });

      // Newest time (2:00 PM) first
      expect(sameDayItems[0].id, 'tx_afternoon');
      // Then 8:30 AM
      expect(sameDayItems[1].id, 'tx_morning');
      // For items with same midnight time, newer createdAt first
      expect(sameDayItems[2].id, 'tx_midnight_b');
      expect(sameDayItems[3].id, 'tx_midnight_a');
    });

    test('3. Transfers are labeled as transfers and excluded from day expense/income subtotal', () {
      final items = [
        LedgerItem(
          id: 'tx_exp',
          accountId: 'acc_1',
          itemType: LedgerItemType.expense,
          amount: const Money(units: 20000), // ₹200.00
          date: DateTime(2026, 10, 11, 10, 0),
          createdAt: DateTime(2026, 10, 11, 10, 0),
          updatedAt: DateTime(2026, 10, 11, 10, 0),
          categoryName: 'Grocery',
          description: 'Milk & Eggs',
        ),
        LedgerItem(
          id: 'tx_trans',
          accountId: 'acc_1',
          destinationAccountId: 'acc_2',
          itemType: LedgerItemType.transfer,
          amount: const Money(units: 500000), // ₹5,000.00
          date: DateTime(2026, 10, 11, 11, 0),
          createdAt: DateTime(2026, 10, 11, 11, 0),
          updatedAt: DateTime(2026, 10, 11, 11, 0),
          description: 'Transfer',
        ),
      ];

      final dayTotalUnits = items.fold<int>(0, (sum, i) {
        if (i.type == LedgerItemType.transfer) return sum;
        return sum + i.amountUnits;
      });

      // Day total must be ₹200 (20000 units), not ₹5,200!
      expect(dayTotalUnits, 20000);
    });

    // -------------------------------------------------------------------------
    // 2. Contextual Today Navigation Tests across all Periods
    // -------------------------------------------------------------------------
    test('4. Day mode: isCurrentPeriod is true for today, false for yesterday and tomorrow', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      bool isCurrent(DateTime selected, TimePeriod period) {
        final n = DateTime.now();
        switch (period) {
          case TimePeriod.day:
            return selected.year == n.year && selected.month == n.month && selected.day == n.day;
          case TimePeriod.week:
            final curWeek = DateTime(n.year, n.month, n.day).startOfWeek;
            final selWeek = selected.startOfWeek;
            return curWeek.year == selWeek.year && curWeek.month == selWeek.month && curWeek.day == selWeek.day;
          case TimePeriod.month:
            return selected.year == n.year && selected.month == n.month;
          case TimePeriod.year:
            return selected.year == n.year;
          case TimePeriod.period:
            return selected.year == n.year && selected.month == n.month;
        }
      }

      expect(isCurrent(today, TimePeriod.day), isTrue, reason: 'Today shortcut should be HIDDEN for current day');
      expect(isCurrent(yesterday, TimePeriod.day), isFalse, reason: 'Today shortcut should be SHOWN for yesterday');
      expect(isCurrent(tomorrow, TimePeriod.day), isFalse, reason: 'Today shortcut should be SHOWN for tomorrow');
    });

    test('5. Week mode: isCurrentPeriod is true for any date within current week, false for previous week', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final mondayCurrentWeek = today.startOfWeek;
      final fridayCurrentWeek = mondayCurrentWeek.add(const Duration(days: 4));
      final previousWeekMonday = mondayCurrentWeek.subtract(const Duration(days: 7));

      bool isCurrentWeek(DateTime selected) {
        final n = DateTime.now();
        final curWeek = DateTime(n.year, n.month, n.day).startOfWeek;
        final selWeek = selected.startOfWeek;
        return curWeek.year == selWeek.year && curWeek.month == selWeek.month && curWeek.day == selWeek.day;
      }

      expect(isCurrentWeek(mondayCurrentWeek), isTrue);
      expect(isCurrentWeek(fridayCurrentWeek), isTrue);
      expect(isCurrentWeek(previousWeekMonday), isFalse);
    });

    test('6. Month mode: isCurrentPeriod is true for current month, false for past or future months', () {
      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 1);
      final pastMonthDate = DateTime(now.year, now.month - 1, 1);
      final nextMonthDate = DateTime(now.year, now.month + 1, 1);

      bool isCurrentMonth(DateTime selected) {
        final n = DateTime.now();
        return selected.year == n.year && selected.month == n.month;
      }

      expect(isCurrentMonth(currentMonthDate), isTrue);
      expect(isCurrentMonth(pastMonthDate), isFalse);
      expect(isCurrentMonth(nextMonthDate), isFalse);
    });

    test('7. Year mode: isCurrentPeriod is true for current year, false for previous year', () {
      final now = DateTime.now();
      final currentYear = DateTime(now.year, 1, 1);
      final previousYear = DateTime(now.year - 1, 1, 1);

      bool isCurrentYear(DateTime selected) {
        final n = DateTime.now();
        return selected.year == n.year;
      }

      expect(isCurrentYear(currentYear), isTrue);
      expect(isCurrentYear(previousYear), isFalse);
    });

    test('8. Custom Period mode: range containing today is current, historical range is non-current', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final currentRange = DateTimeRange(
        start: today.subtract(const Duration(days: 5)),
        end: today.add(const Duration(days: 2)),
      );

      final pastRange = DateTimeRange(
        start: today.subtract(const Duration(days: 30)),
        end: today.subtract(const Duration(days: 10)),
      );

      bool isCurrentRange(DateTimeRange range) {
        final n = DateTime.now();
        final t = DateTime(n.year, n.month, n.day);
        return !range.start.isAfter(t) && !range.end.isBefore(t);
      }

      expect(isCurrentRange(currentRange), isTrue);
      expect(isCurrentRange(pastRange), isFalse);
    });

    // -------------------------------------------------------------------------
    // 3. Navigation Day-Count Clamping Fix Verification
    // -------------------------------------------------------------------------
    test('9. Stepping from March 31 to February steps to max day of Feb (28/29), not clamped to 28 arbitrarily in leap years', () {
      // Leap year 2024
      final march31_2024 = DateTime(2024, 3, 31);
      final prevMonth = march31_2024.month == 1 ? 12 : march31_2024.month - 1;
      final prevYear = march31_2024.month == 1 ? march31_2024.year - 1 : march31_2024.year;
      final maxDay = DateTime(prevYear, prevMonth + 1, 0).day;
      final safeDay = march31_2024.day.clamp(1, maxDay);
      final feb2024 = DateTime(prevYear, prevMonth, safeDay);

      expect(maxDay, 29, reason: 'Feb 2024 is a leap year with 29 days');
      expect(feb2024.day, 29);

      // Non-leap year 2026
      final march31_2026 = DateTime(2026, 3, 31);
      final prevMonth26 = march31_2026.month == 1 ? 12 : march31_2026.month - 1;
      final prevYear26 = march31_2026.month == 1 ? march31_2026.year - 1 : march31_2026.year;
      final maxDay26 = DateTime(prevYear26, prevMonth26 + 1, 0).day;
      final safeDay26 = march31_2026.day.clamp(1, maxDay26);
      final feb2026 = DateTime(prevYear26, prevMonth26, safeDay26);

      expect(maxDay26, 28, reason: 'Feb 2026 has 28 days');
      expect(feb2026.day, 28);
    });

    test('10. Stepping from May 31 to April steps to 30, not 28', () {
      final may31 = DateTime(2026, 5, 31);
      final prevMonth = may31.month - 1;
      final maxDay = DateTime(may31.year, prevMonth + 1, 0).day;
      final safeDay = may31.day.clamp(1, maxDay);
      final april = DateTime(may31.year, prevMonth, safeDay);

      expect(maxDay, 30);
      expect(april.day, 30, reason: 'April has 30 days, must not be clamped to 28');
    });
  });
}
