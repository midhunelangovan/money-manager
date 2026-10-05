import 'package:flutter/material.dart';

enum ReminderFrequency {
  once,
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  String get displayName {
    switch (this) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Every day';
      case ReminderFrequency.weekly:
        return 'Every week';
      case ReminderFrequency.monthly:
        return 'Every month';
      case ReminderFrequency.yearly:
        return 'Every year';
      case ReminderFrequency.custom:
        return 'Custom';
    }
  }

  String get shortName {
    switch (this) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
      case ReminderFrequency.yearly:
        return 'Yearly';
      case ReminderFrequency.custom:
        return 'Custom';
    }
  }

  static ReminderFrequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
      case 'every day':
        return ReminderFrequency.daily;
      case 'weekly':
      case 'every week':
        return ReminderFrequency.weekly;
      case 'monthly':
      case 'every month':
        return ReminderFrequency.monthly;
      case 'yearly':
      case 'every year':
        return ReminderFrequency.yearly;
      case 'custom':
        return ReminderFrequency.custom;
      case 'once':
      default:
        return ReminderFrequency.once;
    }
  }
}

class Reminder {
  final String id;
  final String name;
  final ReminderFrequency frequency;
  final DateTime date;
  final TimeOfDay time;
  final String? comment;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.name,
    required this.frequency,
    required this.date,
    required this.time,
    this.comment,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Reminder copyWith({
    String? id,
    String? name,
    ReminderFrequency? frequency,
    DateTime? date,
    TimeOfDay? time,
    String? comment,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      date: date ?? this.date,
      time: time ?? this.time,
      comment: comment ?? this.comment,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency.name,
      'date': date.toIso8601String(),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'comment': comment,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    TimeOfDay parsedTime = const TimeOfDay(hour: 9, minute: 0);
    if (map['time'] != null && (map['time'] as String).contains(':')) {
      final parts = (map['time'] as String).split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      parsedTime = TimeOfDay(hour: hour, minute: minute);
    }

    DateTime parsedDate = DateTime.now();
    if (map['date'] != null) {
      if (map['date'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
      } else {
        parsedDate = DateTime.tryParse(map['date'] as String) ?? DateTime.now();
      }
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (map['created_at'] != null) {
      if (map['created_at'] is int) {
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int);
      } else {
        parsedCreatedAt = DateTime.tryParse(map['created_at'] as String) ?? DateTime.now();
      }
    }

    DateTime parsedUpdatedAt = DateTime.now();
    if (map['updated_at'] != null) {
      if (map['updated_at'] is int) {
        parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int);
      } else {
        parsedUpdatedAt = DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now();
      }
    }

    return Reminder(
      id: map['id'] as String,
      name: map['name'] as String,
      frequency: ReminderFrequency.fromString(map['frequency'] as String? ?? 'once'),
      date: parsedDate,
      time: parsedTime,
      comment: map['comment'] as String?,
      isEnabled: (map['is_enabled'] is int) ? (map['is_enabled'] as int) == 1 : (map['is_enabled'] as bool? ?? true),
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }
}
