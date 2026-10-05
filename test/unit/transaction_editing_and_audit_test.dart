import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/audit_log.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  late Database db;
  late AppDatabase appDb;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl txRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
      onCreate: DatabaseMigrations.onCreate,
    );
    appDb = AppDatabase.withDatabase(db);
    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);

    await accountRepo.createAccount(Account(
      id: 'acc_bank_1',
      name: 'Bank Account',
      accountType: AccountType.bank,
      openingBalance: const Money.zero(),
      currency: 'INR',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    await accountRepo.createAccount(Account(
      id: 'acc_cash_1',
      name: 'Cash',
      accountType: AccountType.cash,
      openingBalance: const Money.zero(),
      currency: 'INR',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  group('Transaction Editing, Modification History & Ledger Integrity Tests', () {
    test('Requirement 29: Create transaction and edit amount with audit tracking', () async {
      final accounts = await accountRepo.getAllAccounts();
      final hdfcAccount = accounts.first;
      final expenseCategories = await categoryRepo.getAllCategories(type: CategoryType.expense);
      final foodCategory = expenseCategories.first;

      final initialCreatedAt = DateTime(2026, 9, 25, 10, 42);
      const txId = 'TXN-00125';

      // 1. Create original transaction (₹500 expense)
      final originalTx = Transaction(
        id: txId,
        transactionType: CategoryType.expense,
        accountId: hdfcAccount.id,
        categoryId: foodCategory.id,
        amount: const Money(units: 50000), // ₹500.00
        date: initialCreatedAt,
        description: 'Lunch',
        createdAt: initialCreatedAt,
        updatedAt: initialCreatedAt,
      );

      await txRepo.createTransaction(originalTx);

      // Verify created audit record exists
      final logsAfterCreate = await txRepo.getAuditLogsForTransaction(txId);
      expect(logsAfterCreate.length, equals(1));
      expect(logsAfterCreate.first.operation, equals(AuditOperation.created));
      expect(logsAfterCreate.first.amount.units, equals(50000));

      // 2. Edit amount from ₹500 to ₹650
      final updatedTx = originalTx.copyWith(
        amount: const Money(units: 65000), // ₹650.00
      );

      await txRepo.updateTransaction(updatedTx);

      // Verify transaction in database
      final fetchedTx = await txRepo.getTransactionById(txId);
      expect(fetchedTx, isNotNull);
      expect(fetchedTx!.id, equals(txId)); // Transaction ID unchanged
      expect(fetchedTx.createdAt.millisecondsSinceEpoch, equals(initialCreatedAt.millisecondsSinceEpoch)); // CreatedAt unchanged
      expect(fetchedTx.amount.units, equals(65000)); // Updated amount

      // Verify audit logs preserved both original and modified entries
      final logsAfterEdit = await txRepo.getAuditLogsForTransaction(txId);
      expect(logsAfterEdit.length, equals(2));
      expect(logsAfterEdit[0].operation, equals(AuditOperation.created));
      expect(logsAfterEdit[0].amount.units, equals(50000));
      expect(logsAfterEdit[1].operation, equals(AuditOperation.modified));
      expect(logsAfterEdit[1].amount.units, equals(65000));

      // Verify account balance reflects exact ₹650 expense from ledger
      final accountWithBal = await accountRepo.getAccountWithBalance(hdfcAccount.id);
      expect(accountWithBal!.totalExpense.units, equals(65000));
    });

    test('Requirement 30: Edit category (Food -> Shopping) recalculates category totals accurately', () async {
      final accounts = await accountRepo.getAllAccounts();
      final account = accounts.first;
      final expenseCategories = await categoryRepo.getAllCategories(type: CategoryType.expense);
      final foodCat = expenseCategories.firstWhere((c) => c.name.contains('Food'));
      final shoppingCat = expenseCategories.firstWhere((c) => c.name.contains('Shopping'));

      final tx = Transaction(
        id: 'TXN-CAT-01',
        transactionType: CategoryType.expense,
        accountId: account.id,
        categoryId: foodCat.id,
        amount: const Money(units: 50000),
        date: DateTime(2026, 9, 25),
        description: 'Groceries and snacks',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txRepo.createTransaction(tx);

      // Change category to shopping
      final updatedCatTx = tx.copyWith(categoryId: shoppingCat.id);
      await txRepo.updateTransaction(updatedCatTx);

      // Check Food transactions
      final foodTxList = await txRepo.getTransactions(TransactionFilter(categoryId: foodCat.id));
      expect(foodTxList, isEmpty);

      // Check Shopping transactions
      final shoppingTxList = await txRepo.getTransactions(TransactionFilter(categoryId: shoppingCat.id));
      expect(shoppingTxList.length, equals(1));
      expect(shoppingTxList.first.amount.units, equals(50000));
    });

    test('Requirement 31: Edit account (Bank -> Cash) restores old balance and deducts new balance', () async {
      final accounts = await accountRepo.getAllAccounts();
      final bankAcc = accounts.firstWhere((a) => a.accountType == AccountType.bank);
      final cashAcc = accounts.firstWhere((a) => a.accountType == AccountType.cash);
      final expenseCategories = await categoryRepo.getAllCategories(type: CategoryType.expense);

      final tx = Transaction(
        id: 'TXN-ACC-01',
        transactionType: CategoryType.expense,
        accountId: bankAcc.id,
        categoryId: expenseCategories.first.id,
        amount: const Money(units: 50000), // ₹500
        date: DateTime(2026, 9, 25),
        description: 'Dinner',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txRepo.createTransaction(tx);

      var bankBal = await accountRepo.getAccountWithBalance(bankAcc.id);
      expect(bankBal!.totalExpense.units, equals(50000));

      // Edit account to Cash
      final updatedAccTx = tx.copyWith(accountId: cashAcc.id);
      await txRepo.updateTransaction(updatedAccTx);

      // Bank balance restored
      bankBal = await accountRepo.getAccountWithBalance(bankAcc.id);
      expect(bankBal!.totalExpense.units, equals(0));

      // Cash balance reduced by ₹500
      final cashBal = await accountRepo.getAccountWithBalance(cashAcc.id);
      expect(cashBal!.totalExpense.units, equals(50000));
    });

    test('Requirement 32: Edit date moves transaction between period reports accurately', () async {
      final accounts = await accountRepo.getAllAccounts();
      final expenseCategories = await categoryRepo.getAllCategories(type: CategoryType.expense);

      final sep25 = DateTime(2026, 9, 25, 12, 0);
      final sep28 = DateTime(2026, 9, 28, 12, 0);

      final tx = Transaction(
        id: 'TXN-DATE-01',
        transactionType: CategoryType.expense,
        accountId: accounts.first.id,
        categoryId: expenseCategories.first.id,
        amount: const Money(units: 50000),
        date: sep25,
        description: 'Lunch',
        createdAt: sep25,
        updatedAt: sep25,
      );

      await txRepo.createTransaction(tx);

      // Verify Sep 25 summary includes it
      var summarySep25 = await txRepo.getSummary(
        startDate: DateTime(2026, 9, 25, 0, 0),
        endDate: DateTime(2026, 9, 25, 23, 59),
      );
      expect(summarySep25.totalExpense.units, equals(50000));

      // Edit date to Sep 28
      final updatedDateTx = tx.copyWith(date: sep28);
      await txRepo.updateTransaction(updatedDateTx);

      // Verify Sep 25 summary excludes it
      summarySep25 = await txRepo.getSummary(
        startDate: DateTime(2026, 9, 25, 0, 0),
        endDate: DateTime(2026, 9, 25, 23, 59),
      );
      expect(summarySep25.totalExpense.units, equals(0));

      // Verify Sep 28 summary includes it
      final summarySep28 = await txRepo.getSummary(
        startDate: DateTime(2026, 9, 28, 0, 0),
        endDate: DateTime(2026, 9, 28, 23, 59),
      );
      expect(summarySep28.totalExpense.units, equals(50000));
    });

    test('Requirement 33: Multiple modifications retain full audit history', () async {
      final accounts = await accountRepo.getAllAccounts();
      final expenseCategories = await categoryRepo.getAllCategories(type: CategoryType.expense);

      const txId = 'TXN-MULTI-01';

      // 1. Create ₹500
      final tx = Transaction(
        id: txId,
        transactionType: CategoryType.expense,
        accountId: accounts.first.id,
        categoryId: expenseCategories.first.id,
        amount: const Money(units: 50000),
        date: DateTime.now(),
        description: 'Item',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txRepo.createTransaction(tx);

      // 2. Edit to ₹600
      await txRepo.updateTransaction(tx.copyWith(amount: const Money(units: 60000)));

      // 3. Edit to ₹700
      await txRepo.updateTransaction(tx.copyWith(amount: const Money(units: 70000)));

      // Verify current value
      final currentTx = await txRepo.getTransactionById(txId);
      expect(currentTx!.amount.units, equals(70000));

      // Verify all 3 audit history records
      final history = await txRepo.getAuditLogsForTransaction(txId);
      expect(history.length, equals(3));
      expect(history[0].operation, equals(AuditOperation.created));
      expect(history[0].amount.units, equals(50000));
      expect(history[1].operation, equals(AuditOperation.modified));
      expect(history[1].amount.units, equals(60000));
      expect(history[2].operation, equals(AuditOperation.modified));
      expect(history[2].amount.units, equals(70000));
    });

    test('Requirement 34: Direct account balance edit creates adjustment and preserves ledger integrity', () async {
      final accounts = await accountRepo.getAllAccounts();
      final account = accounts.first;
      final expenseCategories = await categoryRepo.getAllCategories(type: CategoryType.expense);

      // 1. Create a historical transaction (₹500 expense)
      final historicalTx = Transaction(
        id: 'TXN-HIST-01',
        transactionType: CategoryType.expense,
        accountId: account.id,
        categoryId: expenseCategories.first.id,
        amount: const Money(units: 50000), // ₹500
        date: DateTime(2026, 9, 20),
        description: 'Historical Grocery',
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );
      await txRepo.createTransaction(historicalTx);

      // Check balance before edit: opening balance - ₹500
      final beforeBal = await accountRepo.getAccountWithBalance(account.id);
      final initialBalanceUnits = account.openingBalance.units;
      expect(beforeBal!.calculatedBalance.units, equals(initialBalanceUnits - 50000));

      // 2. Adjust balance directly to initialBalanceUnits (+₹500 delta) without creating Income transaction
      final accountProvider = AccountProvider(repository: accountRepo);
      await accountProvider.adjustAccountBalance(
        accountId: account.id,
        newBalance: Money(units: initialBalanceUnits),
      );

      // 3. Verify new account balance is exactly initialBalanceUnits and Income is 0 (NOT increased)
      final afterBal = await accountRepo.getAccountWithBalance(account.id);
      expect(afterBal!.calculatedBalance.units, equals(initialBalanceUnits));
      expect(afterBal.totalIncome.units, equals(0), reason: 'Income must NOT increase');
      expect(afterBal.totalExpense.units, equals(50000), reason: 'Expense must remain ₹500');

      // 4. Verify original historical transaction is completely intact
      final fetchedHistTx = await txRepo.getTransactionById('TXN-HIST-01');
      expect(fetchedHistTx, isNotNull);
      expect(fetchedHistTx!.amount.units, equals(50000));
      expect(fetchedHistTx.description, equals('Historical Grocery'));
    });
  });
}
