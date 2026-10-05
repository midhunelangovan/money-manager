import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/features/reminders/domain/entities/reminder.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('Reminder calculateNextTrigger Edge Case Tests', () {
    final notificationService = NotificationService();

    test('One-time reminder returns exact scheduled time', () {
      final reminder = Reminder(
        id: 'r_once',
        name: 'Electricity Bill',
        frequency: ReminderFrequency.once,
        date: DateTime(2026, 10, 15),
        time: const TimeOfDay(hour: 9, minute: 0),
        isEnabled: true,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final now = tz.TZDateTime(tz.local, 2026, 10, 5, 8, 0);
      final trigger = notificationService.calculateNextTrigger(reminder, now);

      expect(trigger.year, 2026);
      expect(trigger.month, 10);
      expect(trigger.day, 15);
      expect(trigger.hour, 9);
      expect(trigger.minute, 0);
    });

    test('Daily reminder schedules today if before time, tomorrow if after time', () {
      final reminder = Reminder(
        id: 'r_daily',
        name: 'Take Vitamin',
        frequency: ReminderFrequency.daily,
        date: DateTime(2026, 10, 1),
        time: const TimeOfDay(hour: 9, minute: 0),
        isEnabled: true,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      // 1. Current time is 08:30 (before 09:00) -> Should schedule for today 09:00
      final beforeTime = tz.TZDateTime(tz.local, 2026, 10, 5, 8, 30);
      final triggerToday = notificationService.calculateNextTrigger(reminder, beforeTime);
      expect(triggerToday.day, 5);
      expect(triggerToday.hour, 9);
      expect(triggerToday.minute, 0);

      // 2. Current time is 09:30 (after 09:00) -> Should schedule for tomorrow (Oct 6) 09:00
      final afterTime = tz.TZDateTime(tz.local, 2026, 10, 5, 9, 30);
      final triggerTomorrow = notificationService.calculateNextTrigger(reminder, afterTime);
      expect(triggerTomorrow.day, 6);
      expect(triggerTomorrow.hour, 9);
      expect(triggerTomorrow.minute, 0);
    });

    test('Weekly reminder schedules on correct weekday', () {
      // Oct 5, 2026 is Monday (weekday = 1)
      // Reminder is set for Wednesday (Oct 7, weekday = 3)
      final reminder = Reminder(
        id: 'r_weekly',
        name: 'Team Review',
        frequency: ReminderFrequency.weekly,
        date: DateTime(2026, 10, 7), // Wednesday
        time: const TimeOfDay(hour: 14, minute: 0),
        isEnabled: true,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final monday = tz.TZDateTime(tz.local, 2026, 10, 5, 10, 0);
      final triggerNextWed = notificationService.calculateNextTrigger(reminder, monday);
      expect(triggerNextWed.weekday, DateTime.wednesday);
      expect(triggerNextWed.day, 7);
      expect(triggerNextWed.hour, 14);

      // If called on Wednesday at 15:00 (after 14:00), should schedule for next Wednesday (Oct 14)
      final wedAfternoon = tz.TZDateTime(tz.local, 2026, 10, 7, 15, 0);
      final triggerFollowingWed = notificationService.calculateNextTrigger(reminder, wedAfternoon);
      expect(triggerFollowingWed.weekday, DateTime.wednesday);
      expect(triggerFollowingWed.day, 14);
      expect(triggerFollowingWed.hour, 14);
    });

    test('Monthly reminder clamps 31st to 30 for 30-day months and 28/29 for February', () {
      final reminder = Reminder(
        id: 'r_monthly_31',
        name: 'End of month savings',
        frequency: ReminderFrequency.monthly,
        date: DateTime(2026, 1, 31),
        time: const TimeOfDay(hour: 18, minute: 0),
        isEnabled: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // In February 2026 (non-leap year, 28 days)
      final feb = tz.TZDateTime(tz.local, 2026, 2, 1, 10, 0);
      final triggerFeb = notificationService.calculateNextTrigger(reminder, feb);
      expect(triggerFeb.month, 2);
      expect(triggerFeb.day, 28);
      expect(triggerFeb.hour, 18);

      // In April 2026 (30 days)
      final apr = tz.TZDateTime(tz.local, 2026, 4, 1, 10, 0);
      final triggerApr = notificationService.calculateNextTrigger(reminder, apr);
      expect(triggerApr.month, 4);
      expect(triggerApr.day, 30);
      expect(triggerApr.hour, 18);

      // In December 2026 after trigger time -> roll over to January 2027 31st
      final decAfter = tz.TZDateTime(tz.local, 2026, 12, 31, 19, 0);
      final triggerJan = notificationService.calculateNextTrigger(reminder, decAfter);
      expect(triggerJan.year, 2027);
      expect(triggerJan.month, 1);
      expect(triggerJan.day, 31);
    });

    test('Yearly reminder handles February 29 on leap years and non-leap years', () {
      final reminder = Reminder(
        id: 'r_leap',
        name: 'Leap Year Celebration',
        frequency: ReminderFrequency.yearly,
        date: DateTime(2024, 2, 29), // 2024 was leap year
        time: const TimeOfDay(hour: 12, minute: 0),
        isEnabled: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      // In 2026 (non-leap year), target should clamp to Feb 28
      final now2026 = tz.TZDateTime(tz.local, 2026, 1, 15, 10, 0);
      final trigger2026 = notificationService.calculateNextTrigger(reminder, now2026);
      expect(trigger2026.year, 2026);
      expect(trigger2026.month, 2);
      expect(trigger2026.day, 28);

      // In 2028 (leap year), target should be Feb 29
      final now2028 = tz.TZDateTime(tz.local, 2028, 1, 15, 10, 0);
      final trigger2028 = notificationService.calculateNextTrigger(reminder, now2028);
      expect(trigger2028.year, 2028);
      expect(trigger2028.month, 2);
      expect(trigger2028.day, 29);
    });
  });
}
