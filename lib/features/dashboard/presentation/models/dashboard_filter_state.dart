import 'package:flutter/material.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/period_selector.dart' as period_selector;
import '../../../../core/widgets/period_selector.dart' show TimePeriod;
import '../../../../core/widgets/transaction_type_tabs.dart';

/// Authoritative filter and state model for Home Dashboard.
/// Encapsulates:
/// - Selected account ID (null represents All Accounts)
/// - Period mode: Day, Week, Month, Year, or Custom Period
/// - Selected date anchor
/// - Custom start/end dates when applicable
/// - Transaction type filter: Expenses, Income, All
class DashboardFilterState {
  final String? accountId; // null = All Accounts
  final TimePeriod periodMode;
  final DateTime anchorDate;
  final DateTimeRange? customDateRange;
  final LedgerTabType tabType;

  const DashboardFilterState({
    this.accountId,
    required this.periodMode,
    required this.anchorDate,
    this.customDateRange,
    required this.tabType,
  });

  DashboardFilterState copyWith({
    String? accountId,
    bool clearAccountId = false,
    TimePeriod? periodMode,
    DateTime? anchorDate,
    DateTimeRange? customDateRange,
    bool clearCustomDateRange = false,
    LedgerTabType? tabType,
  }) {
    return DashboardFilterState(
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      periodMode: periodMode ?? this.periodMode,
      anchorDate: anchorDate ?? this.anchorDate,
      customDateRange: clearCustomDateRange ? null : (customDateRange ?? this.customDateRange),
      tabType: tabType ?? this.tabType,
    );
  }

  /// Calculates the inclusive local start boundary for the period query.
  DateTime get startDate {
    switch (periodMode) {
      case TimePeriod.day:
        return DateTime(anchorDate.year, anchorDate.month, anchorDate.day, 0, 0, 0, 0);
      case TimePeriod.week:
        return anchorDate.startOfWeek;
      case TimePeriod.month:
        return DateTime(anchorDate.year, anchorDate.month, 1, 0, 0, 0, 0);
      case TimePeriod.year:
        return DateTime(anchorDate.year, 1, 1, 0, 0, 0, 0);
      case TimePeriod.period:
        if (customDateRange != null) {
          final s = customDateRange!.start;
          return DateTime(s.year, s.month, s.day, 0, 0, 0, 0);
        }
        return DateTime(anchorDate.year, anchorDate.month, 1, 0, 0, 0, 0);
    }
  }

  /// Calculates the exclusive local upper bound for the period query.
  DateTime get endDate {
    switch (periodMode) {
      case TimePeriod.day:
        return DateTime(anchorDate.year, anchorDate.month, anchorDate.day + 1, 0, 0, 0, 0);
      case TimePeriod.week:
        return anchorDate.startOfWeek.add(const Duration(days: 7));
      case TimePeriod.month:
        return DateTime(anchorDate.year, anchorDate.month + 1, 1, 0, 0, 0, 0);
      case TimePeriod.year:
        return DateTime(anchorDate.year + 1, 1, 1, 0, 0, 0, 0);
      case TimePeriod.period:
        if (customDateRange != null) {
          final e = customDateRange!.end;
          return DateTime(e.year, e.month, e.day + 1, 0, 0, 0, 0);
        }
        return DateTime(anchorDate.year, anchorDate.month + 1, 1, 0, 0, 0, 0);
    }
  }

  /// Determines whether the currently selected period is the current period.
  bool isCurrentPeriod({DateTime? localNow}) => period_selector.isCurrentPeriod(
        periodMode: periodMode,
        selectedDate: anchorDate,
        customRange: customDateRange,
        currentLocalDate: localNow,
      );

  /// Today indicator is visible when the selected period corresponds to the current period.
  bool shouldShowToday({DateTime? localNow}) => isCurrentPeriod(localNow: localNow);

