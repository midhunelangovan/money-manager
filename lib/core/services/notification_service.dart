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

  static const String channelId = 'kals_reminders_channel';
  static const String channelName = 'Personal Reminders';
  static const String channelDescription = 'Offline personal reminders and financial alerts';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone().timeout(
          const Duration(seconds: 2),
          onTimeout: () => TimezoneInfo(identifier: 'UTC'),
        );
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NotificationService: Local timezone fallback: $e');
        }
        tz.setLocalLocation(tz.local);
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
            debugPrint('NotificationService: Clicked ${response.payload}');
          }
        },
      ).timeout(
        const Duration(seconds: 1),
        onTimeout: () => false,
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
          ).timeout(
            const Duration(seconds: 1),
            onTimeout: () {},
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

  Future<bool> requestPermissions() async {
    try {
      await initialize();
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final exactAlarm = await androidImpl.requestExactAlarmsPermission();
          final postNotifs = await androidImpl.requestNotificationsPermission();
          return postNotifs ?? exactAlarm ?? true;
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

  int _getNotificationId(String id) {
    return id.hashCode.abs() % 2147483647;
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
      final id = _getNotificationId(reminder.id);

      // Cancel previous notification if any to prevent duplicates
      await _notificationsPlugin.cancel(id).timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDateTime = calculateNextTrigger(reminder, now);

      // If one-time or custom reminder is strictly in the past, do not schedule
      if ((reminder.frequency == ReminderFrequency.once || reminder.frequency == ReminderFrequency.custom) &&
          scheduledDateTime.isBefore(now)) {
        if (kDebugMode) {
          debugPrint('NotificationService: One-time reminder is in the past, skipping: ${reminder.id}');
        }
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
        ).timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );
        if (kDebugMode) {
          debugPrint('NotificationService: Scheduled (exact) reminder "${reminder.name}" at $scheduledDateTime');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NotificationService: Exact alarm fallback to inexact: $e');
        }
        await _notificationsPlugin.zonedSchedule(
          id,
          reminder.name,
          reminder.comment?.isNotEmpty == true ? reminder.comment : 'Reminder from Money Manager',
          scheduledDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
        ).timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error scheduling reminder: $e');
      }
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
      if (kDebugMode) {
        debugPrint('NotificationService: Rescheduled ${reminders.where((r) => r.isEnabled).length} active reminders');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Reschedule all error: $e');
      }
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    try {
      final id = _getNotificationId(reminderId);
      await _notificationsPlugin.cancel(id).timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
      if (kDebugMode) {
        debugPrint('NotificationService: Cancelled reminder $reminderId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error cancelling reminder: $e');
      }
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error cancelling all notifications: $e');
      }
    }
  }
}
