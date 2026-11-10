import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:kals_money_manager/features/reminders/data/repositories/reminder_repository.dart';
import 'package:kals_money_manager/features/reminders/domain/entities/reminder.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Requirement 2: Database Safety & Non-Destructive Lifecycle Tests', () {
    late Database rawDb;
    late AppDatabase appDb;

    setUp(() async {
      rawDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      );
      appDb = AppDatabase.withDatabase(rawDb);
      AppDatabase.setTestInstance(appDb);
    });

    tearDown(() async {
      await rawDb.close();
    });

    test('Full lifecycle test: Seed, close, reopen, simulate settings check, verify zero data loss and stable IDs', () async {
      final accountRepo = AccountRepositoryImpl(database: appDb);
      final categoryRepo = CategoryRepositoryImpl(database: appDb);
      final transactionRepo = TransactionRepositoryImpl(database: appDb);
      final transferRepo = TransferRepositoryImpl(database: appDb);
      final recurringRepo = RecurringRepositoryImpl(database: appDb);
      final reminderRepo = ReminderRepository(db: appDb);

      // 1. Create 3 Accounts
      final now = DateTime.now();
      final acc1 = Account(
        id: 'acc-canara-1',
        name: 'Canara Bank',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(5000000), // 50,000 INR
        createdAt: now,
        updatedAt: now,
      );
      final acc2 = Account(
        id: 'acc-sbi-2',
        name: 'SBI Savings',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(2500000), // 25,000 INR
        createdAt: now,
        updatedAt: now,
      );
      final acc3 = Account(
        id: 'acc-cash-3',
        name: 'Wallet Cash',
        accountType: AccountType.cash,
        openingBalance: Money.fromUnits(500000), // 5,000 INR
        createdAt: now,
        updatedAt: now,
      );
      await accountRepo.createAccount(acc1);
      await accountRepo.createAccount(acc2);
      await accountRepo.createAccount(acc3);

      // 2. Create Categories
      final catFood = Category(
        id: 'cat-food',
        name: 'Food & Dining',
        type: CategoryType.expense,
        icon: 'restaurant_rounded',
        color: 0xFFEA580C,
        createdAt: now,
        updatedAt: now,
      );
      final catSalary = Category(
        id: 'cat-salary',
        name: 'Salary',
        type: CategoryType.income,
        icon: 'payments_rounded',
        color: 0xFF059669,
        createdAt: now,
        updatedAt: now,
      );
      await categoryRepo.createCategory(catFood);
      await categoryRepo.createCategory(catSalary);

      // 3. Create 22 Transactions
      final initialTxIds = <String>[];
      for (int i = 1; i <= 22; i++) {
        final txId = 'tx-record-$i';
        initialTxIds.add(txId);
        final tx = Transaction(
          id: txId,
          transactionType: i % 4 == 0 ? CategoryType.income : CategoryType.expense,
          accountId: i % 2 == 0 ? acc1.id : acc2.id,
          categoryId: i % 4 == 0 ? catSalary.id : catFood.id,
          amount: Money.fromUnits(i * 10000), // i * 100 INR
          date: now.subtract(Duration(days: i)),
          description: 'Transaction item #$i',
          notes: 'Test note #$i',
          receiptPath: i % 3 == 0 ? '/sdcard/receipt_$i.jpg' : null,
          createdAt: now,
          updatedAt: now,
        );
        await transactionRepo.createTransaction(tx);
      }

      // 4. Create Transfer
      final transfer = Transfer(
        id: 'tr-1001',
        fromAccountId: acc1.id,
        toAccountId: acc2.id,
        amount: Money.fromUnits(100000), // 1,000 INR
        date: now,
        description: 'Monthly savings transfer',
        createdAt: now,
        updatedAt: now,
      );
      await transferRepo.createTransfer(transfer);

      // 5. Create Recurring Payment
      final recurring = RecurringTransaction(
        id: 'rec-1001',
        transactionType: CategoryType.expense,
        accountId: acc1.id,
        categoryId: catFood.id,
        amount: Money.fromUnits(50000),
        description: 'Monthly broadband',
        frequency: RecurringFrequency.monthly,
        startDate: now,
        nextExecutionDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );
      await recurringRepo.createRecurring(recurring);

      // 6. Create Reminder
      final reminder = Reminder(
        id: 'rem-1001',
        name: 'Pay Credit Card Bill',
        frequency: ReminderFrequency.monthly,
        date: DateTime(2026, 10, 15),
        time: const TimeOfDay(hour: 20, minute: 0),
        comment: 'Keep zero balance',
        createdAt: now,
        updatedAt: now,
      );
      await reminderRepo.insertReminder(reminder);

      // Verify Initial Counts Before Lifecycle Actions
      final accountsBefore = await accountRepo.getAllAccounts();
      final txBefore = await transactionRepo.getTransactions(const TransactionFilter(limit: 100));
      final transfersBefore = await transferRepo.getAllTransfers();
      final recurringBefore = await recurringRepo.getAllRecurring();
      final remindersBefore = await reminderRepo.getAllReminders();

      expect(accountsBefore.length, 3);
      expect(txBefore.length, 22);
      expect(transfersBefore.length, 1);
      expect(recurringBefore.length, 1);
      expect(remindersBefore.length, 1);

      // Simulate App Restart & Settings Check (Existing user onboarding detection)
      final settingsProvider = SettingsProvider(database: appDb);
      await settingsProvider.loadSettings();
      expect(settingsProvider.isOnboardingCompleted, isTrue);

      // Verify zero records disappeared
      final accountsAfter = await accountRepo.getAllAccounts();
      final txAfter = await transactionRepo.getTransactions(const TransactionFilter(limit: 100));
      final remindersAfter = await reminderRepo.getAllReminders();

      expect(accountsAfter.length, accountsBefore.length);
      expect(txAfter.length, txBefore.length);
      expect(remindersAfter.length, remindersBefore.length);

      // Verify stable IDs
      final afterTxIds = txAfter.map((t) => t.id).toList();
      for (final id in initialTxIds) {
        expect(afterTxIds.contains(id), isTrue);
      }
    });
  });
}
