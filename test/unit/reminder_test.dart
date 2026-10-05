import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/features/reminders/domain/entities/reminder.dart';

void main() {
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
}
