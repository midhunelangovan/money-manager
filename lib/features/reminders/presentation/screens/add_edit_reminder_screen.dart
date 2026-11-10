import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? initialReminder;

  const AddEditReminderScreen({
    super.key,
    this.initialReminder,
  });

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _commentController;
  late ReminderFrequency _frequency;

  // Scheduling state variables
  late DateTime _selectedDate; // Used for "once"
  late TimeOfDay _selectedTime;
  late int _selectedWeekday; // 1 = Monday, 7 = Sunday (Used for "weekly")
  late int _selectedDayOfMonth; // 1..31 (Used for "monthly" and "yearly")
  late int _selectedMonth; // 1..12 (Used for "yearly")

  String? _nameError;
  bool _isSaving = false;

  bool get isEditing => widget.initialReminder != null;

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
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final reminder = widget.initialReminder;
    final now = DateTime.now();

    _nameController = TextEditingController(text: reminder?.name ?? '');
    _commentController = TextEditingController(text: reminder?.comment ?? '');
    _frequency = reminder?.frequency ?? ReminderFrequency.daily;

    if (reminder != null) {
      final reminderDateOnly = DateTime(reminder.date.year, reminder.date.month, reminder.date.day);
      final todayDateOnly = DateTime(now.year, now.month, now.day);
      if (_frequency == ReminderFrequency.once && reminderDateOnly.isBefore(todayDateOnly)) {
        _selectedDate = todayDateOnly;
      } else {
        _selectedDate = reminder.date;
      }
      _selectedTime = reminder.time;
      _selectedWeekday = reminder.date.weekday;
      _selectedDayOfMonth = reminder.date.day;
      _selectedMonth = reminder.date.month;
    } else {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = const TimeOfDay(hour: 21, minute: 30); // 9:30 PM default
      _selectedWeekday = now.weekday;
      _selectedDayOfMonth = now.day;
      _selectedMonth = now.month;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
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

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormatter.formatTime(dt);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  IconData _getFrequencyIcon(ReminderFrequency freq) {
    switch (freq) {
      case ReminderFrequency.once:
        return Icons.notifications_active_rounded;
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
    }
  }

  void _showWeekdayPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Select Day of Week',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ...List.generate(7, (index) {
                  final weekdayNumber = index + 1;
                  final weekdayName = _weekdays[index];
                  final isSelected = _selectedWeekday == weekdayNumber;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? primaryColor.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.12))
                            : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_view_week_rounded,
                        size: 20,
                        color: isSelected
                            ? (isDark ? primaryColor : AppColors.primary)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                    title: Text(
                      'Every $weekdayName',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? primaryColor : AppColors.primary)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: isDark ? primaryColor : AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedWeekday = weekdayNumber);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDayOfMonthPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    'Select Day of Month',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 31,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isSelected = _selectedDayOfMonth == day;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedDayOfMonth = day);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? primaryColor : AppColors.primary)
                                : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? null
                                : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (isDark ? AppColors.darkBackground : Colors.white)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthAndDayPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final maxDays = DateTime(2026, _selectedMonth + 1, 0).day;
            final currentDay = _selectedDayOfMonth.clamp(1, maxDays);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Month and Day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Month Dropdown
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkInputSurface : AppColors.lightInputSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedMonth,
                                dropdownColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                items: List.generate(12, (index) {
                                  final m = index + 1;
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      _months[index],
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }),
                                onChanged: (newMonth) {
                                  if (newMonth != null) {
                                    setModalState(() {
                                      _selectedMonth = newMonth;
                                    });
                                    setState(() {
                                      _selectedMonth = newMonth;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Day Dropdown
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkInputSurface : AppColors.lightInputSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: currentDay,
                                dropdownColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                items: List.generate(maxDays, (index) {
                                  final d = index + 1;
                                  return DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      _formatOrdinal(d),
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }),
                                onChanged: (newDay) {
                                  if (newDay != null) {
                                    setModalState(() {
                                      _selectedDayOfMonth = newDay;
                                    });
                                    setState(() {
                                      _selectedDayOfMonth = newDay;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? primaryColor : AppColors.primary,
                          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFrequencyPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Reminder Frequency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ...ReminderFrequency.values.where((f) => f != ReminderFrequency.custom).map((freq) {
                  final isSelected = freq == _frequency;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? primaryColor.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.12))
                            : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getFrequencyIcon(freq),
                        size: 20,
                        color: isSelected
                            ? (isDark ? primaryColor : AppColors.primary)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                    title: Text(
                      freq.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? primaryColor : AppColors.primary)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: isDark ? primaryColor : AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _frequency = freq;
                        if (freq == ReminderFrequency.once) {
                          final now = DateTime.now();
                          final todayDateOnly = DateTime(now.year, now.month, now.day);
                          if (_selectedDate.isBefore(todayDateOnly)) {
                            _selectedDate = todayDateOnly;
                          }
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Required field');
      return;
    }

    final now = DateTime.now();
    DateTime anchorDate;

    switch (_frequency) {
      case ReminderFrequency.once:
        anchorDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        final scheduledTarget = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        if (scheduledTarget.isBefore(now.subtract(const Duration(seconds: 10)))) {
          AppSnackBar.showError(
            context,
            'The selected time is in the past. Please choose a future time or date.',
          );
          return;
        }
        break;

      case ReminderFrequency.daily:
        // Internal anchor is today
        anchorDate = DateTime(now.year, now.month, now.day);
        break;

      case ReminderFrequency.weekly:
        // Internal anchor is a date matching the chosen weekday
        final diff = (_selectedWeekday - now.weekday) % 7;
        anchorDate = DateTime(now.year, now.month, now.day).add(Duration(days: diff));
        break;

      case ReminderFrequency.monthly:
        // Internal anchor matches chosen day of month
        final maxDays = DateTime(now.year, now.month + 1, 0).day;
        final validDay = _selectedDayOfMonth.clamp(1, maxDays);
        anchorDate = DateTime(now.year, now.month, validDay);
        break;

      case ReminderFrequency.yearly:
        // Internal anchor matches chosen month and day
        final maxDays = DateTime(now.year, _selectedMonth + 1, 0).day;
        final validDay = _selectedDayOfMonth.clamp(1, maxDays);
        anchorDate = DateTime(now.year, _selectedMonth, validDay);
        break;

      case ReminderFrequency.custom:
        anchorDate = DateTime(now.year, now.month, now.day);
        break;
    }

    setState(() => _isSaving = true);
    try {
      final provider = context.read<ReminderProvider>();
      // Ask for notification permission if not yet requested
      await provider.requestNotificationPermission();

      if (isEditing) {
        final updated = widget.initialReminder!.copyWith(
          name: name,
          frequency: _frequency,
          date: anchorDate,
          time: _selectedTime,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          updatedAt: now,
        );
        await provider.updateReminder(updated);
      } else {
        final reminder = Reminder(
          id: IdGenerator.generate(),
          name: name,
          frequency: _frequency,
          date: anchorDate,
          time: _selectedTime,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          isEnabled: true,
          createdAt: now,
          updatedAt: now,
        );
        await provider.addReminder(reminder);
      }

      if (mounted) {
        final isNew = !isEditing;
        final warning = provider.schedulingWarning;
        Navigator.pop(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final rootContext = MainNavigationService.navigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            if (warning != null) {
              AppSnackBar.showError(rootContext, warning);
            } else {
              AppSnackBar.showSuccess(
                rootContext,
                isNew ? 'Reminder scheduled successfully.' : 'Reminder updated successfully.',
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save reminder: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete reminder?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'This will remove this reminder and cancel any scheduled alerts.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ReminderProvider>();
      await provider.deleteReminder(widget.initialReminder!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildSelectionBox({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputSurface : AppColors.lightInputSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isDark ? primaryColor : AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: isEditing ? 'Edit Reminder' : 'Create Reminder',
              showBackButton: true,
              actions: [
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    tooltip: 'Delete Reminder',
                    onPressed: _delete,
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Reminder Name',
                            hintText: 'Enter reminder name',
                            onChanged: (_) {
                              if (_nameError != null) {
                                setState(() => _nameError = null);
                              }
                            },
                          ),
                          if (_nameError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _nameError!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildSelectionBox(
                            label: 'Reminder Frequency',
                            value: _frequency.displayName,
                            icon: Icons.repeat_rounded,
                            onTap: _showFrequencyPicker,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),

                          // Dynamic Frequency-Specific Scheduling Fields
                          if (_frequency == ReminderFrequency.weekly) ...[
                            const SizedBox(height: 16),
                            _buildSelectionBox(
                              label: 'Day of week',
                              value: 'Every ${_weekdays[_selectedWeekday - 1]}',
                              icon: Icons.event_repeat_rounded,
                              onTap: _showWeekdayPicker,
                              isDark: isDark,
                              primaryColor: primaryColor,
                            ),
                          ] else if (_frequency == ReminderFrequency.monthly) ...[
                            const SizedBox(height: 16),
                            _buildSelectionBox(
                              label: 'Day of month',
                              value: 'Every ${_formatOrdinal(_selectedDayOfMonth)} of the month',
                              icon: Icons.calendar_month_rounded,
                              onTap: _showDayOfMonthPicker,
                              isDark: isDark,
                              primaryColor: primaryColor,
                            ),
                          ] else if (_frequency == ReminderFrequency.yearly) ...[
                            const SizedBox(height: 16),
                            _buildSelectionBox(
                              label: 'Month & Day',
                              value: '${_months[_selectedMonth - 1]} ${_formatOrdinal(_selectedDayOfMonth)}',
                              icon: Icons.calendar_today_rounded,
                              onTap: _showMonthAndDayPicker,
                              isDark: isDark,
                              primaryColor: primaryColor,
                            ),
                          ] else if (_frequency == ReminderFrequency.once) ...[
                            const SizedBox(height: 16),
                            _buildSelectionBox(
                              label: 'Date',
                              value: DateFormatter.formatFullWithDay(_selectedDate),
                              icon: Icons.calendar_today_rounded,
                              onTap: _pickDate,
                              isDark: isDark,
                              primaryColor: primaryColor,
                            ),
                          ],

                          const SizedBox(height: 16),
                          _buildSelectionBox(
                            label: 'Time',
                            value: _formatTimeOfDay(_selectedTime),
                            icon: Icons.access_time_rounded,
                            onTap: _pickTime,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _commentController,
                            label: 'Comment',
                            hintText: 'Optional note or comment...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? primaryColor : AppColors.primary,
                          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark ? AppColors.darkBackground : Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Create',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
