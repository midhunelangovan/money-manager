import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/utilities/id_generator.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Manual Account Balance Adjustment Tests', () {
    late Database db;
    late AppDatabase appDb;
    late AccountRepositoryImpl accountRepo;
    late AccountProvider accountProvider;
    late TransactionRepositoryImpl txRepo;
    late CategoryRepositoryImpl catRepo;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      );
      appDb = AppDatabase.withDatabase(db);
      accountRepo = AccountRepositoryImpl(database: appDb);
      accountProvider = AccountProvider(repository: accountRepo);
      txRepo = TransactionRepositoryImpl(database: appDb);
      catRepo = CategoryRepositoryImpl(database: appDb);
    });

    tearDown(() async {
      await db.close();
    });

    test('Starting balance ₹4,043.76 set to ₹5,000.00 creates NO transaction and keeps Income 0', () async {
      final now = DateTime.now();
      final accountId = IdGenerator.generate();

      // Create account with ₹4,043.76
      await accountRepo.createAccount(Account(
        id: accountId,
        name: 'Canara Bank',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 404376), // ₹4,043.76
        createdAt: now,
        updatedAt: now,
      ));

      await accountProvider.loadAccounts();
      final initialAcc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      expect(initialAcc.calculatedBalance.units, equals(404376));
      expect(initialAcc.totalIncome.units, equals(0));
      expect(initialAcc.totalExpense.units, equals(0));
      expect(initialAcc.transactionCount, equals(0));

      // Manually adjust balance to ₹5,000.00 (+₹956.24 difference)
      await accountProvider.adjustAccountBalance(
        accountId: accountId,
        newBalance: const Money(units: 500000), // ₹5,000.00
      );

      final updatedAcc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      expect(updatedAcc.calculatedBalance.units, equals(500000));
      expect(updatedAcc.totalIncome.units, equals(0), reason: 'Income must NOT increase');
      expect(updatedAcc.totalExpense.units, equals(0), reason: 'Expense must NOT increase');
      expect(updatedAcc.totalTransfersIn.units, equals(0));
      expect(updatedAcc.totalTransfersOut.units, equals(0));
      expect(updatedAcc.transactionCount, equals(0), reason: 'Transaction count must remain 0');

      // Verify DB transactions table is empty
      final txCountDb = await db.query(DbTables.transactions);
      expect(txCountDb.isEmpty, isTrue, reason: 'No rows should be inserted into transactions table');
    });

    test('Balance reduction from ₹5,000.00 to ₹4,000.00 creates NO expense and keeps totals unchanged', () async {
      final now = DateTime.now();
      final accountId = IdGenerator.generate();

      await accountRepo.createAccount(Account(
        id: accountId,
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 500000), // ₹5,000.00
        createdAt: now,
        updatedAt: now,
      ));

      await accountProvider.loadAccounts();

      // Reduce balance to ₹4,000.00 (-₹1,000.00 difference)
      await accountProvider.adjustAccountBalance(
        accountId: accountId,
        newBalance: const Money(units: 400000), // ₹4,000.00
      );

      final updatedAcc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      expect(updatedAcc.calculatedBalance.units, equals(400000));
      expect(updatedAcc.totalIncome.units, equals(0));
      expect(updatedAcc.totalExpense.units, equals(0), reason: 'Expense must NOT increase');
      expect(updatedAcc.transactionCount, equals(0));

      final txCountDb = await db.query(DbTables.transactions);
      expect(txCountDb.isEmpty, isTrue);
    });

    test('Manual balance adjustment preserves existing imported transactions and categories', () async {
      final now = DateTime.now();
      final accountId = IdGenerator.generate();
      final catIncomeId = IdGenerator.generate();
      final catExpenseId = IdGenerator.generate();

      await accountRepo.createAccount(Account(
        id: accountId,
        name: 'Salary Account',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 100000), // ₹1,000.00
        createdAt: now,
        updatedAt: now,
      ));

      await catRepo.createCategory(Category(
        id: catIncomeId,
        name: 'Salary',
        type: CategoryType.income,
        createdAt: now,
        updatedAt: now,
      ));

      await catRepo.createCategory(Category(
        id: catExpenseId,
        name: 'Groceries',
        type: CategoryType.expense,
        createdAt: now,
        updatedAt: now,
      ));

      // Add 1 income: ₹3,000
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.uuid(),
        accountId: accountId,
        categoryId: catIncomeId,
        amount: const Money(units: 300000),
        transactionType: CategoryType.income,
        date: now,
        description: 'Monthly Salary',
        createdAt: now,
        updatedAt: now,
      ));

      // Add 1 expense: ₹500
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.uuid(),
        accountId: accountId,
        categoryId: catExpenseId,
        amount: const Money(units: 50000),
        transactionType: CategoryType.expense,
        date: now,
        description: 'Supermarket',
        createdAt: now,
        updatedAt: now,
      ));

      await accountProvider.loadAccounts();
      final accBefore = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      // Balance = 1,000 + 3,000 - 500 = ₹3,500.00
      expect(accBefore.calculatedBalance.units, equals(350000));
      expect(accBefore.totalIncome.units, equals(300000));
      expect(accBefore.totalExpense.units, equals(50000));
      expect(accBefore.transactionCount, equals(2));

      // Now user manually adjusts current balance to ₹4,500.00
      await accountProvider.adjustAccountBalance(
        accountId: accountId,
        newBalance: const Money(units: 450000), // ₹4,500.00
      );

      final accAfter = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      expect(accAfter.calculatedBalance.units, equals(450000));
      expect(accAfter.totalIncome.units, equals(300000), reason: 'Existing income total must be unchanged');
      expect(accAfter.totalExpense.units, equals(50000), reason: 'Existing expense total must be unchanged');
      expect(accAfter.transactionCount, equals(2), reason: 'Transaction count must remain 2');

      // Add a new transaction after adjustment and verify calculation continues seamlessly
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.uuid(),
        accountId: accountId,
        categoryId: catExpenseId,
        amount: const Money(units: 50000), // -₹500.00
        transactionType: CategoryType.expense,
        date: now,
        description: 'Dinner',
        createdAt: now,
        updatedAt: now,
      ));

      await accountProvider.loadAccounts();
      final accFinal = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      // 4,500 - 500 = ₹4,000.00
      expect(accFinal.calculatedBalance.units, equals(400000));
      expect(accFinal.totalIncome.units, equals(300000));
      expect(accFinal.totalExpense.units, equals(100000));
      expect(accFinal.transactionCount, equals(3));
    });

    test('Section 12 Final Acceptance Test: Sequential adjustments & additional transactions', () async {
      final now = DateTime.now();
      final accountId = IdGenerator.generate();
      final catExpenseId = IdGenerator.generate();
      final catIncomeId = IdGenerator.generate();

      await catRepo.createCategory(Category(
        id: catExpenseId,
        name: 'General Expense',
        type: CategoryType.expense,
        createdAt: now,
        updatedAt: now,
      ));
      await catRepo.createCategory(Category(
        id: catIncomeId,
        name: 'General Income',
        type: CategoryType.income,
        createdAt: now,
        updatedAt: now,
      ));

      // Step 1: Starting balance = ₹4,043.76
      await accountRepo.createAccount(Account(
        id: accountId,
        name: 'Canara Bank',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 404376), // ₹4,043.76
        createdAt: now,
        updatedAt: now,
      ));

      await accountProvider.loadAccounts();
      var acc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      expect(acc.calculatedBalance.units, equals(404376));
      expect(acc.totalIncome.units, equals(0));
      expect(acc.totalExpense.units, equals(0));
      expect(acc.totalTransfersIn.units, equals(0));
      expect(acc.totalTransfersOut.units, equals(0));
      expect(acc.transactionCount, equals(0));

      // Step 2: Set to ₹5,000.00
      await accountProvider.adjustAccountBalance(
        accountId: accountId,
        newBalance: const Money(units: 500000), // ₹5,000.00
      );

      acc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      expect(acc.calculatedBalance.units, equals(500000), reason: 'Account balance = ₹5,000.00');
      expect(acc.totalIncome.units, equals(0), reason: 'Income = unchanged');
      expect(acc.totalExpense.units, equals(0), reason: 'Expense = unchanged');
      expect(acc.totalTransfersIn.units, equals(0), reason: 'Transfers in = unchanged');
      expect(acc.totalTransfersOut.units, equals(0), reason: 'Transfers out = unchanged');
      expect(acc.transactionCount, equals(0), reason: 'Transaction count = unchanged');

      // Step 3: Set to ₹4,000.00
      await accountProvider.adjustAccountBalance(
        accountId: accountId,
        newBalance: const Money(units: 400000), // ₹4,000.00
      );

      acc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      expect(acc.calculatedBalance.units, equals(400000), reason: 'Account balance = ₹4,000.00');
      expect(acc.totalIncome.units, equals(0), reason: 'Income = unchanged');
      expect(acc.totalExpense.units, equals(0), reason: 'Expense = unchanged');
      expect(acc.totalTransfersIn.units, equals(0), reason: 'Transfers in = unchanged');
      expect(acc.totalTransfersOut.units, equals(0), reason: 'Transfers out = unchanged');
      expect(acc.transactionCount, equals(0), reason: 'Transaction count = unchanged');

      // Step 4: Import / add additional transactions
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.uuid(),
        accountId: accountId,
        categoryId: catIncomeId,
        amount: const Money(units: 250000), // +₹2,500.00
        transactionType: CategoryType.income,
        date: now,
        description: 'Client payment',
        createdAt: now,
        updatedAt: now,
      ));

      await txRepo.createTransaction(Transaction(
        id: IdGenerator.uuid(),
        accountId: accountId,
        categoryId: catExpenseId,
        amount: const Money(units: 150000), // -₹1,500.00
        transactionType: CategoryType.expense,
        date: now,
        description: 'Supplies',
        createdAt: now,
        updatedAt: now,
      ));

      await accountProvider.loadAccounts();
      acc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == accountId);
      // Balance = 4,000 + 2,500 - 1,500 = ₹5,000.00
      expect(acc.calculatedBalance.units, equals(500000));
      expect(acc.totalIncome.units, equals(250000));
      expect(acc.totalExpense.units, equals(150000));
      expect(acc.transactionCount, equals(2));
    });
  });
}
