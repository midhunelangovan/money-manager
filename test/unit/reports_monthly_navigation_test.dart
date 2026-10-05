import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/id_generator.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Historical Month Navigation & Analytics Tests', () {
    late Database db;
    late AppDatabase appDb;
    late AccountRepositoryImpl accountRepo;
    late CategoryRepositoryImpl catRepo;
    late TransactionRepositoryImpl txRepo;
    late TransferRepositoryImpl transferRepo;
    late TransactionProvider txProvider;

    late String canaraBankId;
    late String sbiBankId;
    late String foodCategoryId;
    late String salaryCategoryId;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      );
      appDb = AppDatabase.withDatabase(db);
      accountRepo = AccountRepositoryImpl(database: appDb);
      catRepo = CategoryRepositoryImpl(database: appDb);
      txRepo = TransactionRepositoryImpl(database: appDb);
      transferRepo = TransferRepositoryImpl(database: appDb);
      txProvider = TransactionProvider(repository: txRepo);

      final now = DateTime.now();
      canaraBankId = IdGenerator.generate();
      sbiBankId = IdGenerator.generate();
      await accountRepo.createAccount(Account(
        id: canaraBankId,
        name: 'Canara Bank',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 0),
        createdAt: now,
        updatedAt: now,
      ));
      await accountRepo.createAccount(Account(
        id: sbiBankId,
        name: 'SBI',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 0),
        createdAt: now,
        updatedAt: now,
      ));

      foodCategoryId = IdGenerator.generate();
      salaryCategoryId = IdGenerator.generate();
      await catRepo.createCategory(Category(
        id: foodCategoryId,
        name: 'Food',
        type: CategoryType.expense,
        createdAt: now,
        updatedAt: now,
      ));
      await catRepo.createCategory(Category(
        id: salaryCategoryId,
        name: 'Salary',
        type: CategoryType.income,
        createdAt: now,
        updatedAt: now,
      ));
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Database Query Boundaries: January, February, March, April 2026 [start, end)', () async {
      final now = DateTime(2026, 10, 3);

      // Insert transaction at the very beginning of Jan 2026 (2026-01-01 00:00:00)
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: foodCategoryId,
        amount: const Money(units: 10000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 1, 1, 0, 0, 0),
        description: 'Jan 1 expense',
        createdAt: now,
        updatedAt: now,
      ));

      // Insert transaction at the very end of Jan 2026 (2026-01-31 23:59:59)
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: foodCategoryId,
        amount: const Money(units: 20000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 1, 31, 23, 59, 59),
        description: 'Jan 31 expense',
        createdAt: now,
        updatedAt: now,
      ));

      // Insert transaction at the very beginning of Feb 2026 (2026-02-01 00:00:00)
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: foodCategoryId,
        amount: const Money(units: 30000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 2, 1, 0, 0, 0),
        description: 'Feb 1 expense',
        createdAt: now,
        updatedAt: now,
      ));

      // January query: >= 2026-01-01 00:00:00, < 2026-02-01 00:00:00
      final janStart = DateTime(2026, 1, 1, 0, 0, 0);
      final janEnd = DateTime(2026, 2, 1, 0, 0, 0);
      final janItems = await txRepo.getUnifiedLedger(
        startDate: janStart,
        endDate: janEnd,
        exclusiveEndDate: true,
        limit: -1,
      );

      expect(janItems.length, 2, reason: 'January must contain Jan 1 and Jan 31 transactions, NOT Feb 1');

      // February query: >= 2026-02-01 00:00:00, < 2026-03-01 00:00:00
      final febStart = DateTime(2026, 2, 1, 0, 0, 0);
      final febEnd = DateTime(2026, 3, 1, 0, 0, 0);
      final febItems = await txRepo.getUnifiedLedger(
        startDate: febStart,
        endDate: febEnd,
        exclusiveEndDate: true,
        limit: -1,
      );

      expect(febItems.length, 1, reason: 'February must contain Feb 1 transaction');
    });

    test('2. Historical Data: January 2026 (60 expenses, 12 incomes, 5 transfers = 77 items)', () async {
      final importDate = DateTime(2026, 10, 3, 18, 0, 0);

      // Create 60 Expenses in Jan 2026
      for (int i = 1; i <= 60; i++) {
        final day = (i % 28) + 1;
        await txRepo.createTransaction(Transaction(
          id: IdGenerator.generate(),
          accountId: canaraBankId,
          categoryId: foodCategoryId,
          amount: const Money(units: 10000), // ₹100
          transactionType: CategoryType.expense,
          date: DateTime(2026, 1, day, 10, 0, 0),
          description: 'Expense $i',
          createdAt: importDate,
          updatedAt: importDate,
        ));
      }

      // Create 12 Incomes in Jan 2026
      for (int i = 1; i <= 12; i++) {
        final day = (i % 28) + 1;
        await txRepo.createTransaction(Transaction(
          id: IdGenerator.generate(),
          accountId: canaraBankId,
          categoryId: salaryCategoryId,
          amount: const Money(units: 50000), // ₹500
          transactionType: CategoryType.income,
          date: DateTime(2026, 1, day, 12, 0, 0),
          description: 'Income $i',
          createdAt: importDate,
          updatedAt: importDate,
        ));
      }

      // Create 5 Transfers in Jan 2026
      for (int i = 1; i <= 5; i++) {
        final day = (i % 28) + 1;
        await transferRepo.createTransfer(Transfer(
          id: IdGenerator.generate(),
          fromAccountId: canaraBankId,
          toAccountId: sbiBankId,
          amount: const Money(units: 20000), // ₹200
          date: DateTime(2026, 1, day, 15, 0, 0),
          description: 'Transfer $i',
          createdAt: importDate,
          updatedAt: importDate,
        ));
      }

      // Query January 2026 via range provider
      final janStart = DateTime(2026, 1, 1);
      final janEnd = DateTime(2026, 2, 1);
      final janItems = await txProvider.getItemsForRange(
        startDate: janStart,
        endDate: janEnd,
        exclusiveEndDate: true,
      );

      expect(janItems.length, 77);

      final summary = await txProvider.getSummaryForRange(
        startDate: janStart,
        endDate: janEnd,
        exclusiveEndDate: true,
      );

      expect(summary.totalExpense.units, 60 * 10000);
      expect(summary.totalIncome.units, 12 * 50000);
      expect(summary.transactionCount, 72); // 60 expenses + 12 incomes
    });

    test('3. Transaction Date must be used, NOT createdAt or importedAt', () async {
      final importDate = DateTime(2026, 10, 3, 18, 0, 0);

      // Transaction date: Jan 15, 2026; Import date: Oct 3, 2026
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: foodCategoryId,
        amount: const Money(units: 15000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 1, 15, 14, 30),
        description: 'Historical grocery',
        createdAt: importDate,
        updatedAt: importDate,
      ));

      // Query January 2026
      final janItems = await txProvider.getItemsForRange(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 1),
        exclusiveEndDate: true,
      );
      expect(janItems.length, 1, reason: 'Transaction must appear in January 2026');

      // Query October 2026
      final octItems = await txProvider.getItemsForRange(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 11, 1),
        exclusiveEndDate: true,
      );
      expect(octItems.length, 0, reason: 'Transaction must NOT appear in October 2026 just because it was imported then');
    });

    test('4. Backward and Forward Month Navigation Across Full Year & Across Year Boundary', () async {
      final now = DateTime(2026, 10, 3);

      // Insert 1 item for each month from Nov 2025 to Oct 2026
      final monthsToPopulate = [
        DateTime(2025, 11, 15),
        DateTime(2025, 12, 20),
        DateTime(2026, 1, 10),
        DateTime(2026, 2, 10),
        DateTime(2026, 3, 10),
        DateTime(2026, 4, 10),
        DateTime(2026, 5, 10),
        DateTime(2026, 6, 10),
        DateTime(2026, 7, 10),
        DateTime(2026, 8, 10),
        DateTime(2026, 9, 10),
        DateTime(2026, 10, 2),
      ];

      for (final txDate in monthsToPopulate) {
        await txRepo.createTransaction(Transaction(
          id: IdGenerator.generate(),
          accountId: canaraBankId,
          categoryId: foodCategoryId,
          amount: const Money(units: 5000),
          transactionType: CategoryType.expense,
          date: txDate,
          description: 'Tx at $txDate',
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Backward navigation simulation from October 2026 down to November 2025
      DateTime currentMonth = DateTime(2026, 10, 1);
      final backwardExpectedMonths = [
        DateTime(2026, 10, 1),
        DateTime(2026, 9, 1),
        DateTime(2026, 8, 1),
        DateTime(2026, 7, 1),
        DateTime(2026, 6, 1),
        DateTime(2026, 5, 1),
        DateTime(2026, 4, 1),
        DateTime(2026, 3, 1),
        DateTime(2026, 2, 1),
        DateTime(2026, 1, 1),
        DateTime(2025, 12, 1),
        DateTime(2025, 11, 1),
      ];

      for (final expectedMonth in backwardExpectedMonths) {
        expect(currentMonth.year, expectedMonth.year);
        expect(currentMonth.month, expectedMonth.month);

        final startDate = DateTime(currentMonth.year, currentMonth.month, 1);
        final endDate = DateTime(currentMonth.year, currentMonth.month + 1, 1);
        final items = await txProvider.getItemsForRange(
          startDate: startDate,
          endDate: endDate,
          exclusiveEndDate: true,
        );
        expect(items.length, 1, reason: 'Month ${currentMonth.year}-${currentMonth.month} should have 1 transaction');

        // Navigate backward
        currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
      }

      // Forward navigation simulation from November 2025 back to October 2026
      currentMonth = DateTime(2025, 11, 1);
      final forwardExpectedMonths = backwardExpectedMonths.reversed.toList();

      for (final expectedMonth in forwardExpectedMonths) {
        expect(currentMonth.year, expectedMonth.year);
        expect(currentMonth.month, expectedMonth.month);

        final startDate = DateTime(currentMonth.year, currentMonth.month, 1);
        final endDate = DateTime(currentMonth.year, currentMonth.month + 1, 1);
        final items = await txProvider.getItemsForRange(
          startDate: startDate,
          endDate: endDate,
          exclusiveEndDate: true,
        );
        expect(items.length, 1, reason: 'Month ${currentMonth.year}-${currentMonth.month} should have 1 transaction');

        // Navigate forward
        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }
    });

    test('5. Filter Combination: January 2026 + Account Filter (Canara Bank vs SBI)', () async {
      final now = DateTime(2026, 1, 15);

      // Canara Bank transaction
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: foodCategoryId,
        amount: const Money(units: 10000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 1, 10),
        description: 'Canara Tx',
        createdAt: now,
        updatedAt: now,
      ));

      // SBI transaction
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: sbiBankId,
        categoryId: foodCategoryId,
        amount: const Money(units: 20000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 1, 20),
        description: 'SBI Tx',
        createdAt: now,
        updatedAt: now,
      ));

      final janStart = DateTime(2026, 1, 1);
      final janEnd = DateTime(2026, 2, 1);

      // All accounts
      final allItems = await txProvider.getItemsForRange(
        startDate: janStart,
        endDate: janEnd,
        exclusiveEndDate: true,
      );
      expect(allItems.length, 2);

      // Canara Bank only
      final canaraItems = await txProvider.getItemsForRange(
        startDate: janStart,
        endDate: janEnd,
        exclusiveEndDate: true,
        accountId: canaraBankId,
      );
      expect(canaraItems.length, 1);

      // SBI only
      final sbiItems = await txProvider.getItemsForRange(
        startDate: janStart,
        endDate: janEnd,
        exclusiveEndDate: true,
        accountId: sbiBankId,
      );
      expect(sbiItems.length, 1);
    });

    test('6. Empty Month returns 0 items without error', () async {
      final start = DateTime(2024, 6, 1);
      final end = DateTime(2024, 7, 1);

      final items = await txProvider.getItemsForRange(
        startDate: start,
        endDate: end,
        exclusiveEndDate: true,
      );
      expect(items.isEmpty, isTrue);

      final summary = await txProvider.getSummaryForRange(
        startDate: start,
        endDate: end,
        exclusiveEndDate: true,
      );
      expect(summary.totalExpense.units, 0);
      expect(summary.totalIncome.units, 0);
      expect(summary.transactionCount, 0);
    });
  });
}
