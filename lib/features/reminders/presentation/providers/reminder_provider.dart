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

  Future<void> showTestNotification() async {
    await _notificationService.showTestNotification();
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      final scheduleId = NotificationService.getNotificationId(reminder.id);
      debugPrint('[REMINDER_CREATED] id: ${reminder.id}, scheduleId: $scheduleId, name: "${reminder.name}", freq: ${reminder.frequency.name}, date: ${reminder.date.toIso8601String()}, time: ${reminder.time.hour}:${reminder.time.minute}');
      
      // Step 1: Insert into database
      await _repository.insertReminder(reminder);
      debugPrint('[REMINDER_PERSISTED] id: ${reminder.id}');
      
      // Step 2: Schedule in AlarmManager if enabled
      if (reminder.isEnabled) {
        await _notificationService.scheduleReminder(reminder);
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
    try {
      final scheduleId = NotificationService.getNotificationId(reminder.id);
      debugPrint('[REMINDER_UPDATE_REQUESTED] id: ${reminder.id}, scheduleId: $scheduleId, name: "${reminder.name}", freq: ${reminder.frequency.name}, enabled: ${reminder.isEnabled}, date: ${reminder.date.toIso8601String()}, time: ${reminder.time.hour}:${reminder.time.minute}');
      
      // Step 1: Explicitly cancel existing notification/alarm for this reminder
      await _notificationService.cancelReminder(reminder.id);
      
      // Step 2: Persist updated reminder in database
      await _repository.updateReminder(reminder);
      debugPrint('[REMINDER_PERSISTED] id: ${reminder.id}');
      
      // Step 3: Schedule the new trigger time if enabled using standard schedule pipeline
      if (reminder.isEnabled) {
        await _notificationService.scheduleReminder(reminder);
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

  Future<void> toggleReminder(Reminder reminder) async {
    try {
      final updated = reminder.copyWith(
        isEnabled: !reminder.isEnabled,
        updatedAt: DateTime.now(),
      );
      final scheduleId = NotificationService.getNotificationId(updated.id);
      debugPrint('[REMINDER_TOGGLED] id: ${updated.id}, scheduleId: $scheduleId, isEnabled: ${updated.isEnabled}');
      
      // Step 1: Update in database
      await _repository.updateReminder(updated);
      debugPrint('[REMINDER_PERSISTED] id: ${updated.id}');
      
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
      final scheduleId = NotificationService.getNotificationId(id);
      debugPrint('[REMINDER_DELETED] id: $id, scheduleId: $scheduleId');
      
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
