import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/features/reminders/data/repositories/reminder_repository.dart';
import 'package:kals_money_manager/features/reminders/domain/entities/reminder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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
}
