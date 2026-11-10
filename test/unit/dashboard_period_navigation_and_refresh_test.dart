import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';
import 'package:kals_money_manager/core/widgets/transaction_type_tabs.dart';
import 'package:kals_money_manager/features/dashboard/presentation/models/dashboard_filter_state.dart';

void main() {
  group('Home Dashboard Period Navigation and Today Visibility Tests', () {
    final fixedNow = DateTime(2026, 10, 13, 14, 30); // Tuesday 13 October 2026

    test('Bug 1: Day mode isCurrentPeriod logic', () {
      final todayFilter = DashboardFilterState(
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );
      final yesterdayFilter = DashboardFilterState(
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 12),
        tabType: LedgerTabType.expenses,
      );

      // Current local day -> Today button must be hidden (isCurrentPeriod = true)
      expect(todayFilter.isCurrentPeriod(localNow: fixedNow), isTrue);

      // Non-current day -> Today button must be visible (isCurrentPeriod = false)
      expect(yesterdayFilter.isCurrentPeriod(localNow: fixedNow), isFalse);
    });

    test('Bug 1: Week mode isCurrentPeriod logic compares full week start/end', () {
      // 13 Oct 2026 is Tuesday. Week is Mon 12 Oct to Sun 18 Oct.
      final currentWeekFilter = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 14), // Wednesday of current week
        tabType: LedgerTabType.expenses,
      );
      final prevWeekFilter = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 5), // Monday of previous week
        tabType: LedgerTabType.expenses,
      );
      final nextWeekFilter = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 20), // Next week
        tabType: LedgerTabType.expenses,
      );

      // Selected week is current week -> Hide Today
      expect(currentWeekFilter.isCurrentPeriod(localNow: fixedNow), isTrue);

      // Selected week is previous week -> Show Today
      expect(prevWeekFilter.isCurrentPeriod(localNow: fixedNow), isFalse);

      // Selected week is next week -> Show Today
      expect(nextWeekFilter.isCurrentPeriod(localNow: fixedNow), isFalse);
    });

    test('Bug 1: Month mode compares BOTH month and year (not just month name)', () {
      // Current month: October 2026
      final currentMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 10, 1),
        tabType: LedgerTabType.expenses,
      );

      // Even if anchor is a different day in October 2026, it is the current month
      final currentMonthDifferentDay = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 10, 28),
        tabType: LedgerTabType.expenses,
      );

      // October 2025 has same month (10) but DIFFERENT YEAR (2025)
      final historicalOctoberFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2025, 10, 13),
        tabType: LedgerTabType.expenses,
      );

      // September 2026 has same year (2026) but DIFFERENT MONTH (9)
      final previousMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 9, 13),
        tabType: LedgerTabType.expenses,
      );

      // Current month -> Hide Today
      expect(currentMonthFilter.isCurrentPeriod(localNow: fixedNow), isTrue);
      expect(currentMonthDifferentDay.isCurrentPeriod(localNow: fixedNow), isTrue);

      // Historical October (2025) -> Must SHOW Today (isCurrentPeriod = false)
      expect(historicalOctoberFilter.isCurrentPeriod(localNow: fixedNow), isFalse);

      // Previous month (Sept 2026) -> Must SHOW Today (isCurrentPeriod = false)
      expect(previousMonthFilter.isCurrentPeriod(localNow: fixedNow), isFalse);
    });

    test('Bug 1: Year mode isCurrentPeriod logic compares year', () {
      final currentYearFilter = DashboardFilterState(
        periodMode: TimePeriod.year,
        anchorDate: DateTime(2026, 4, 1),
        tabType: LedgerTabType.expenses,
      );
      final lastYearFilter = DashboardFilterState(
        periodMode: TimePeriod.year,
        anchorDate: DateTime(2025, 10, 13),
        tabType: LedgerTabType.expenses,
      );

      // 2026 is current year -> Hide Today
      expect(currentYearFilter.isCurrentPeriod(localNow: fixedNow), isTrue);

      // 2025 is not current year -> Show Today
      expect(lastYearFilter.isCurrentPeriod(localNow: fixedNow), isFalse);
    });

    test('Bug 1: Custom Period mode follows explicit range inclusion', () {
      final rangeWithToday = DashboardFilterState(
        periodMode: TimePeriod.period,
        anchorDate: DateTime(2026, 10, 1),
        customDateRange: DateTimeRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 20),
        ),
        tabType: LedgerTabType.expenses,
      );

      final historicalRange = DashboardFilterState(
        periodMode: TimePeriod.period,
        anchorDate: DateTime(2026, 8, 1),
        customDateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 31),
        ),
        tabType: LedgerTabType.expenses,
      );

      // Contains today -> Hide Today
      expect(rangeWithToday.isCurrentPeriod(localNow: fixedNow), isTrue);

      // Outside today -> Show Today
      expect(historicalRange.isCurrentPeriod(localNow: fixedNow), isFalse);
    });

    test('Bug 1: toCurrentPeriod action resets anchor according to active mode', () {
      final prevMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2025, 4, 15),
        tabType: LedgerTabType.expenses,
      );

      final resetFilter = prevMonthFilter.toCurrentPeriod(localNow: fixedNow);
      expect(resetFilter.anchorDate.year, 2026);
      expect(resetFilter.anchorDate.month, 10);
      expect(resetFilter.isCurrentPeriod(localNow: fixedNow), isTrue);
    });

    test('Bug 2: Period boundaries have inclusive start and exclusive end', () {
      // Month: October 2026
      final monthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );
      expect(monthFilter.startDate, DateTime(2026, 10, 1, 0, 0, 0));
      expect(monthFilter.endDate, DateTime(2026, 11, 1, 0, 0, 0));

      // Week: Mon 12 Oct to Mon 19 Oct
      final weekFilter = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );
      expect(weekFilter.startDate, DateTime(2026, 10, 12, 0, 0, 0));
      expect(weekFilter.endDate, DateTime(2026, 10, 19, 0, 0, 0));

      // Day: 13 Oct 00:00 to 14 Oct 00:00
      final dayFilter = DashboardFilterState(
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );
      expect(dayFilter.startDate, DateTime(2026, 10, 13, 0, 0, 0));
      expect(dayFilter.endDate, DateTime(2026, 10, 14, 0, 0, 0));

      // Year: 2026 Jan 1 to 2027 Jan 1
      final yearFilter = DashboardFilterState(
        periodMode: TimePeriod.year,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );
      expect(yearFilter.startDate, DateTime(2026, 1, 1, 0, 0, 0));
      expect(yearFilter.endDate, DateTime(2027, 1, 1, 0, 0, 0));
    });

    test('Bug 2: Previous and Next navigation across Month and Year boundaries', () {
      final janFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 1, 15),
        tabType: LedgerTabType.expenses,
      );

      final prevFromJan = janFilter.previousPeriod();
      expect(prevFromJan.anchorDate.year, 2025);
      expect(prevFromJan.anchorDate.month, 12);
      expect(prevFromJan.startDate, DateTime(2025, 12, 1, 0, 0, 0));
      expect(prevFromJan.endDate, DateTime(2026, 1, 1, 0, 0, 0));

      final nextBackToJan = prevFromJan.nextPeriod();
      expect(nextBackToJan.anchorDate.year, 2026);
      expect(nextBackToJan.anchorDate.month, 1);
    });

    test('Bug 2: Cache keys are unique per account, period mode, and boundaries', () {
      final allAccountsMonth = DashboardFilterState(
        accountId: null,
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 10, 1),
        tabType: LedgerTabType.expenses,
      );
      final account1Month = DashboardFilterState(
        accountId: 'acc_1',
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 10, 1),
        tabType: LedgerTabType.expenses,
      );
      final allAccountsPrevMonth = DashboardFilterState(
        accountId: null,
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 9, 1),
        tabType: LedgerTabType.expenses,
      );

      expect(allAccountsMonth.queryKey != account1Month.queryKey, isTrue);
      expect(allAccountsMonth.queryKey != allAccountsPrevMonth.queryKey, isTrue);
    });

    test('Authoritative shouldShowToday test for all modes and Month comparison', () {
      final now = DateTime(2026, 10, 13);

      // Month Mode
      // Current month & year: October 2026 -> SHOW (shouldShowToday = true)
      expect(shouldShowToday(
        periodMode: TimePeriod.month,
        selectedDate: DateTime(2026, 10, 1),
        currentLocalDate: now,
      ), isTrue);
      expect(shouldShowToday(
        periodMode: TimePeriod.month,
        selectedDate: DateTime(2026, 10, 31),
        currentLocalDate: now,
      ), isTrue);

      // September 2026 -> HIDE (shouldShowToday = false)
      expect(shouldShowToday(
        periodMode: TimePeriod.month,
        selectedDate: DateTime(2026, 9, 1),
        currentLocalDate: now,
      ), isFalse);

      // November 2026 -> HIDE (shouldShowToday = false)
      expect(shouldShowToday(
        periodMode: TimePeriod.month,
        selectedDate: DateTime(2026, 11, 1),
        currentLocalDate: now,
      ), isFalse);

      // October 2025 (Same month, previous year) -> HIDE (shouldShowToday = false)
      expect(shouldShowToday(
        periodMode: TimePeriod.month,
        selectedDate: DateTime(2025, 10, 1),
        currentLocalDate: now,
      ), isFalse);

      // Day Mode
      // Current day -> SHOW (shouldShowToday = true)
      expect(shouldShowToday(
        periodMode: TimePeriod.day,
        selectedDate: DateTime(2026, 10, 13),
        currentLocalDate: now,
      ), isTrue);
      // Yesterday -> HIDE (shouldShowToday = false)
      expect(shouldShowToday(
        periodMode: TimePeriod.day,
        selectedDate: DateTime(2026, 10, 12),
        currentLocalDate: now,
      ), isFalse);

      // Week Mode
      // Current week -> SHOW (shouldShowToday = true)
      expect(shouldShowToday(
        periodMode: TimePeriod.week,
        selectedDate: DateTime(2026, 10, 14),
        currentLocalDate: now,
      ), isTrue);
      // Previous week -> HIDE (shouldShowToday = false)
      expect(shouldShowToday(
        periodMode: TimePeriod.week,
        selectedDate: DateTime(2026, 10, 5),
        currentLocalDate: now,
      ), isFalse);

      // Year Mode
      // Current year -> SHOW (shouldShowToday = true)
      expect(shouldShowToday(
        periodMode: TimePeriod.year,
        selectedDate: DateTime(2026, 1, 1),
        currentLocalDate: now,
      ), isTrue);
      // Previous year -> HIDE (shouldShowToday = false)
      expect(shouldShowToday(
        periodMode: TimePeriod.year,
        selectedDate: DateTime(2025, 1, 1),
        currentLocalDate: now,
      ), isFalse);
    });

    testWidgets('Widget Test: No Today text badge; ⏩ fast-forward jump appears in Day, Week, Month, Year when non-current', (tester) async {
      final now = DateTime(2026, 10, 13);
      DateTime selectedDate = DateTime(2026, 10, 13);
      TimePeriod currentPeriod = TimePeriod.day;

      Widget buildHarness() {
        return MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) {
                final isCurrent = isCurrentPeriod(
                  periodMode: currentPeriod,
                  selectedDate: selectedDate,
                  currentLocalDate: now,
                );
                return PeriodSelector(
                  selectedPeriod: currentPeriod,
                  onPeriodChanged: (p) => setState(() => currentPeriod = p),
                  dateRangeLabel: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  onPrevious: () => setState(() {
                    if (currentPeriod == TimePeriod.day) {
                      selectedDate = selectedDate.subtract(const Duration(days: 1));
                    } else if (currentPeriod == TimePeriod.week) {
                      selectedDate = selectedDate.subtract(const Duration(days: 7));
                    } else if (currentPeriod == TimePeriod.month) {
                      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, selectedDate.day);
                    } else if (currentPeriod == TimePeriod.year) {
                      selectedDate = DateTime(selectedDate.year - 1, selectedDate.month, selectedDate.day);
                    }
                  }),
                  onNext: () => setState(() {
                    if (currentPeriod == TimePeriod.day) {
                      selectedDate = selectedDate.add(const Duration(days: 1));
                    } else if (currentPeriod == TimePeriod.week) {
                      selectedDate = selectedDate.add(const Duration(days: 7));
                    } else if (currentPeriod == TimePeriod.month) {
                      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, selectedDate.day);
                    } else if (currentPeriod == TimePeriod.year) {
                      selectedDate = DateTime(selectedDate.year + 1, selectedDate.month, selectedDate.day);
                    }
                  }),
                  onToday: () => setState(() => selectedDate = now),
                  canJumpToToday: !isCurrent,
                );
              },
            ),
          ),
        );
      }

      // 1. Initial render: Today (Day mode) -> NO Today text badge, and NO jump action
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsNothing);
      expect(find.byTooltip('Go to current period'), findsNothing);

      // 2. Navigate to yesterday (Day mode) -> ⏩ jump icon MUST appear, NO text badge
      await tester.tap(find.byTooltip('Previous Date'));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsNothing);
      expect(find.byTooltip('Go to current period'), findsOneWidget);

      // 3. Tap ⏩ jump icon -> Date resets to today and icon disappears
      await tester.tap(find.byTooltip('Go to current period'));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsNothing);
      expect(find.byTooltip('Go to current period'), findsNothing);

      // 4. Switch to Month mode -> Currently on current month -> NO jump icon
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsNothing);
      expect(find.byTooltip('Go to current period'), findsNothing);

      // 5. Navigate previous month in Month mode -> ⏩ jump icon MUST appear
      await tester.tap(find.byTooltip('Previous Date'));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsNothing);
      expect(find.byTooltip('Go to current period'), findsOneWidget);

      // 6. Tap ⏩ jump icon -> Resets to current month and icon disappears
      await tester.tap(find.byTooltip('Go to current period'));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsNothing);
      expect(find.byTooltip('Go to current period'), findsNothing);

      // 7. Switch to Year mode and navigate previous -> ⏩ jump icon appears, resets on tap
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Go to current period'), findsNothing);

      await tester.tap(find.byTooltip('Previous Date'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Go to current period'), findsOneWidget);

      await tester.tap(find.byTooltip('Go to current period'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Go to current period'), findsNothing);
    });
  });
}
