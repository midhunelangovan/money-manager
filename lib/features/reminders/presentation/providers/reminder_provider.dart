import 'package:flutter/foundation.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../domain/entities/reminder.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderRepository _repository;
  final NotificationService _notificationService;

  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReminderProvider({
    ReminderRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? ReminderRepository(),
        _notificationService = notificationService ?? NotificationService();

  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReminders({bool rescheduleAlarms = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reminders = await _repository.getAllReminders();
      if (rescheduleAlarms) {
        // Synchronize and register active reminders with notification service (e.g. on startup/restore)
        await _notificationService.rescheduleAllActiveReminders(_reminders);
      }
    } catch (e) {
      _errorMessage = 'Failed to load reminders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestNotificationPermission() async {
    return await _notificationService.requestPermissions();
  }

  NotificationService get notificationService => _notificationService;
  String? _schedulingWarning;
  String? get schedulingWarning => _schedulingWarning;

  Future<void> addReminder(Reminder reminder) async {
    _schedulingWarning = null;
    try {
      // Step 1: Insert into database
      await _repository.insertReminder(reminder);
      
      // Step 2: Schedule in notification system if enabled
      if (reminder.isEnabled) {
        try {
          await _notificationService.scheduleReminder(reminder);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('ReminderProvider: Scheduling error for ${reminder.id}: $e');
          }
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('permission') || errStr.contains('exact_alarm')) {
            _schedulingWarning = 'Saved, but notification permission is required for alerts.';
          } else {
            _schedulingWarning = 'Saved, but notifications could not be scheduled on this device.';
          }
        }
      }
      
      // Step 3: Refresh in-memory list from DB
      _reminders = await _repository.getAllReminders();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add reminder: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    _schedulingWarning = null;
    try {
      // Step 1: Explicitly cancel existing notification/alarm for this reminder
      await _notificationService.cancelReminder(reminder.id);
      
      // Step 2: Persist updated reminder in database
      await _repository.updateReminder(reminder);
      
      // Step 3: Schedule the new trigger time if enabled using standard schedule pipeline
      if (reminder.isEnabled) {
        try {
          await _notificationService.scheduleReminder(reminder);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('ReminderProvider: Scheduling error for ${reminder.id}: $e');
          }
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('permission') || errStr.contains('exact_alarm')) {
            _schedulingWarning = 'Saved, but notification permission is required for alerts.';
          } else {
            _schedulingWarning = 'Saved, but notifications could not be scheduled on this device.';
          }
        }
      }
      
      // Step 4: Refresh in-memory list from DB
      _reminders = await _repository.getAllReminders();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update reminder: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> retryRescheduleReminders() async {
    _isLoading = true;
    _schedulingWarning = null;
    notifyListeners();
    try {
      _reminders = await _repository.getAllReminders();
      await _notificationService.rescheduleAllActiveReminders(_reminders);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ReminderProvider: Retry rescheduling error: $e');
      }
      _schedulingWarning = 'Could not reschedule all reminders. Check system permissions.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleReminder(Reminder reminder) async {
    try {
      final updated = reminder.copyWith(
        isEnabled: !reminder.isEnabled,
        updatedAt: DateTime.now(),
      );
      
      // Step 1: Update in database
      await _repository.updateReminder(updated);
      
      // Step 2: Schedule or Cancel in AlarmManager
      if (updated.isEnabled) {
        await _notificationService.scheduleReminder(updated);
      } else {
        await _notificationService.cancelReminder(updated.id);
      }
      
      // Step 3: Refresh in-memory list from DB
      _reminders = await _repository.getAllReminders();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to toggle reminder: $e';
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      // Step 1: Cancel notification/alarm
      await _notificationService.cancelReminder(id);
      
      // Step 2: Delete from database
      await _repository.deleteReminder(id);
      
      // Step 3: Refresh in-memory list from DB
      _reminders = await _repository.getAllReminders();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete reminder: $e';
      notifyListeners();
      rethrow;
    }
  }
}
