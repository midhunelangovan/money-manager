import 'package:flutter/material.dart';
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

class PeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final String dateRangeLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onTapDate;
  final VoidCallback? onToday;
  final bool isToday;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.dateRangeLabel,
    this.onPrevious,
    this.onNext,
    this.onTapDate,
    this.onToday,
    this.isToday = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // Tabs: Day | Week | Month | Year | Period
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: AppColors.darkBorderSubtle) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: TimePeriod.values.map((period) {
              final isSelected = period == selectedPeriod;
              return GestureDetector(
                onTap: () => onPeriodChanged(period),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? primaryColor.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.12))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    period.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? primaryColor : AppColors.primary)
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Date Range Display with Previous / Next Arrows & Interactive Calendar Tap
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: onPrevious,
                iconSize: 26,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                tooltip: 'Previous Date',
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTapDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: isDark ? primaryColor : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dateRangeLabel,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!isToday && onToday != null) ...[
                GestureDetector(
                  onTap: onToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? primaryColor.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? primaryColor.withValues(alpha: 0.4)
                            : AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? primaryColor : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: onNext,
                iconSize: 26,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                tooltip: 'Next Date',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
