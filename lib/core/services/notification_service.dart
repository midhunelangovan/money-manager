import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:open_filex/open_filex.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/recurring/domain/entities/recurring_transaction.dart';
import '../../features/reminders/domain/entities/reminder.dart';
import '../theme/app_colors.dart';

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

  static const String exportChannelId = 'kals_exports_channel';
  static const String exportChannelName = 'Export & Backup Reports';
  static const String exportChannelDescription = 'Status notifications when scheduled or manual exports complete';

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
        onDidReceiveNotificationResponse: (response) async {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final file = File(payload);
            if (await file.exists()) {
              try {
                await OpenFilex.open(payload);
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('NotificationService: Failed to open file: $e');
                }
              }
            }
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
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              exportChannelId,
              exportChannelName,
              description: exportChannelDescription,
              importance: Importance.high,
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

  String? _lastSchedulingError;
  String? get lastSchedulingError => _lastSchedulingError;
  bool get isInitialized => _isInitialized;

  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.areNotificationsEnabled() ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    try {
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.canScheduleExactNotifications() ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  Future<bool> requestPermissions() async {
    try {
      await initialize();
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final postNotifs = await androidImpl.requestNotificationsPermission();
          try {
            final canExact = await androidImpl.canScheduleExactNotifications();
            if (canExact != true) {
              await androidImpl.requestExactAlarmsPermission();
            }
          } catch (_) {}
          return postNotifs ?? false;
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

  /// Calculates the next valid occurrence for a reminder in device local time
  tz.TZDateTime calculateNextTrigger(Reminder reminder, tz.TZDateTime now) {
    final targetHour = reminder.time.hour;
    final targetMinute = reminder.time.minute;

    switch (reminder.frequency) {
      case ReminderFrequency.once:
        var trigger = tz.TZDateTime(
          tz.local,
          reminder.date.year,
          reminder.date.month,
          reminder.date.day,
          targetHour,
          targetMinute,
        );
        // If trigger is in the current minute (less than 60s behind current seconds),
        // adjust to now + 5s so it triggers immediately instead of being discarded as past.
        if (trigger.isBefore(now) && now.difference(trigger).inSeconds < 60) {
          trigger = now.add(const Duration(seconds: 5));
        }
        return trigger;

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
      } catch (_) {}

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDateTime = calculateNextTrigger(reminder, now);

      if (isTestMode) {
        return;
      }

      // If one-time or custom reminder is strictly in the past, do not schedule
      if ((reminder.frequency == ReminderFrequency.once || reminder.frequency == ReminderFrequency.custom) &&
          scheduledDateTime.isBefore(now)) {
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
        icon: 'ic_notification',
        color: AppColors.primary,
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

      _lastSchedulingError = null;

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
        try {
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
        } catch (e2) {
          debugPrint('NotificationService: Inexact failed, trying launcher icon fallback: $e2');
          const fallbackAndroidDetails = AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          );
          const fallbackDetails = NotificationDetails(
            android: fallbackAndroidDetails,
            iOS: darwinDetails,
          );
          await _notificationsPlugin.zonedSchedule(
            id,
            reminder.name,
            reminder.comment?.isNotEmpty == true ? reminder.comment : 'Reminder from Money Manager',
            scheduledDateTime,
            fallbackDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: matchComponents,
          );
          debugPrint('[REMINDER_SCHEDULED] (fallback launcher) id: ${reminder.id}, scheduleId: $id, trigger: $scheduledDateTime');
        }
      }
    } catch (e) {
      _lastSchedulingError = e.toString();
      if (kDebugMode) {
        debugPrint('NotificationService: Schedule reminder error: $e');
      }
      rethrow;
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Reschedule all error: $e');
      }
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    try {
      final id = getNotificationId(reminderId);
      if (isTestMode) {
        return;
      }
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Cancel reminder error: $e');
      }
    }
  }

  // --- RECURRING PAYMENT REMINDERS ---

  static int getRecurringNotificationId(String recurringId) {
    return getNotificationId('rec_$recurringId');
  }

  tz.TZDateTime? calculateNextRecurringTrigger(RecurringTransaction recurring, tz.TZDateTime now) {
    var execDate = recurring.nextExecutionDate;

    // Advance occurrence if the trigger time for this occurrence is already in the past
    int maxIterations = 36;
    while (maxIterations-- > 0) {
      if (recurring.endDate != null && execDate.isAfter(recurring.endDate!)) {
        return null;
      }

      final triggerDate = execDate.subtract(Duration(days: recurring.reminderLeadDays));
      final triggerTz = tz.TZDateTime(
        tz.local,
        triggerDate.year,
        triggerDate.month,
        triggerDate.day,
        9, // 9:00 AM local time
        0,
      );

      if (triggerTz.isAfter(now)) {
        return triggerTz;
      }

      // If this occurrence's reminder is in the past, advance to next occurrence
      final nextExec = recurring.calculateNextDate(execDate);
      if (nextExec.isAtSameMomentAs(execDate) || nextExec.isBefore(execDate)) {
        break;
      }
      execDate = nextExec;
    }
    return null;
  }

  Future<void> scheduleRecurringReminder(RecurringTransaction recurring) async {
    if (!recurring.remindMe || !recurring.isActive) {
      await cancelRecurringReminder(recurring.id);
      return;
    }

    try {
      await initialize();
      final id = getRecurringNotificationId(recurring.id);

      // Cancel previous notification if any to prevent duplicates
      try {
        await _notificationsPlugin.cancel(id);
      } catch (_) {}

      if (isTestMode) {
        return;
      }

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDateTime = calculateNextRecurringTrigger(recurring, now);

      if (scheduledDateTime == null) {
        return;
      }

      final title = 'Recurring Payment Due';
      final leadDays = recurring.reminderLeadDays;
      final desc = recurring.description.isNotEmpty ? recurring.description : 'payment';

      String body;
      if (leadDays == 0) {
        body = 'Your scheduled $desc is due today.';
      } else if (leadDays == 1) {
        body = 'Your scheduled $desc is due tomorrow.';
      } else {
        body = 'Your scheduled $desc is due in $leadDays days.';
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'ic_notification',
        color: AppColors.primary,
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
          title,
          body,
          scheduledDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('[RECURRING_REMINDER_SCHEDULED] (exact) id: ${recurring.id}, scheduleId: $id, trigger: $scheduledDateTime');
      } catch (e) {
        debugPrint('NotificationService: Exact alarm fallback to inexact: $e');
        try {
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDateTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
          debugPrint('[RECURRING_REMINDER_SCHEDULED] (inexact) id: ${recurring.id}, scheduleId: $id, trigger: $scheduledDateTime');
        } catch (e2) {
          debugPrint('NotificationService: Inexact failed, trying launcher icon fallback: $e2');
          const fallbackAndroidDetails = AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          );
          const fallbackDetails = NotificationDetails(
            android: fallbackAndroidDetails,
            iOS: darwinDetails,
          );
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDateTime,
            fallbackDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
          debugPrint('[RECURRING_REMINDER_SCHEDULED] (fallback launcher) id: ${recurring.id}, scheduleId: $id, trigger: $scheduledDateTime');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Schedule recurring reminder error: $e');
      }
    }
  }

  Future<void> cancelRecurringReminder(String recurringId) async {
    try {
      final id = getRecurringNotificationId(recurringId);
      if (isTestMode) return;
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Cancel recurring reminder error: $e');
      }
    }
  }

  Future<void> rescheduleAllRecurringReminders(List<RecurringTransaction> recurringList) async {
    try {
      await initialize();
      for (final rec in recurringList) {
        if (rec.remindMe && rec.isActive) {
          await scheduleRecurringReminder(rec);
        } else {
          await cancelRecurringReminder(rec.id);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Reschedule all recurring error: $e');
      }
    }
  }

  Future<void> showExportNotification({
    required String title,
    required String body,
    bool isSuccess = true,
    String? filePath,
  }) async {
    if (isTestMode) return;
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      exportChannelId,
      exportChannelName,
      channelDescription: exportChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'ic_notification',
      color: AppColors.primary,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        99901,
        title,
        body,
        details,
        payload: filePath,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Failed to display export notification with ic_notification: $e, retrying with launcher icon');
      }
      try {
        final fallbackDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            exportChannelId,
            exportChannelName,
            channelDescription: exportChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: darwinDetails,
        );
        await _notificationsPlugin.show(
          99901,
          title,
          body,
          fallbackDetails,
          payload: filePath,
        );
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('NotificationService: Failed export notification fallback: $e2');
        }
      }
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
