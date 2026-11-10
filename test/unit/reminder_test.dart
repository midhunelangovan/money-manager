import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/features/reminders/data/repositories/reminder_repository.dart';
import 'package:kals_money_manager/features/reminders/domain/entities/reminder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('Reminder Entity & Serialization Tests', () {
    test('Reminder serializes toMap and deserializes fromMap accurately', () {
      final now = DateTime(2026, 10, 1, 10, 0);
      final reminder = Reminder(
        id: 'rem_123',
        name: 'Drink Water',
        frequency: ReminderFrequency.daily,
        date: DateTime(2026, 10, 1),
        time: const TimeOfDay(hour: 10, minute: 30),
        comment: 'Stay hydrated',
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = reminder.toMap();
      expect(map['id'], 'rem_123');
      expect(map['name'], 'Drink Water');
      expect(map['frequency'], 'daily');
      expect(map['time'], '10:30');
      expect(map['comment'], 'Stay hydrated');
      expect(map['is_enabled'], 1);

      final restored = Reminder.fromMap(map);
      expect(restored.id, reminder.id);
      expect(restored.name, reminder.name);
      expect(restored.frequency, ReminderFrequency.daily);
      expect(restored.time.hour, 10);
      expect(restored.time.minute, 30);
      expect(restored.comment, 'Stay hydrated');
      expect(restored.isEnabled, true);
    });

    test('Reminder copyWith works correctly', () {
      final now = DateTime(2026, 10, 1, 10, 0);
      final reminder = Reminder(
        id: 'rem_1',
        name: 'Pay Rent',
        frequency: ReminderFrequency.monthly,
        date: DateTime(2026, 10, 1),
        time: const TimeOfDay(hour: 9, minute: 0),
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final toggled = reminder.copyWith(isEnabled: false);
      expect(toggled.isEnabled, false);
      expect(toggled.name, 'Pay Rent');
      expect(toggled.frequency, ReminderFrequency.monthly);
    });

    test('ReminderFrequency displayName and parsing', () {
      expect(ReminderFrequency.fromString('once'), ReminderFrequency.once);
      expect(ReminderFrequency.fromString('daily'), ReminderFrequency.daily);
      expect(ReminderFrequency.fromString('weekly'), ReminderFrequency.weekly);
      expect(ReminderFrequency.fromString('monthly'), ReminderFrequency.monthly);
      expect(ReminderFrequency.fromString('yearly'), ReminderFrequency.yearly);
      expect(ReminderFrequency.fromString('custom'), ReminderFrequency.custom);

      expect(ReminderFrequency.daily.displayName, 'Every day');
      expect(ReminderFrequency.daily.shortName, 'Daily');
      expect(ReminderFrequency.weekly.displayName, 'Every week');
      expect(ReminderFrequency.monthly.displayName, 'Every month');
      expect(ReminderFrequency.yearly.displayName, 'Every year');
    });
  });

  group('Reminder Database Repository Persistence Tests', () {
    late Database db;
    late AppDatabase appDb;
    late ReminderRepository reminderRepo;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: DatabaseMigrations.onCreate,
      );
      appDb = AppDatabase.withDatabase(db);
      reminderRepo = ReminderRepository(db: appDb);
    });

    tearDown(() async {
      await db.close();
    });

    test('Insert, fetch by ID, update, toggle and delete lifecycle in SQLite', () async {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'rem_db_test_1',
        name: 'Car Insurance Due',
        frequency: ReminderFrequency.yearly,
        date: DateTime(2026, 11, 20),
        time: const TimeOfDay(hour: 15, minute: 45),
        comment: 'Policy #998811',
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Insert
      await reminderRepo.insertReminder(reminder);

      // 2. Fetch all
      final all = await reminderRepo.getAllReminders();
      expect(all.length, 1);
      expect(all.first.id, 'rem_db_test_1');
      expect(all.first.name, 'Car Insurance Due');
      expect(all.first.frequency, ReminderFrequency.yearly);
      expect(all.first.time.hour, 15);
      expect(all.first.time.minute, 45);
      expect(all.first.comment, 'Policy #998811');
      expect(all.first.isEnabled, true);

      // 3. Update
      final updated = all.first.copyWith(
        name: 'Car Insurance Renewed',
        isEnabled: false,
        updatedAt: DateTime.now(),
      );
      await reminderRepo.updateReminder(updated);

      final fetchedUpdated = await reminderRepo.getReminderById('rem_db_test_1');
      expect(fetchedUpdated, isNotNull);
      expect(fetchedUpdated!.name, 'Car Insurance Renewed');
      expect(fetchedUpdated.isEnabled, false);

      // 4. Delete
      await reminderRepo.deleteReminder('rem_db_test_1');
      final afterDelete = await reminderRepo.getAllReminders();
      expect(afterDelete.isEmpty, true);
    });
  });

  group('Reminder Notification Trigger Calculation & Frequency Matrix', () {
    final notificationService = NotificationService();

    test('Daily reminder: Schedules for today if time is future, tomorrow if passed', () {
      final now = tz.TZDateTime(tz.local, 2026, 10, 15, 12, 0); // 12:00 PM

      // Future today (21:30)
      final dailyFuture = Reminder(
        id: 'daily_1',
        name: 'Add payments',
        frequency: ReminderFrequency.daily,
        date: DateTime(2026, 10, 15),
        time: const TimeOfDay(hour: 21, minute: 30),
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
      );
      final nextFuture = notificationService.calculateNextTrigger(dailyFuture, now);
      expect(nextFuture.year, 2026);
      expect(nextFuture.month, 10);
      expect(nextFuture.day, 15);
      expect(nextFuture.hour, 21);
      expect(nextFuture.minute, 30);

      // Passed today (09:00) -> Schedules for tomorrow
      final dailyPassed = Reminder(
        id: 'daily_2',
        name: 'Morning routine',
        frequency: ReminderFrequency.daily,
        date: DateTime(2026, 10, 15),
        time: const TimeOfDay(hour: 9, minute: 0),
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
      );
      final nextTomorrow = notificationService.calculateNextTrigger(dailyPassed, now);
      expect(nextTomorrow.year, 2026);
      expect(nextTomorrow.month, 10);
      expect(nextTomorrow.day, 16);
      expect(nextTomorrow.hour, 9);
      expect(nextTomorrow.minute, 0);
    });

    test('Weekly reminder: Fires on the exact selected weekday (e.g. Every Monday)', () {
      // Thursday, Oct 15, 2026 (weekday = 4)
      final now = tz.TZDateTime(tz.local, 2026, 10, 15, 12, 0);

      // Target Monday (weekday = 1) -> Should schedule for Monday Oct 19, 2026
      final weeklyMonday = Reminder(
        id: 'weekly_mon',
        name: 'Weekly review',
        frequency: ReminderFrequency.weekly,
        date: DateTime(2026, 10, 19), // A Monday
        time: const TimeOfDay(hour: 21, minute: 30),
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
      );
      final nextMon = notificationService.calculateNextTrigger(weeklyMonday, now);
      expect(nextMon.weekday, DateTime.monday);
      expect(nextMon.day, 19);
      expect(nextMon.hour, 21);
      expect(nextMon.minute, 30);
    });

    test('Monthly reminder: Handles 29th, 30th, 31st with month-end clamping', () {
      // Jan 31, 2026 at 22:00 -> passed 21:30 time for today
      final nowJan31Passed = tz.TZDateTime(tz.local, 2026, 1, 31, 22, 0);

      final monthly31 = Reminder(
        id: 'monthly_31',
        name: 'End of month audit',
        frequency: ReminderFrequency.monthly,
        date: DateTime(2026, 1, 31),
        time: const TimeOfDay(hour: 21, minute: 30),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Next occurrence after Jan 31 is in February (which only has 28 days in 2026)
      final nextFeb = notificationService.calculateNextTrigger(monthly31, nowJan31Passed);
      expect(nextFeb.year, 2026);
      expect(nextFeb.month, 2);
      expect(nextFeb.day, 28); // Clamped to Feb 28
      expect(nextFeb.hour, 21);
      expect(nextFeb.minute, 30);
    });

    test('Once reminder: Schedules exact date and time', () {
      final now = tz.TZDateTime(tz.local, 2026, 10, 1, 10, 0);
      final onceRem = Reminder(
        id: 'once_target',
        name: 'Dentist Appointment',
        frequency: ReminderFrequency.once,
        date: DateTime(2026, 10, 28),
        time: const TimeOfDay(hour: 14, minute: 15),
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final next = notificationService.calculateNextTrigger(onceRem, now);
      expect(next.year, 2026);
      expect(next.month, 10);
      expect(next.day, 28);
      expect(next.hour, 14);
      expect(next.minute, 15);
    });

    test('NotificationService.getNotificationId produces deterministic positive 31-bit integer hash', () {
      const id1 = 'reminder-uuid-abc-123';
      const id2 = 'reminder-uuid-abc-123';
      const id3 = 'reminder-uuid-xyz-789';

      final hash1 = NotificationService.getNotificationId(id1);
      final hash2 = NotificationService.getNotificationId(id2);
      final hash3 = NotificationService.getNotificationId(id3);

      expect(hash1, hash2);
      expect(hash1, isPositive);
      expect(hash1 <= 0x7FFFFFFF, true);
      expect(hash1 != hash3, true);
    });

    test('Edit reminder retains same stable ID and produces same deterministic notification ID', () {
      final now = DateTime.now();
      final original = Reminder(
        id: 'stable_rem_id_55',
        name: 'Electric Bill',
        frequency: ReminderFrequency.once,
        date: DateTime(2026, 10, 5),
        time: const TimeOfDay(hour: 10, minute: 0),
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final edited = original.copyWith(
        time: const TimeOfDay(hour: 10, minute: 30),
        name: 'Electric Bill (Updated)',
        updatedAt: DateTime.now(),
      );

      expect(edited.id, original.id);
      expect(
        NotificationService.getNotificationId(edited.id),
        NotificationService.getNotificationId(original.id),
      );
    });
  });
}
