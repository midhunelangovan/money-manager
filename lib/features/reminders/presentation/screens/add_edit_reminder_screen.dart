import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
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
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _nameError;
  bool _isSaving = false;

  bool get isEditing => widget.initialReminder != null;

  @override
  void initState() {
    super.initState();
    final reminder = widget.initialReminder;
    _nameController = TextEditingController(text: reminder?.name ?? '');
    _commentController = TextEditingController(text: reminder?.comment ?? '');
    _frequency = reminder?.frequency ?? ReminderFrequency.once;
    _selectedDate = reminder?.date ?? DateTime.now();
    _selectedTime = reminder?.time ?? const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
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

  void _showFrequencyPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
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
                const Divider(),
                ...ReminderFrequency.values.map((freq) {
                  final isSelected = freq == _frequency;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    title: Text(
                      freq.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _frequency = freq);
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

    setState(() => _isSaving = true);
    try {
      final provider = context.read<ReminderProvider>();
      // Ask for notification permission if not yet requested
      await provider.requestNotificationPermission();

      final now = DateTime.now();
      if (isEditing) {
        final updated = widget.initialReminder!.copyWith(
          name: name,
          frequency: _frequency,
          date: _selectedDate,
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
          date: _selectedDate,
          time: _selectedTime,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          isEnabled: true,
          createdAt: now,
          updatedAt: now,
        );
        await provider.addReminder(reminder);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save reminder: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete reminder?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('This will remove this reminder and cancel any scheduled alerts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
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
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
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
                          ),
                          const SizedBox(height: 16),
                          _buildSelectionBox(
                            label: 'Date',
                            value: DateFormatter.formatFullWithDay(_selectedDate),
                            icon: Icons.calendar_today_rounded,
                            onTap: _pickDate,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildSelectionBox(
                            label: 'Time',
                            value: _formatTimeOfDay(_selectedTime),
                            icon: Icons.access_time_rounded,
                            onTap: _pickTime,
                            isDark: isDark,
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
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
