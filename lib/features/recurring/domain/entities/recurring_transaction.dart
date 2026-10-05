import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
      case RecurringFrequency.custom:
        return 'Custom';
    }
  }

  static RecurringFrequency fromString(String val) {
    switch (val.toUpperCase()) {
      case 'DAILY':
        return RecurringFrequency.daily;
      case 'WEEKLY':
        return RecurringFrequency.weekly;
      case 'MONTHLY':
        return RecurringFrequency.monthly;
      case 'YEARLY':
        return RecurringFrequency.yearly;
      default:
        return RecurringFrequency.custom;
    }
  }

  String toDbString() {
    switch (this) {
      case RecurringFrequency.daily:
        return 'DAILY';
      case RecurringFrequency.weekly:
        return 'WEEKLY';
      case RecurringFrequency.monthly:
        return 'MONTHLY';
      case RecurringFrequency.yearly:
        return 'YEARLY';
      case RecurringFrequency.custom:
        return 'CUSTOM';
    }
  }
}

class RecurringTransaction {
  final String id;
  final CategoryType transactionType; // INCOME or EXPENSE
  final String accountId;
  final String categoryId;
  final Money amount;
  final String description;
  final RecurringFrequency frequency;
  final int interval; // e.g. 1 (every 1 month)
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextExecutionDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined display properties
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;

  const RecurringTransaction({
    required this.id,
    required this.transactionType,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    required this.nextExecutionDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  RecurringTransaction copyWith({
    String? id,
    CategoryType? transactionType,
    String? accountId,
    String? categoryId,
    Money? amount,
    String? description,
    RecurringFrequency? frequency,
    int? interval,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextExecutionDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountName,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      transactionType: transactionType ?? this.transactionType,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  /// Calculates the next occurrence date after a given date
  DateTime calculateNextDate(DateTime fromDate) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return fromDate.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        return fromDate.add(Duration(days: 7 * interval));
      case RecurringFrequency.monthly:
        // Safe month rollover
        var nextYear = fromDate.year;
        var nextMonth = fromDate.month + interval;
        while (nextMonth > 12) {
          nextYear++;
          nextMonth -= 12;
        }
        final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
        final targetDay = startDate.day <= maxDay ? startDate.day : maxDay;
        return DateTime(nextYear, nextMonth, targetDay, fromDate.hour, fromDate.minute);
      case RecurringFrequency.yearly:
        final nextYear = fromDate.year + interval;
        final isLeap = (nextYear % 4 == 0 && nextYear % 100 != 0) || (nextYear % 400 == 0);
        var targetDay = startDate.day;
        if (startDate.month == 2 && startDate.day == 29 && !isLeap) {
          targetDay = 28;
        }
        return DateTime(nextYear, startDate.month, targetDay, fromDate.hour, fromDate.minute);
      case RecurringFrequency.custom:
        return fromDate.add(Duration(days: interval));
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
