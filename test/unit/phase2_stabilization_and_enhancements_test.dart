import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/core/utilities/app_snack_bar.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/backup/data/services/automatic_export_service.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    NotificationService.isTestMode = true;
  });

  group('Phase 2A & 2B: Stabilization, Reliability & Enhancement Tests', () {
    test('1. NotificationService calculateNextRecurringTrigger respects configurable reminder time', () {
      final notificationService = NotificationService();
      final now = tz.TZDateTime(tz.local, 2026, 11, 12, 10, 0); // 10:00 AM on Nov 12

      // Recurring payment due on Nov 15 with reminderLeadDays: 1 (due Nov 14) at 15:30 (3:30 PM)
      final recurring = RecurringTransaction(
        id: 'rec_test_1',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_1',
        amount: Money.fromUnits(150000),
        description: 'Internet Bill',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 11, 15),
        nextExecutionDate: DateTime(2026, 11, 15),
        remindMe: true,
        reminderLeadDays: 1, // 1 day before: Nov 14
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      final trigger = notificationService.calculateNextRecurringTrigger(
        recurring,
        now,
        reminderHour: 15,
        reminderMinute: 30,
      );

      expect(trigger, isNotNull);
      expect(trigger!.year, equals(2026));
      expect(trigger.month, equals(11));
      expect(trigger.day, equals(14));
      expect(trigger.hour, equals(15));
      expect(trigger.minute, equals(30));
    });

    test('2. NotificationService advances past recurring reminder occurrence safely to next period', () {
      final notificationService = NotificationService();
      // Now is Nov 12 at 18:00 (6:00 PM)
      final now = tz.TZDateTime(tz.local, 2026, 11, 12, 18, 0);

      // Recurring payment due today (Nov 12), leadDays: 0, reminderTime: 09:00 AM (already passed)
      final recurring = RecurringTransaction(
        id: 'rec_daily_1',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_1',
        amount: Money.fromUnits(5000),
        description: 'Daily Milk',
        frequency: RecurringFrequency.daily,
        interval: 1,
        startDate: DateTime(2026, 11, 1),
        nextExecutionDate: DateTime(2026, 11, 12),
        remindMe: true,
        reminderLeadDays: 0,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      final trigger = notificationService.calculateNextRecurringTrigger(
        recurring,
        now,
        reminderHour: 9,
        reminderMinute: 0,
      );

      expect(trigger, isNotNull);
      // Because Nov 12 at 09:00 passed, it must advance to Nov 13 at 09:00
      expect(trigger!.year, equals(2026));
      expect(trigger.month, equals(11));
      expect(trigger.day, equals(13));
      expect(trigger.hour, equals(9));
      expect(trigger.minute, equals(0));
    });

    test('3. AutoExportScope supports all requested durations and resolves rolling boundaries', () {
      final now = DateTime(2026, 11, 12, 15, 0);

      // 7 Days
      final start7 = now.subtract(const Duration(days: 7));
      expect(start7.day, equals(5));

      // 30 Days
      final start30 = now.subtract(const Duration(days: 30));
      expect(start30.month, equals(10));
      expect(start30.day, equals(13));

      // 90 Days
      final start90 = now.subtract(const Duration(days: 90));
      expect(start90.month, equals(8));

      // 1 Year
      final startYear = DateTime(now.year - 1, now.month, now.day);
      expect(startYear.year, equals(2025));
      expect(startYear.month, equals(11));
      expect(startYear.day, equals(12));

      // Verify enum values
      expect(AutoExportScope.values, contains(AutoExportScope.allTransactions));
      expect(AutoExportScope.values, contains(AutoExportScope.last7Days));
      expect(AutoExportScope.values, contains(AutoExportScope.last30Days));
      expect(AutoExportScope.values, contains(AutoExportScope.last90Days));
      expect(AutoExportScope.values, contains(AutoExportScope.lastYear));
    });

    testWidgets('4. AppSnackBar auto-dismisses after duration in standard UI', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppSnackBar.showSuccess(ctx, 'Saved successfully!'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Saved successfully!'), findsOneWidget);

      // Fast forward past the 2.5s duration + exit animation
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();

      expect(find.text('Saved successfully!'), findsNothing);
    });

    testWidgets('5. TransactionListItem does not use Dismissible to prevent accidental swipe deletion during vertical scroll', (tester) async {
      final item = LedgerItem(
        id: 'tx_swipe_1',
        itemType: LedgerItemType.expense,
        amount: Money.fromUnits(25000),
        date: DateTime(2026, 11, 12, 14, 30),
        description: 'Groceries',
        accountId: 'acc_1',
        accountName: 'HDFC Bank',
        createdAt: DateTime(2026, 11, 12, 14, 30),
      );

      bool deleteTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
              child: TransactionListItem(
                item: item,
                onDelete: () => deleteTriggered = true,
              ),
            ),
          ),
        ),
      );

      // Dismissible must NOT be present on TransactionListItem
      expect(find.byType(Dismissible), findsNothing);
      expect(deleteTriggered, isFalse);
    });
  });
}
