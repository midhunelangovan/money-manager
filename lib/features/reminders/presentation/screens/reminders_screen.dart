import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';
import 'add_edit_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ReminderProvider>();
      await provider.loadReminders();
      final enabled = await provider.notificationService.areNotificationsEnabled();
      if (mounted) {
        setState(() => _notificationsEnabled = enabled);
      }
    });
  }

  String _formatOrdinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  String _formatReminderSchedule(Reminder reminder) {
    final timeStr = DateFormatter.formatTime(DateTime(
      2026,
      1,
      1,
      reminder.time.hour,
      reminder.time.minute,
    ));

    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        return 'Every day • $timeStr';
      case ReminderFrequency.weekly:
        final weekdayName = _weekdays[(reminder.date.weekday - 1).clamp(0, 6)];
        return 'Every $weekdayName • $timeStr';
      case ReminderFrequency.monthly:
        final ordinal = _formatOrdinal(reminder.date.day);
        return 'Every $ordinal of the month • $timeStr';
      case ReminderFrequency.yearly:
        final monthName = _months[(reminder.date.month - 1).clamp(0, 11)];
        final ordinal = _formatOrdinal(reminder.date.day);
        return 'Every $monthName $ordinal • $timeStr';
      case ReminderFrequency.once:
        final relativeDate = DateFormatter.formatRelative(reminder.date);
        return '$relativeDate • $timeStr';
      case ReminderFrequency.custom:
        return 'Custom • $timeStr';
    }
  }

  IconData _getFrequencyIcon(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return Icons.repeat_rounded;
      case ReminderFrequency.weekly:
        return Icons.event_repeat_rounded;
      case ReminderFrequency.monthly:
        return Icons.calendar_month_rounded;
      case ReminderFrequency.yearly:
        return Icons.calendar_today_rounded;
      case ReminderFrequency.custom:
        return Icons.tune_rounded;
      case ReminderFrequency.once:
        return Icons.notifications_active_rounded;
    }
  }

  void _openAddReminder() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditReminderScreen(),
      ),
    );
  }

  void _openEditReminder(Reminder reminder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditReminderScreen(initialReminder: reminder),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No reminders yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set personal notifications for routines, bills, or tasks. Reminders work completely offline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _openAddReminder,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Create Reminder',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(Reminder reminder, bool isDark, Color primaryColor) {
    final scheduleText = _formatReminderSchedule(reminder);
    final frequencyIcon = _getFrequencyIcon(reminder.frequency);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: InkWell(
          onTap: () => _openEditReminder(reminder),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: reminder.isEnabled
                      ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                      : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  reminder.isEnabled ? frequencyIcon : Icons.notifications_off_rounded,
                  size: 22,
                  color: reminder.isEnabled
                      ? primaryColor
                      : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary),
                ),
              ),
              const SizedBox(width: 14),

              // Reminder Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: reminder.isEnabled
                            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: reminder.isEnabled
                                ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                                : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reminder.isEnabled ? frequencyIcon : Icons.alarm_off_rounded,
                                size: 11,
                                color: reminder.isEnabled
                                    ? primaryColor
                                    : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                reminder.frequency.shortName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: reminder.isEnabled
                                      ? primaryColor
                                      : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scheduleText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (reminder.comment != null && reminder.comment!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.comment!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Enable/Disable Switch
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: reminder.isEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    context.read<ReminderProvider>().toggleReminder(reminder);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _openAddReminder,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Create Reminder',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Reminders',
              showBackButton: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  tooltip: 'Create Reminder',
                  onPressed: _openAddReminder,
                ),
              ],
            ),
            if (!_notificationsEnabled)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade800.withValues(alpha: isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_off_rounded,
                      color: Colors.amber.shade800,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications are disabled. Reminders will not appear until allowed in system settings.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        final provider = context.read<ReminderProvider>();
                        final granted = await provider.requestNotificationPermission();
                        if (mounted) {
                          setState(() => _notificationsEnabled = granted);
                        }
                      },
                      child: Text(
                        'Enable',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Consumer<ReminderProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.reminders.isEmpty) {
                    return Center(child: CircularProgressIndicator(color: primaryColor));
                  }

                  if (provider.reminders.isEmpty) {
                    return _buildEmptyState(isDark, primaryColor);
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadReminders(),
                    color: primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                      itemCount: provider.reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = provider.reminders[index];
                        return _buildReminderItem(reminder, isDark, primaryColor);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
