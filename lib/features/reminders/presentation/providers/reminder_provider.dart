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
      _notificationService.rescheduleAllActiveReminders(_reminders);
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
      await _repository.insertReminder(reminder);
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
      await _repository.updateReminder(reminder);
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
      await _repository.updateReminder(updated);
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
      await loadReminders();
    } catch (e) {
      _errorMessage = 'Failed to delete reminder: $e';
      notifyListeners();
      rethrow;
    }
  }
}
