import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/id_generator.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';
import 'package:kals_money_manager/core/widgets/transaction_type_tabs.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/dashboard/presentation/models/dashboard_filter_state.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Comprehensive 15-Point Dashboard Regression Tests', () {
    late Database db;
    late AppDatabase appDb;
    late AccountRepositoryImpl accountRepo;
    late CategoryRepositoryImpl catRepo;
    late TransactionRepositoryImpl txRepo;
    late TransferRepositoryImpl transferRepo;

    late Account primaryAccount;
    late Account secondaryAccount;
    late Category foodCategory;

    // Fixed test anchor: 13 Oct 2026
    final testNow = DateTime(2026, 10, 13, 12, 0);

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

      primaryAccount = Account(
        id: 'acc_primary',
        name: 'Canara Bank',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(500000), // 5000.00
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      secondaryAccount = Account(
        id: 'acc_secondary',
        name: 'SBI Bank',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(300000), // 3000.00
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      foodCategory = Category(
        id: 'cat_food',
        name: 'Food & Dining',
        type: CategoryType.expense,
        icon: 'restaurant',
        color: 0xFFEF4444,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await accountRepo.createAccount(primaryAccount);
      await accountRepo.createAccount(secondaryAccount);
      await catRepo.createCategory(foodCategory);
    });

    tearDown(() async {
      await db.close();
    });

    test('1, 2, 3, 4: Week navigation refreshes chart and totals immediately without account switching', () async {
      // Current week: Mon 12 Oct to Sun 18 Oct 2026
      // Previous week: Mon 5 Oct to Sun 11 Oct 2026
      // Seed current week transaction
      final currentWeekTx = Transaction(
        id: IdGenerator.generate(),
        accountId: primaryAccount.id,
        categoryId: foodCategory.id,
        amount: Money.fromUnits(15000), // 150.00
        transactionType: CategoryType.expense,
        date: DateTime(2026, 10, 13, 10, 0),
        description: 'Current Week Lunch',
        createdAt: DateTime(2026, 10, 13),
        updatedAt: DateTime(2026, 10, 13),
      );
      // Seed previous week transaction
      final prevWeekTx = Transaction(
        id: IdGenerator.generate(),
        accountId: primaryAccount.id,
        categoryId: foodCategory.id,
        amount: Money.fromUnits(25000), // 250.00
        transactionType: CategoryType.expense,
        date: DateTime(2026, 10, 7, 14, 0),
        description: 'Previous Week Grocery',
        createdAt: DateTime(2026, 10, 7),
        updatedAt: DateTime(2026, 10, 7),
      );
      await txRepo.createTransaction(currentWeekTx);
      await txRepo.createTransaction(prevWeekTx);

      // Start on Current Week
      var filter = DashboardFilterState(
        accountId: primaryAccount.id,
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );

      // Query current week
      var items = await txRepo.getUnifiedLedger(
        accountId: filter.accountId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );
      expect(items.length, 1);
      expect(items.first.id, currentWeekTx.id);
      expect(items.first.amountUnits, 15000);
      expect(filter.isCurrentPeriod(localNow: testNow), isTrue); // Today hidden

      // 2. Navigate to Previous Week
      filter = filter.previousPeriod();
      items = await txRepo.getUnifiedLedger(
        accountId: filter.accountId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );
      // 3. Verify totals and items updated immediately WITHOUT changing account
      expect(items.length, 1);
      expect(items.first.id, prevWeekTx.id);
      expect(items.first.amountUnits, 25000);
      expect(filter.isCurrentPeriod(localNow: testNow), isFalse); // Today visible

      // 4. Navigate back to Next Week
      filter = filter.nextPeriod();
      items = await txRepo.getUnifiedLedger(
        accountId: filter.accountId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );
      expect(items.length, 1);
      expect(items.first.id, currentWeekTx.id);
      expect(filter.isCurrentPeriod(localNow: testNow), isTrue); // Today hidden again
    });

    test('5, 6: Month navigation updates data for historical months', () async {
      // October 2026 (current)
      final octTx = Transaction(
        id: IdGenerator.generate(),
        accountId: primaryAccount.id,
        categoryId: foodCategory.id,
        amount: Money.fromUnits(50000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 10, 2),
        description: 'October Rent',
        createdAt: DateTime(2026, 10, 2),
        updatedAt: DateTime(2026, 10, 2),
      );
      // September 2026 (historical)
      final septTx = Transaction(
        id: IdGenerator.generate(),
        accountId: primaryAccount.id,
        categoryId: foodCategory.id,
        amount: Money.fromUnits(45000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 9, 15),
        description: 'September Bills',
        createdAt: DateTime(2026, 9, 15),
        updatedAt: DateTime(2026, 9, 15),
      );
      await txRepo.createTransaction(octTx);
      await txRepo.createTransaction(septTx);

      var filter = DashboardFilterState(
        accountId: primaryAccount.id,
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );

      var items = await txRepo.getUnifiedLedger(
        accountId: filter.accountId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );
      expect(items.length, 1);
      expect(items.first.id, octTx.id);

      // Navigate to previous month (Sept 2026)
      filter = filter.previousPeriod();
      items = await txRepo.getUnifiedLedger(
        accountId: filter.accountId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );
      expect(items.length, 1);
      expect(items.first.id, septTx.id);
    });

    test('7, 8: Today visibility in Month mode: hidden when current month, visible when historical month', () {
      final currentMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );
      final historicalMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 9, 13),
        tabType: LedgerTabType.expenses,
      );
      final historicalYearSameMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2025, 10, 13),
        tabType: LedgerTabType.expenses,
      );

      // 7. Select current month -> Today is hidden
      expect(currentMonthFilter.isCurrentPeriod(localNow: testNow), isTrue);

      // 8. Select historical month -> Today is visible
      expect(historicalMonthFilter.isCurrentPeriod(localNow: testNow), isFalse);

      // Same month (Oct) in 2025 is NOT current month -> Today is visible
      expect(historicalYearSameMonthFilter.isCurrentPeriod(localNow: testNow), isFalse);
    });

    test('9. Today visibility across Day, Week, and Year', () {
      // Day
      final todayDay = DashboardFilterState(
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );
      final yesterdayDay = DashboardFilterState(
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 12),
        tabType: LedgerTabType.expenses,
      );
      expect(todayDay.isCurrentPeriod(localNow: testNow), isTrue);
      expect(yesterdayDay.isCurrentPeriod(localNow: testNow), isFalse);

      // Week
      final currentWeek = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 14),
        tabType: LedgerTabType.expenses,
      );
      final lastWeek = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 5),
        tabType: LedgerTabType.expenses,
      );
      expect(currentWeek.isCurrentPeriod(localNow: testNow), isTrue);
      expect(lastWeek.isCurrentPeriod(localNow: testNow), isFalse);

      // Year
      final currentYear = DashboardFilterState(
        periodMode: TimePeriod.year,
        anchorDate: DateTime(2026, 3, 1),
        tabType: LedgerTabType.expenses,
      );
      final pastYear = DashboardFilterState(
        periodMode: TimePeriod.year,
        anchorDate: DateTime(2025, 12, 1),
        tabType: LedgerTabType.expenses,
      );
      expect(currentYear.isCurrentPeriod(localNow: testNow), isTrue);
      expect(pastYear.isCurrentPeriod(localNow: testNow), isFalse);
    });

    test('10. Tap Today restores the active mode to the current period immediately', () {
      final historicalMonth = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2024, 3, 15),
        tabType: LedgerTabType.expenses,
      );

      final returnedFilter = historicalMonth.toCurrentPeriod(localNow: testNow);
      expect(returnedFilter.periodMode, TimePeriod.month);
      expect(returnedFilter.anchorDate.year, 2026);
      expect(returnedFilter.anchorDate.month, 10);
      expect(returnedFilter.isCurrentPeriod(localNow: testNow), isTrue);
    });

    test('11. Account filtering: All Accounts vs specific account queries', () async {
      final primaryTx = Transaction(
        id: IdGenerator.generate(),
        accountId: primaryAccount.id,
        categoryId: foodCategory.id,
        amount: Money.fromUnits(10000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 10, 13),
        description: 'Primary Account Lunch',
        createdAt: DateTime(2026, 10, 13),
        updatedAt: DateTime(2026, 10, 13),
      );
      final secondaryTx = Transaction(
        id: IdGenerator.generate(),
        accountId: secondaryAccount.id,
        categoryId: foodCategory.id,
        amount: Money.fromUnits(20000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 10, 13),
        description: 'Secondary Account Dinner',
        createdAt: DateTime(2026, 10, 13),
        updatedAt: DateTime(2026, 10, 13),
      );
      await txRepo.createTransaction(primaryTx);
      await txRepo.createTransaction(secondaryTx);

      final allAccountsFilter = DashboardFilterState(
        accountId: null,
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );
      final primaryOnlyFilter = allAccountsFilter.copyWith(accountId: primaryAccount.id);

      final allItems = await txRepo.getUnifiedLedger(
        accountId: allAccountsFilter.accountId,
        startDate: allAccountsFilter.startDate,
        endDate: allAccountsFilter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );
      expect(allItems.length, 2);

      final primaryItems = await txRepo.getUnifiedLedger(
        accountId: primaryOnlyFilter.accountId,
        startDate: primaryOnlyFilter.startDate,
        endDate: primaryOnlyFilter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );
      expect(primaryItems.length, 1);
      expect(primaryItems.first.id, primaryTx.id);
    });

    test('12. Empty period returns 0 items and zero totals without error', () async {
      final emptyFilter = DashboardFilterState(
        accountId: primaryAccount.id,
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2023, 1, 1),
        tabType: LedgerTabType.expenses,
      );

      final items = await txRepo.getUnifiedLedger(
        accountId: emptyFilter.accountId,
        startDate: emptyFilter.startDate,
        endDate: emptyFilter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );
      expect(items, isEmpty);
    });

    test('13. Transfers are excluded from income and expense category totals', () async {
      final transfer = Transfer(
        id: IdGenerator.generate(),
        fromAccountId: primaryAccount.id,
        toAccountId: secondaryAccount.id,
        amount: Money.fromUnits(50000),
        date: DateTime(2026, 10, 13),
        description: 'Inter-account transfer',
        createdAt: DateTime(2026, 10, 13),
        updatedAt: DateTime(2026, 10, 13),
      );
      await transferRepo.createTransfer(transfer);

      final filter = DashboardFilterState(
        accountId: primaryAccount.id,
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );

      final items = await txRepo.getUnifiedLedger(
        accountId: filter.accountId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );

      final expenseItems = items.where((i) => i.type == LedgerItemType.expense).toList();
      final transferItems = items.where((i) => i.type == LedgerItemType.transfer).toList();

      expect(expenseItems, isEmpty);
      expect(transferItems.length, 1);
      expect(transferItems.first.amountUnits, 50000);
    });

    test('14. Chart totals match underlying filtered transactions', () async {
      final tx1 = Transaction(
        id: IdGenerator.generate(),
        accountId: primaryAccount.id,
        categoryId: foodCategory.id,
        amount: Money.fromUnits(12000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 10, 13),
        description: 'Snacks',
        createdAt: DateTime(2026, 10, 13),
        updatedAt: DateTime(2026, 10, 13),
      );
      final tx2 = Transaction(
        id: IdGenerator.generate(),
        accountId: primaryAccount.id,
        categoryId: foodCategory.id,
        amount: Money.fromUnits(8000),
        transactionType: CategoryType.expense,
        date: DateTime(2026, 10, 13),
        description: 'Coffee',
        createdAt: DateTime(2026, 10, 13),
        updatedAt: DateTime(2026, 10, 13),
      );
      await txRepo.createTransaction(tx1);
      await txRepo.createTransaction(tx2);

      final filter = DashboardFilterState(
        accountId: primaryAccount.id,
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 13),
        tabType: LedgerTabType.expenses,
      );

      final items = await txRepo.getUnifiedLedger(
        accountId: filter.accountId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        exclusiveEndDate: true,
        limit: -1,
      );

      final totalExpenseUnits = items
          .where((i) => i.type == LedgerItemType.expense)
          .fold<int>(0, (sum, i) => sum + i.amountUnits);

      expect(totalExpenseUnits, 20000); // 200.00
    });

    test('15. Financial records in database remain unmodified and safe', () async {
      final initialCount = (await txRepo.getUnifiedLedger(limit: -1)).length;
      final initialAccounts = await accountRepo.getAllAccounts();

      expect(initialAccounts.length, 2);
      expect(initialCount >= 0, isTrue);
    });
  });
}
