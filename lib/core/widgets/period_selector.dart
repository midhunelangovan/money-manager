import 'package:flutter/material.dart';
import '../extensions/date_extensions.dart';
import '../theme/app_colors.dart';

enum TimePeriod {
  day,
  week,
  month,
  year,
  period,
}

extension TimePeriodExtension on TimePeriod {
  String get displayName {
    switch (this) {
      case TimePeriod.day:
        return 'Day';
      case TimePeriod.week:
        return 'Week';
      case TimePeriod.month:
        return 'Month';
      case TimePeriod.year:
        return 'Year';
      case TimePeriod.period:
        return 'Period';
    }
  }
}

/// Authoritative period-aware determination of whether the selected period matches the current local period.
bool isCurrentPeriod({
  required TimePeriod periodMode,
  required DateTime selectedDate,
  DateTimeRange? customRange,
  DateTime? currentLocalDate,
}) {
  final now = currentLocalDate ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

  switch (periodMode) {
    case TimePeriod.day:
      return selected.year == today.year &&
          selected.month == today.month &&
          selected.day == today.day;

    case TimePeriod.week:
      final currentWeekStart = today.startOfWeek;
      final selectedWeekStart = selected.startOfWeek;
      return currentWeekStart.year == selectedWeekStart.year &&
          currentWeekStart.month == selectedWeekStart.month &&
          currentWeekStart.day == selectedWeekStart.day;

    case TimePeriod.month:
      return selected.year == today.year && selected.month == today.month;

    case TimePeriod.year:
      return selected.year == today.year;

    case TimePeriod.period:
      if (customRange != null) {
        final s = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
        final e = DateTime(customRange.end.year, customRange.end.month, customRange.end.day);
        return !today.isBefore(s) && !today.isAfter(e);
      }
      return selected.year == today.year && selected.month == today.month;
  }
}

/// Helper that returns whether the Today indicator should be shown (true when selected period is current)
bool shouldShowToday({
  required TimePeriod periodMode,
  required DateTime selectedDate,
  DateTimeRange? customRange,
  DateTime? currentLocalDate,
}) {
  return isCurrentPeriod(
    periodMode: periodMode,
    selectedDate: selectedDate,
    customRange: customRange,
    currentLocalDate: currentLocalDate,
  );
}

class PeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final String dateRangeLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onTapDate;
  final VoidCallback? onToday;
  final bool? canJumpToToday;
  final bool? showToday;
  final bool? isToday;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.dateRangeLabel,
    this.onPrevious,
    this.onNext,
    this.onTapDate,
    this.onToday,
    this.canJumpToToday,
    this.showToday,
    this.isToday,
  });

  bool get effectiveCanJumpToToday {
    if (canJumpToToday != null) return canJumpToToday!;
    // When showToday was provided as isCurrentPeriod, jump is available when NOT current period
    if (showToday != null) return !showToday!;
    if (isToday != null) return !isToday!;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBrand = isDark ? theme.colorScheme.primary : AppColors.primary;
    final inactiveText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final showJumpAction = selectedPeriod != TimePeriod.period && effectiveCanJumpToToday && onToday != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tabs: Day | Week | Month | Year | Period with brand highlight & underline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: TimePeriod.values.map((period) {
              final isSelected = period == selectedPeriod;
              return Expanded(
                child: InkWell(
                  onTap: () => onPeriodChanged(period),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          period.displayName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? primaryBrand : inactiveText,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 2.5,
                          width: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBrand : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Date Range Display: Previous, Centered Date Text, Next + ⏩ Jump to Current Period
        SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Center: Date Range Text (Tappable for Date Picker)
              // Strictly bounded between x=76 and x=width-76 to prevent any hit-test overlap with arrows
              Positioned(
                left: 76,
                right: 76,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    key: const ValueKey('period_selector_date_picker_button'),
                    onTap: onTapDate,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        dateRangeLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Left: Previous Arrow (Explicit, isolated 48x44 tap target, never intercepted)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  key: const ValueKey('period_selector_previous_button'),
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: onPrevious,
                  iconSize: 28,
                  color: isDark ? AppColors.darkIconSecondary : AppColors.lightIconSecondary,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
                  padding: EdgeInsets.zero,
                  tooltip: 'Previous Date',
                ),
              ),

              // 3. Right: Next Arrow + ⏩ Jump-to-Current-Period Action (Day, Week, Month, Year)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const ValueKey('period_selector_next_button'),
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: onNext,
                      iconSize: 28,
                      color: isDark ? AppColors.darkIconSecondary : AppColors.lightIconSecondary,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      padding: EdgeInsets.zero,
                      tooltip: 'Next Date',
                    ),
                    if (showJumpAction)
                      IconButton(
                        key: const ValueKey('period_selector_jump_current_button'),
                        icon: const Icon(Icons.fast_forward_rounded, size: 20),
                        onPressed: onToday,
                        color: primaryBrand,
                        tooltip: 'Go to current period',
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reusable Month & Year picker dialog
class MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const MonthPickerDialog({super.key, required this.initialDate});

  static Future<DateTime?> show(BuildContext context, DateTime initialDate) {
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => MonthPickerDialog(initialDate: initialDate),
    );
  }

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year Selector Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(() => _selectedYear--),
                  tooltip: 'Previous Year',
                ),
                Text(
                  '$_selectedYear',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => setState(() => _selectedYear++),
                  tooltip: 'Next Year',
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Month Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (ctx, index) {
                final monthNum = index + 1;
                final isSelected = _selectedYear == widget.initialDate.year && _selectedMonth == monthNum;
                final isCurrentMonth = now.year == _selectedYear && now.month == monthNum;

                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(DateTime(_selectedYear, monthNum, 1));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? primaryColor : AppColors.primary)
                          : (isCurrentMonth
                              ? (isDark ? primaryColor.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.08))
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isCurrentMonth
                                  ? (isDark ? primaryColor.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.3))
                                  : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                              width: isCurrentMonth ? 1.5 : 1,
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _months[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || isCurrentMonth ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
