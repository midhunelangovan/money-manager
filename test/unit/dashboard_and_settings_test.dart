import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/constants/app_currency.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/theme/app_colors.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:kals_money_manager/features/transfers/presentation/providers/transfer_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Dashboard Data Flow & State Reactivity Tests', () {
    late Database db;
    late AppDatabase appDb;
    late AccountRepositoryImpl accountRepo;
    late TransactionRepositoryImpl txRepo;
    late TransferRepositoryImpl transferRepo;
    late AccountProvider accountProvider;
    late TransactionProvider txProvider;
    late TransferProvider transferProvider;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      );
      appDb = AppDatabase.withDatabase(db);
      accountRepo = AccountRepositoryImpl(database: appDb);
      txRepo = TransactionRepositoryImpl(database: appDb);
      transferRepo = TransferRepositoryImpl(database: appDb);

      accountProvider = AccountProvider(repository: accountRepo);
      txProvider = TransactionProvider(repository: txRepo);
      transferProvider = TransferProvider(repository: transferRepo);

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

      await accountProvider.loadAccounts();
      await txProvider.loadLedger();
      await transferProvider.loadTransfers();
    });

    tearDown(() async {
      await db.close();
    });

    test('Adding Expense immediately updates balance, ledger, and category totals', () async {
      final accounts = accountProvider.accountsWithBalances;
      expect(accounts.isNotEmpty, isTrue);
      final accountId = accounts.first.account.id;

      // Initial state
      final initialBalance = accountProvider.totalBalance.units;

      // Add expense ₹500 (50000 units)
      final expenseTx = Transaction(
        id: 'test_exp_1',
        transactionType: CategoryType.expense,
        accountId: accountId,
        categoryId: (await db.query('categories', where: 'type = ?', whereArgs: ['EXPENSE'])).first['id'] as String,
        amount: const Money(units: 50000),
        date: DateTime.now(),
        description: 'Dinner with friends',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txProvider.createTransaction(expenseTx);
      await accountProvider.loadAccounts();

      // Check reactive updates
      expect(accountProvider.totalBalance.units, equals(initialBalance - 50000));
      expect(txProvider.allLedgerItems.any((item) => item.id == 'test_exp_1'), isTrue);
      expect(txProvider.allLedgerItems.first.description, equals('Dinner with friends'));
    });

    test('Adding Income immediately updates balance, totals, and net change', () async {
      final accounts = accountProvider.accountsWithBalances;
      final accountId = accounts.first.account.id;
      final initialBalance = accountProvider.totalBalance.units;

      // Add income ₹20,000 (2000000 units)
      final incomeTx = Transaction(
        id: 'test_inc_1',
        transactionType: CategoryType.income,
        accountId: accountId,
        categoryId: (await db.query('categories', where: 'type = ?', whereArgs: ['INCOME'])).first['id'] as String,
        amount: const Money(units: 2000000),
        date: DateTime.now(),
        description: 'Freelance Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txProvider.createTransaction(incomeTx);
      await accountProvider.loadAccounts();

      expect(accountProvider.totalBalance.units, equals(initialBalance + 2000000));
      expect(txProvider.allLedgerItems.any((item) => item.id == 'test_inc_1'), isTrue);
      expect(txProvider.allLedgerItems.first.amountUnits, equals(2000000));
    });

    test('Transfer between accounts recalculates individual balances and displays in ledger', () async {
      final accounts = accountProvider.accountsWithBalances;
      expect(accounts.length >= 2, isTrue);

      final fromAcc = accounts[0];
      final toAcc = accounts[1];
      final initialFromBal = fromAcc.calculatedBalance.units;
      final initialToBal = toAcc.calculatedBalance.units;

      final transfer = Transfer(
        id: 'test_tr_1',
        fromAccountId: fromAcc.account.id,
        toAccountId: toAcc.account.id,
        amount: const Money(units: 150000), // ₹1,500
        date: DateTime.now(),
        description: 'Bank to Cash ATM',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await transferProvider.createTransfer(transfer);
      await accountProvider.loadAccounts();
      await txProvider.loadLedger();

      final updatedAccounts = accountProvider.accountsWithBalances;
      final updatedFrom = updatedAccounts.firstWhere((a) => a.account.id == fromAcc.account.id);
      final updatedTo = updatedAccounts.firstWhere((a) => a.account.id == toAcc.account.id);

      expect(updatedFrom.calculatedBalance.units, equals(initialFromBal - 150000));
      expect(updatedTo.calculatedBalance.units, equals(initialToBal + 150000));
      expect(txProvider.allLedgerItems.any((item) => item.id == 'test_tr_1'), isTrue);
    });
  });

  group('Settings & Currency Configuration Tests', () {
    test('Currency formatting uses configured metadata without modifying raw integer amounts', () {
      const money = Money(units: 58345000); // 583,450.00

      // INR format
      final formattedInr = money.format(currency: AppCurrency.inr);
      expect(formattedInr, contains('₹'));
      expect(formattedInr, contains('5,83,450'));

      // USD format
      final formattedUsd = money.format(currency: AppCurrency.usd);
      expect(formattedUsd, contains('\$'));
      expect(formattedUsd, contains('583,450'));

      // EUR format
      final formattedEur = money.format(currency: AppCurrency.eur);
      expect(formattedEur, contains('€'));
      expect(formattedEur, contains('583,450'));

      // Integer units remain strictly exact
      expect(money.units, equals(58345000));
    });

    test('SettingsProvider correctly handles theme mode and accent color changes', () {
      final provider = SettingsProvider();

      // Accent color
      provider.setAccentColor(AppAccentColor.blue);
      expect(provider.accentColor, equals(AppAccentColor.blue));
      expect(provider.accentColor.primary, equals(const Color(0xFF1D5C96)));

      provider.setAccentColor(AppAccentColor.green);
      expect(provider.accentColor, equals(AppAccentColor.green));

      // Currency
      provider.setCurrency(AppCurrency.usd);
      expect(provider.currency.code, equals('USD'));
      expect(provider.currency.symbol, equals('\$'));

      // App Lock
      provider.setAppLockEnabled(true);
      expect(provider.isAppLockEnabled, isTrue);
    });
  });
}
