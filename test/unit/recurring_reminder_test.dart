import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/recurring/data/models/recurring_transaction_model.dart';
import 'package:kals_money_manager/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('Recurring Payment Reminder Model Serialization Tests', () {
    test('Entity and Model serialization preserves remindMe and reminderLeadDays', () {
      final now = DateTime(2026, 10, 12, 10, 0);
      final recurring = RecurringTransaction(
        id: 'rec_test_1',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        amount: Money(units: 1500000), // 15,000.00
        description: 'House Rent',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextExecutionDate: DateTime(2026, 11, 1),
        isActive: true,
        remindMe: true,
        reminderLeadDays: 3,
        createdAt: now,
        updatedAt: now,
      );

      final model = RecurringTransactionModel.fromEntity(recurring);
      expect(model.remindMe, true);
      expect(model.reminderLeadDays, 3);

      final map = model.toMap();
      expect(map['remind_me'], 1);
      expect(map['reminder_lead_days'], 3);

      final fromMap = RecurringTransactionModel.fromMap(map);
      expect(fromMap.id, 'rec_test_1');
      expect(fromMap.remindMe, true);
      expect(fromMap.reminderLeadDays, 3);
      expect(fromMap.amount.units, 1500000);
      expect(fromMap.description, 'House Rent');
    });

    test('Defaults to false and 0 lead days when missing in database map', () {
      final map = {
        'id': 'rec_legacy',
        'transaction_type': 'EXPENSE',
        'account_id': 'acc_1',
        'category_id': 'cat_1',
        'amount': 50000,
        'description': 'Wifi Bill',
        'frequency': 'MONTHLY',
        'interval': 1,
        'start_date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'next_execution_date': DateTime(2026, 11, 1).millisecondsSinceEpoch,
        'is_active': 1,
        'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'updated_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      };

      final fromMap = RecurringTransactionModel.fromMap(map);
      expect(fromMap.remindMe, false);
      expect(fromMap.reminderLeadDays, 0);
    });
  });

  group('Recurring Notification ID Determinism Tests', () {
    test('Recurring notification IDs are deterministic and distinct from normal reminders', () {
      const recId = 'recurring_payment_42';
      final nId1 = NotificationService.getRecurringNotificationId(recId);
      final nId2 = NotificationService.getRecurringNotificationId(recId);
      final normalReminderId = NotificationService.getNotificationId(recId);

      expect(nId1, nId2, reason: 'Must produce identical ID on subsequent calls');
      expect(nId1 != normalReminderId, true, reason: 'Prefix rec_ isolates from standard reminders');
      expect(nId1 > 0, true);
      expect(nId1 <= 0x7FFFFFFF, true);
    });
  });

  group('NotificationService calculateNextRecurringTrigger Tests', () {
    final notificationService = NotificationService();

    test('Triggers at 9:00 AM on due date when leadDays == 0', () {
      final recurring = RecurringTransaction(
        id: 'rec_test_0d',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        amount: Money(units: 100000),
        description: 'Internet Bill',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextExecutionDate: DateTime(2026, 10, 20),
        isActive: true,
        remindMe: true,
        reminderLeadDays: 0,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final now = tz.TZDateTime(tz.local, 2026, 10, 12, 12, 0);
      final trigger = notificationService.calculateNextRecurringTrigger(recurring, now);

      expect(trigger, isNotNull);
      expect(trigger!.year, 2026);
      expect(trigger.month, 10);
      expect(trigger.day, 20);
      expect(trigger.hour, 9);
      expect(trigger.minute, 0);
    });

    test('Triggers 1 day before due date when leadDays == 1', () {
      final recurring = RecurringTransaction(
        id: 'rec_test_1d',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        amount: Money(units: 100000),
        description: 'Phone Recharge',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextExecutionDate: DateTime(2026, 10, 20),
        isActive: true,
        remindMe: true,
        reminderLeadDays: 1,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final now = tz.TZDateTime(tz.local, 2026, 10, 12, 12, 0);
      final trigger = notificationService.calculateNextRecurringTrigger(recurring, now);

      expect(trigger, isNotNull);
      expect(trigger!.year, 2026);
      expect(trigger.month, 10);
      expect(trigger.day, 19); // 1 day before Oct 20
      expect(trigger.hour, 9);
      expect(trigger.minute, 0);
    });

    test('Triggers 3 days before due date when leadDays == 3', () {
      final recurring = RecurringTransaction(
        id: 'rec_test_3d',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        amount: Money(units: 100000),
        description: 'House Rent',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextExecutionDate: DateTime(2026, 10, 20),
        isActive: true,
        remindMe: true,
        reminderLeadDays: 3,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final now = tz.TZDateTime(tz.local, 2026, 10, 12, 12, 0);
      final trigger = notificationService.calculateNextRecurringTrigger(recurring, now);

      expect(trigger, isNotNull);
      expect(trigger!.year, 2026);
      expect(trigger.month, 10);
      expect(trigger.day, 17); // 3 days before Oct 20
      expect(trigger.hour, 9);
      expect(trigger.minute, 0);
    });

    test('Triggers 7 days before due date when leadDays == 7 across month boundary', () {
      final recurring = RecurringTransaction(
        id: 'rec_test_7d',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        amount: Money(units: 100000),
        description: 'Car EMI',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextExecutionDate: DateTime(2026, 11, 4),
        isActive: true,
        remindMe: true,
        reminderLeadDays: 7,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final now = tz.TZDateTime(tz.local, 2026, 10, 12, 12, 0);
      final trigger = notificationService.calculateNextRecurringTrigger(recurring, now);

      expect(trigger, isNotNull);
      expect(trigger!.year, 2026);
      expect(trigger.month, 10);
      expect(trigger.day, 28); // Nov 4 minus 7 days = Oct 28 (October has 31 days)
      expect(trigger.hour, 9);
      expect(trigger.minute, 0);
    });

    test('Advances to next occurrence safely if current occurrence trigger has already passed', () {
      final recurring = RecurringTransaction(
        id: 'rec_missed_test',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        amount: Money(units: 100000),
        description: 'Quarterly Subscription',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 10, 5),
        nextExecutionDate: DateTime(2026, 10, 5), // Already in the past!
        isActive: true,
        remindMe: true,
        reminderLeadDays: 1,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      // Current time is Oct 12 (past Oct 5)
      final now = tz.TZDateTime(tz.local, 2026, 10, 12, 12, 0);
      final trigger = notificationService.calculateNextRecurringTrigger(recurring, now);

      expect(trigger, isNotNull);
      expect(trigger!.year, 2026);
      expect(trigger.month, 11);
      expect(trigger.day, 4); // 1 day before Nov 5
      expect(trigger.hour, 9);
      expect(trigger.minute, 0);
    });

    test('Returns null if expired and no future occurrences exist', () {
      final recurring = RecurringTransaction(
        id: 'rec_expired',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        amount: Money(units: 100000),
        description: 'One Year Contract',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 10, 1), // Ended!
        nextExecutionDate: DateTime(2026, 10, 1),
        isActive: true,
        remindMe: true,
        reminderLeadDays: 1,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final now = tz.TZDateTime(tz.local, 2026, 10, 12, 12, 0);
      final trigger = notificationService.calculateNextRecurringTrigger(recurring, now);

      expect(trigger, isNull);
    });
  });
}
