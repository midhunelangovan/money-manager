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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadReminders();
    });
  }

  String _formatReminderSchedule(Reminder reminder) {
    final timeStr = DateFormatter.formatTime(DateTime(
      2026,
      1,
      1,
      reminder.time.hour,
      reminder.time.minute,
    ));

    final relativeDate = DateFormatter.formatRelative(reminder.date);
    if (reminder.frequency == ReminderFrequency.once) {
      return '$relativeDate • $timeStr';
    } else {
      return '${reminder.frequency.displayName} • $timeStr';
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

  Widget _buildEmptyState(bool isDark) {
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
                color: AppColors.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: AppColors.primary,
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await context.read<ReminderProvider>().showTestNotification();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent! Check your notification bar.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Send Test Notification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(Reminder reminder, bool isDark) {
    final scheduleText = _formatReminderSchedule(reminder);

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
                      ? AppColors.primaryContainer.withValues(alpha: isDark ? 0.3 : 0.6)
                      : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  reminder.isEnabled ? Icons.alarm_rounded : Icons.alarm_off_rounded,
                  size: 24,
                  color: reminder.isEnabled
                      ? AppColors.primary
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
                            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REMINDER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
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
                  activeThumbColor: AppColors.primary,
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                  icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                  tooltip: 'Test Notification',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<ReminderProvider>().showTestNotification();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Test notification sent! Check your notification shade.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  tooltip: 'Create Reminder',
                  onPressed: _openAddReminder,
                ),
              ],
            ),
            Expanded(
              child: Consumer<ReminderProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.reminders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.reminders.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadReminders(),
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                      itemCount: provider.reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = provider.reminders[index];
                        return _buildReminderItem(reminder, isDark);
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
