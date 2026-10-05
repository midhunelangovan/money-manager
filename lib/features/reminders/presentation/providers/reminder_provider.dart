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

  Future<void> loadReminders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reminders = await _repository.getAllReminders();
      // Synchronize and register active reminders with notification service
      await _notificationService.rescheduleAllActiveReminders(_reminders);
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
      if (kDebugMode) {
        debugPrint('[REMINDER_CREATED] id: ${reminder.id}, name: "${reminder.name}", freq: ${reminder.frequency.name}, date: ${reminder.date.toIso8601String()}, time: ${reminder.time.hour}:${reminder.time.minute}');
      }
      await _repository.insertReminder(reminder);
      if (kDebugMode) {
        debugPrint('[REMINDER_PERSISTED] id: ${reminder.id}');
      }
      if (reminder.isEnabled) {
        await _notificationService.scheduleReminder(reminder);
      }
      await loadReminders();
    } catch (e) {
      _errorMessage = 'Failed to add reminder: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      if (kDebugMode) {
        debugPrint('[REMINDER_UPDATED] id: ${reminder.id}, name: "${reminder.name}", enabled: ${reminder.isEnabled}');
      }
      await _repository.updateReminder(reminder);
      if (kDebugMode) {
        debugPrint('[REMINDER_PERSISTED] id: ${reminder.id}');
      }
      if (reminder.isEnabled) {
        await _notificationService.scheduleReminder(reminder);
      } else {
        await _notificationService.cancelReminder(reminder.id);
      }
      await loadReminders();
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
      if (kDebugMode) {
        debugPrint('[REMINDER_TOGGLED] id: ${updated.id}, isEnabled: ${updated.isEnabled}');
      }
      await _repository.updateReminder(updated);
      if (kDebugMode) {
        debugPrint('[REMINDER_PERSISTED] id: ${updated.id}');
      }
      if (updated.isEnabled) {
        await _notificationService.scheduleReminder(updated);
      } else {
        await _notificationService.cancelReminder(updated.id);
      }
      await loadReminders();
    } catch (e) {
      _errorMessage = 'Failed to toggle reminder: $e';
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _notificationService.cancelReminder(id);
      await _repository.deleteReminder(id);
      if (kDebugMode) {
        debugPrint('[REMINDER_DELETED] id: $id');
      }
      await loadReminders();
    } catch (e) {
      _errorMessage = 'Failed to delete reminder: $e';
      notifyListeners();
      rethrow;
    }
  }
}
