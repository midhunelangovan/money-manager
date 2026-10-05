import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/reminders/domain/entities/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static bool isTestMode = false;

  static const String channelId = 'kals_reminders_channel';
  static const String channelName = 'Personal Reminders';
  static const String channelDescription = 'Offline personal reminders and financial alerts';

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (isTestMode) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      _isInitialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone().timeout(
          const Duration(seconds: 2),
        );
        final String identifier = tzInfo.identifier;
        final location = _findMatchingLocation(identifier);
        tz.setLocalLocation(location);
        if (kDebugMode) {
          debugPrint('NotificationService: Local timezone initialized: ${tz.local.name}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NotificationService: Local timezone fallback: $e');
        }
        _configureFallbackTimezone();
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) {
            debugPrint('[REMINDER_NOTIFICATION_CLICKED] payload: ${response.payload}');
          }
        },
      );

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: channelDescription,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
        }
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Initialization error: $e');
      }
    }
  }

  static tz.Location _findMatchingLocation(String identifier) {
    if (tz.timeZoneDatabase.locations.containsKey(identifier)) {
      return tz.getLocation(identifier);
    }
    // Try case-insensitive match
    for (final entry in tz.timeZoneDatabase.locations.entries) {
      if (entry.key.toLowerCase() == identifier.toLowerCase()) {
        return entry.value;
      }
    }
    // Try offset match
    final offset = DateTime.now().timeZoneOffset;
    for (final location in tz.timeZoneDatabase.locations.values) {
      final tzNow = tz.TZDateTime.now(location);
      if (tzNow.timeZoneOffset == offset) {
        return location;
      }
    }
    return tz.getLocation('UTC');
  }

  static void _configureFallbackTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      for (final location in tz.timeZoneDatabase.locations.values) {
        final tzNow = tz.TZDateTime.now(location);
        if (tzNow.timeZoneOffset == offset) {
          tz.setLocalLocation(location);
          return;
        }
      }
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }

  Future<bool> requestPermissions() async {
    try {
      await initialize();
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final exactAlarm = await androidImpl.requestExactAlarmsPermission();
          final postNotifs = await androidImpl.requestNotificationsPermission();
          return (postNotifs ?? false) || (exactAlarm ?? false);
        }
      } else if (Platform.isIOS) {
        final iosImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Request permissions error: $e');
      }
    }
    return false;
  }

  /// Generates a deterministic positive 31-bit integer hash from any string ID.
  /// Guarantees that across process restarts and OS reboots, the same reminder ID
  /// always maps to the exact same notification/alarm ID.
  static int getNotificationId(String id) {
    var hash = 0x811c9dc5;
    for (int i = 0; i < id.length; i++) {
      hash ^= id.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<void> showTestNotification() async {
    try {
      await initialize();
      await requestPermissions();

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        999999,
        'Money Manager Reminder Test',
        'Your offline reminders and notifications are working properly!',
        notificationDetails,
      );
      if (kDebugMode) {
        debugPrint('[REMINDER_NOTIFICATION_SHOWN] Test notification fired successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Test notification error: $e');
      }
    }
  }

  /// Calculates the next valid occurrence for a reminder in device local time
  tz.TZDateTime calculateNextTrigger(Reminder reminder, tz.TZDateTime now) {
    final targetHour = reminder.time.hour;
    final targetMinute = reminder.time.minute;

    switch (reminder.frequency) {
      case ReminderFrequency.once:
        return tz.TZDateTime(
          tz.local,
          reminder.date.year,
          reminder.date.month,
          reminder.date.day,
          targetHour,
          targetMinute,
        );

      case ReminderFrequency.daily:
        var next = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          targetHour,
          targetMinute,
        );
        if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case ReminderFrequency.weekly:
        final targetWeekday = reminder.date.weekday;
        var next = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          targetHour,
          targetMinute,
        );
        while (next.weekday != targetWeekday || next.isBefore(now) || next.isAtSameMomentAs(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case ReminderFrequency.monthly:
        var year = now.year;
        var month = now.month;
        final targetDay = reminder.date.day;

        int maxDays = DateTime(year, month + 1, 0).day;
        var clampedDay = targetDay.clamp(1, maxDays);

        var next = tz.TZDateTime(
          tz.local,
          year,
          month,
          clampedDay,
          targetHour,
          targetMinute,
        );

        if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
          if (month == 12) {
            year += 1;
            month = 1;
          } else {
            month += 1;
          }
          maxDays = DateTime(year, month + 1, 0).day;
          clampedDay = targetDay.clamp(1, maxDays);
          next = tz.TZDateTime(
            tz.local,
            year,
            month,
            clampedDay,
            targetHour,
            targetMinute,
          );
        }
        return next;

      case ReminderFrequency.yearly:
        var year = now.year;
        final targetMonth = reminder.date.month;
        final targetDay = reminder.date.day;

        int maxDays = DateTime(year, targetMonth + 1, 0).day;
        var clampedDay = targetDay.clamp(1, maxDays);

        var next = tz.TZDateTime(
          tz.local,
          year,
          targetMonth,
          clampedDay,
          targetHour,
          targetMinute,
        );

        if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
          year += 1;
          maxDays = DateTime(year, targetMonth + 1, 0).day;
          clampedDay = targetDay.clamp(1, maxDays);
          next = tz.TZDateTime(
            tz.local,
            year,
            targetMonth,
            clampedDay,
            targetHour,
            targetMinute,
          );
        }
        return next;

      case ReminderFrequency.custom:
        return tz.TZDateTime(
          tz.local,
          reminder.date.year,
          reminder.date.month,
          reminder.date.day,
          targetHour,
          targetMinute,
        );
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isEnabled) {
      await cancelReminder(reminder.id);
      return;
    }

    try {
      await initialize();
      final id = getNotificationId(reminder.id);

      // Cancel previous notification if any to prevent duplicates
      try {
        await _notificationsPlugin.cancel(id);
      } catch (e) {
        debugPrint('NotificationService: Pre-cancel notification notice: $e');
      }

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDateTime = calculateNextTrigger(reminder, now);

      debugPrint(
        '[REMINDER_SCHEDULE_REQUESTED] id: ${reminder.id}, name: "${reminder.name}", '
        'freq: ${reminder.frequency.name}, nowLocal: $now, targetLocal: $scheduledDateTime, '
        'diffSec: ${scheduledDateTime.difference(now).inSeconds}',
      );

      if (isTestMode) {
        debugPrint('[REMINDER_SCHEDULED] (testMode) id: ${reminder.id}, scheduleId: $id, trigger: $scheduledDateTime');
        return;
      }

      // If one-time or custom reminder is strictly in the past, do not schedule
      if ((reminder.frequency == ReminderFrequency.once || reminder.frequency == ReminderFrequency.custom) &&
          scheduledDateTime.isBefore(now)) {
        debugPrint('NotificationService: One-time reminder is in the past, skipping: ${reminder.id}');
        return;
      }

      DateTimeComponents? matchComponents;
      switch (reminder.frequency) {
        case ReminderFrequency.daily:
          matchComponents = DateTimeComponents.time;
          break;
        case ReminderFrequency.weekly:
          matchComponents = DateTimeComponents.dayOfWeekAndTime;
          break;
        case ReminderFrequency.monthly:
          matchComponents = DateTimeComponents.dayOfMonthAndTime;
          break;
        case ReminderFrequency.yearly:
          matchComponents = DateTimeComponents.dateAndTime;
          break;
        case ReminderFrequency.once:
        case ReminderFrequency.custom:
          matchComponents = null;
          break;
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          reminder.name,
          reminder.comment?.isNotEmpty == true ? reminder.comment : 'Reminder from Money Manager',
          scheduledDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
        );
        debugPrint('[REMINDER_SCHEDULED] (exact) id: ${reminder.id}, scheduleId: $id, trigger: $scheduledDateTime');
      } catch (e) {
        debugPrint('NotificationService: Exact alarm fallback to inexact: $e');
        await _notificationsPlugin.zonedSchedule(
          id,
          reminder.name,
          reminder.comment?.isNotEmpty == true ? reminder.comment : 'Reminder from Money Manager',
          scheduledDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
        );
        debugPrint('[REMINDER_SCHEDULED] (inexact) id: ${reminder.id}, scheduleId: $id, trigger: $scheduledDateTime');
      }
    } catch (e, stack) {
      debugPrint('NotificationService: Error scheduling reminder: $e\n$stack');
    }
  }

  Future<void> rescheduleAllActiveReminders(List<Reminder> reminders) async {
    try {
      await initialize();
      for (final reminder in reminders) {
        if (reminder.isEnabled) {
          await scheduleReminder(reminder);
        } else {
          await cancelReminder(reminder.id);
        }
      }
      debugPrint('[REMINDER_RESCHEDULED] Rescheduled ${reminders.where((r) => r.isEnabled).length} active reminders');
    } catch (e) {
      debugPrint('NotificationService: Reschedule all error: $e');
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    try {
      final id = getNotificationId(reminderId);
      if (isTestMode) {
        debugPrint('[REMINDER_CANCELLED] (testMode) id: $reminderId, scheduleId: $id');
        return;
      }
      await _notificationsPlugin.cancel(id);
      debugPrint('[REMINDER_CANCELLED] id: $reminderId, scheduleId: $id');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling reminder: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('NotificationService: Cancelled all notifications');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling all notifications: $e');
    }
  }
}