  /// Formatted date range label for UI display.
  String get dateRangeLabel {
    final start = startDate;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    switch (periodMode) {
      case TimePeriod.day:
        final dayName = daysOfWeek[anchorDate.weekday - 1];
        return '${anchorDate.day.toString().padLeft(2, '0')} ${months[anchorDate.month - 1]} ${anchorDate.year} ($dayName)';
      case TimePeriod.week:
        final end = start.add(const Duration(days: 6));
        return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]} ${end.year}';
      case TimePeriod.month:
        return '${months[anchorDate.month - 1]} ${anchorDate.year}';
      case TimePeriod.year:
        return '${anchorDate.year}';
      case TimePeriod.period:
        if (customDateRange != null) {
          final s = customDateRange!.start;
          final e = customDateRange!.end;
          return '${s.day} ${months[s.month - 1]} – ${e.day} ${months[e.month - 1]} ${e.year}';
        }
        return '${months[anchorDate.month - 1]} ${anchorDate.year}';
    }
  }

  /// Navigate to previous period based on active mode.
  DashboardFilterState previousPeriod() {
    switch (periodMode) {
      case TimePeriod.day:
        return copyWith(anchorDate: anchorDate.subtract(const Duration(days: 1)));
      case TimePeriod.week:
        return copyWith(anchorDate: anchorDate.subtract(const Duration(days: 7)));
      case TimePeriod.month:
        final prevMonth = anchorDate.month == 1 ? 12 : anchorDate.month - 1;
        final prevYear = anchorDate.month == 1 ? anchorDate.year - 1 : anchorDate.year;
        final maxDay = DateTime(prevYear, prevMonth + 1, 0).day;
        final safeDay = anchorDate.day.clamp(1, maxDay);
        return copyWith(anchorDate: DateTime(prevYear, prevMonth, safeDay));
      case TimePeriod.year:
        final prevYear = anchorDate.year - 1;
        final maxDay = DateTime(prevYear, anchorDate.month + 1, 0).day;
        final safeDay = anchorDate.day.clamp(1, maxDay);
        return copyWith(anchorDate: DateTime(prevYear, anchorDate.month, safeDay));
      case TimePeriod.period:
        if (customDateRange != null) {
          final days = customDateRange!.duration.inDays + 1;
          final newRange = DateTimeRange(
            start: customDateRange!.start.subtract(Duration(days: days)),
            end: customDateRange!.end.subtract(Duration(days: days)),
          );
          return copyWith(
            customDateRange: newRange,
            anchorDate: newRange.start,
          );
        } else {
          final prevMonth = anchorDate.month == 1 ? 12 : anchorDate.month - 1;
          final prevYear = anchorDate.month == 1 ? anchorDate.year - 1 : anchorDate.year;
          final maxDay = DateTime(prevYear, prevMonth + 1, 0).day;
          final safeDay = anchorDate.day.clamp(1, maxDay);
          return copyWith(anchorDate: DateTime(prevYear, prevMonth, safeDay));
        }
    }
  }

  /// Navigate to next period based on active mode.
  DashboardFilterState nextPeriod() {
    switch (periodMode) {
      case TimePeriod.day:
        return copyWith(anchorDate: anchorDate.add(const Duration(days: 1)));
      case TimePeriod.week:
        return copyWith(anchorDate: anchorDate.add(const Duration(days: 7)));
      case TimePeriod.month:
        final nextMonth = anchorDate.month == 12 ? 1 : anchorDate.month + 1;
        final nextYear = anchorDate.month == 12 ? anchorDate.year + 1 : anchorDate.year;
        final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
        final safeDay = anchorDate.day.clamp(1, maxDay);
        return copyWith(anchorDate: DateTime(nextYear, nextMonth, safeDay));
      case TimePeriod.year:
        final nextYear = anchorDate.year + 1;
        final maxDay = DateTime(nextYear, anchorDate.month + 1, 0).day;
        final safeDay = anchorDate.day.clamp(1, maxDay);
        return copyWith(anchorDate: DateTime(nextYear, anchorDate.month, safeDay));
      case TimePeriod.period:
        if (customDateRange != null) {
          final days = customDateRange!.duration.inDays + 1;
          final newRange = DateTimeRange(
            start: customDateRange!.start.add(Duration(days: days)),
            end: customDateRange!.end.add(Duration(days: days)),
          );
          return copyWith(
            customDateRange: newRange,
            anchorDate: newRange.start,
          );
        } else {
          final nextMonth = anchorDate.month == 12 ? 1 : anchorDate.month + 1;
          final nextYear = anchorDate.month == 12 ? anchorDate.year + 1 : anchorDate.year;
          final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
          final safeDay = anchorDate.day.clamp(1, maxDay);
          return copyWith(anchorDate: DateTime(nextYear, nextMonth, safeDay));
        }
    }
  }

  /// Resets to current period according to active mode (Today action).
  DashboardFilterState toCurrentPeriod({DateTime? localNow}) {
    final now = localNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange? range;
    if (periodMode == TimePeriod.period) {
      range = DateTimeRange(
        start: DateTime(today.year, today.month, 1),
        end: today,
      );
    }
    return copyWith(
      anchorDate: today,
      customDateRange: range,
      clearCustomDateRange: periodMode != TimePeriod.period,
    );
  }

  /// Authoritative cache key for database query results.
  /// Encompasses account scope, period mode, and boundary timestamps.
  String get queryKey =>
      '${accountId ?? "ALL"}_${periodMode.name}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardFilterState &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId &&
          periodMode == other.periodMode &&
          anchorDate.year == other.anchorDate.year &&
          anchorDate.month == other.anchorDate.month &&
          anchorDate.day == other.anchorDate.day &&
          customDateRange == other.customDateRange &&
          tabType == other.tabType;

  @override
  int get hashCode => Object.hash(
        accountId,
        periodMode,
        anchorDate.year,
        anchorDate.month,
        anchorDate.day,
        customDateRange,
        tabType,
      );
}
