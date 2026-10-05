import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/recurring/domain/entities/recurring_transaction.dart';

void main() {
  group('Recurring Date Calculation Tests', () {
    test('Daily frequency advances by interval days', () {
      final schedule = RecurringTransaction(
        id: '1',
        transactionType: CategoryType.expense,
        accountId: 'acc1',
        categoryId: 'cat1',
        amount: const Money(units: 5000),
        description: 'Daily Milk',
        frequency: RecurringFrequency.daily,
        interval: 2,
        startDate: DateTime(2026, 1, 1),
        nextExecutionDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final next = schedule.calculateNextDate(DateTime(2026, 1, 1));
      expect(next, equals(DateTime(2026, 1, 3)));
    });

    test('Monthly frequency preserves day and handles rollover', () {
      final schedule = RecurringTransaction(
        id: '1',
        transactionType: CategoryType.expense,
        accountId: 'acc1',
        categoryId: 'cat1',
        amount: const Money(units: 100000),
        description: 'SIP',
        frequency: RecurringFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 15),
        nextExecutionDate: DateTime(2026, 1, 15),
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      );

      final feb = schedule.calculateNextDate(DateTime(2026, 1, 15));
      expect(feb.year, equals(2026));
      expect(feb.month, equals(2));
      expect(feb.day, equals(15));

      final dec = schedule.calculateNextDate(DateTime(2026, 11, 15));
      expect(dec.month, equals(12));

      final nextYear = schedule.calculateNextDate(DateTime(2026, 12, 15));
      expect(nextYear.year, equals(2027));
      expect(nextYear.month, equals(1));
    });

    test('Monthly frequency caps at end-of-month for shorter months', () {
      final schedule = RecurringTransaction(
        id: '1',
        transactionType: CategoryType.expense,
        accountId: 'acc1',
        categoryId: 'cat1',
        amount: const Money(units: 10000),
        description: 'Bill',
        frequency: RecurringFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 31),
        nextExecutionDate: DateTime(2026, 1, 31),
        createdAt: DateTime(2026, 1, 31),
        updatedAt: DateTime(2026, 1, 31),
      );

      // Feb in 2026 has 28 days
      final feb = schedule.calculateNextDate(DateTime(2026, 1, 31));
      expect(feb.month, equals(2));
      expect(feb.day, equals(28));
    });
  });
}
