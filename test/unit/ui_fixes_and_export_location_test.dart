import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/utilities/app_snack_bar.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/utilities/storage_helper.dart';
import 'package:kals_money_manager/core/widgets/export_success_dialog.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
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

  late Database db;
  late AppDatabase appDb;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl txRepo;
  late TransferRepositoryImpl transferRepo;
  late AccountProvider accountProvider;
  late CategoryProvider categoryProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      ),
    );
    appDb = AppDatabase.withDatabase(db);
    AppDatabase.setTestInstance(appDb);

    await db.delete(DbTables.transactions);
    await db.delete(DbTables.transfers);
    await db.delete(DbTables.categories);
    await db.delete(DbTables.accounts);
    try {
      await db.delete('app_settings');
    } catch (_) {}

    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    transferRepo = TransferRepositoryImpl(database: appDb);

    // Create 2 distinct accounts
    await accountRepo.createAccount(Account(
      id: 'acc_bank',
      name: 'Bank Account',
      accountType: AccountType.bank,
      currency: 'INR',
      openingBalance: const Money(units: 500000), // ₹5,000
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await accountRepo.createAccount(Account(
      id: 'acc_cash',
      name: 'Cash Wallet',
      accountType: AccountType.cash,
      currency: 'INR',
      openingBalance: const Money(units: 100000), // ₹1,000
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Create categories
    await categoryRepo.createCategory(Category(
      id: 'cat_groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_bag',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await categoryRepo.createCategory(Category(
      id: 'cat_salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: 'payments',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    accountProvider = AccountProvider(repository: accountRepo);
    categoryProvider = CategoryProvider(repository: categoryRepo);
    settingsProvider = SettingsProvider(database: appDb);

    await Future.wait([
      accountProvider.loadAccounts(),
      categoryProvider.loadCategories(),
      settingsProvider.loadSettings(),
    ]);
  });

  tearDown(() async {
    AppDatabase.setTestInstance(null);
    await db.close();
  });

  group('1. Success Message Dismissal Tests', () {
    testWidgets('AppSnackBar.showSuccess sets 2500ms duration and clears prior messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackBar.showSuccess(context, 'Transaction added successfully.');
                },
                child: const Text('Show Notification'),
              ),
            ),
          ),
        ),
      );

      // Trigger snackbar
      await tester.tap(find.text('Show Notification'));
      await tester.pumpAndSettle(); // Settle entrance animation

      expect(find.text('Transaction added successfully.'), findsOneWidget);

      // Advance by 2500ms duration
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle(); // Settle exit animation

      // Automatically dismissed without manual scroll or swipe
      expect(find.text('Transaction added successfully.'), findsNothing);
    });

    testWidgets('AppSnackBar clears pending duplicate messages before showing new one', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppSnackBar.showSuccess(context, 'First message'),
                    child: const Text('First'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppSnackBar.showSuccess(context, 'Second message'),
                    child: const Text('Second'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('First'));
      await tester.pump();
      expect(find.text('First message'), findsOneWidget);

      // Tapping second immediately clears first and shows second without stacking queue
      await tester.tap(find.text('Second'));
      await tester.pump();

      expect(find.text('Second message'), findsOneWidget);
    });
  });

  group('2. All Accounts Dashboard & Filtering Tests', () {
    test('Persists DashboardFocusMode.allAccounts across restarts and keeps Primary Account separate', () async {
      final acc1 = 'acc_bank';
      final acc2 = 'acc_cash';

      // Set primary account to acc1 (default for new transactions)
      settingsProvider.setPrimaryAccountId(acc1);
      expect(settingsProvider.primaryAccountId, equals(acc1));

      // Set dashboard focus to All Accounts
      settingsProvider.setDashboardFocus(DashboardFocusMode.allAccounts);
      settingsProvider.setDashboardSelectedAccountId(null);
      expect(settingsProvider.dashboardFocus, equals(DashboardFocusMode.allAccounts));
      expect(settingsProvider.dashboardSelectedAccountId, isNull);

      // Primary account for new transactions must remain acc1
      expect(settingsProvider.primaryAccountId, equals(acc1));

      // Simulate app restart by initializing a fresh SettingsProvider instance from database
      final freshSettings = SettingsProvider(database: appDb);
      await freshSettings.loadSettings();

      expect(freshSettings.dashboardFocus, equals(DashboardFocusMode.allAccounts));
      expect(freshSettings.dashboardSelectedAccountId, isNull);
      expect(freshSettings.primaryAccountId, equals(acc1));

      // Switch to specific account
      freshSettings.setDashboardFocus(DashboardFocusMode.selectedAccount);
      freshSettings.setDashboardSelectedAccountId(acc2);

      final restartedSettings2 = SettingsProvider(database: appDb);
      await restartedSettings2.loadSettings();
      expect(restartedSettings2.dashboardFocus, equals(DashboardFocusMode.selectedAccount));
      expect(restartedSettings2.dashboardSelectedAccountId, equals(acc2));
    });

    test('All Accounts unified ledger includes all transactions and excludes internal transfers from totals', () async {
      final now = DateTime.now();

      // Expense 1 on Bank Account (₹1,500 = 150,000 units)
      await txRepo.createTransaction(Transaction(
        id: 'tx_exp_1',
        transactionType: CategoryType.expense,
        accountId: 'acc_bank',
        categoryId: 'cat_groceries',
        amount: const Money(units: 150000),
        description: 'Supermarket Groceries',
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      // Expense 2 on Cash Wallet (₹300 = 30,000 units)
      await txRepo.createTransaction(Transaction(
        id: 'tx_exp_2',
        transactionType: CategoryType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_groceries',
        amount: const Money(units: 30000),
        description: 'Snacks and fruits',
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      // Income 1 on Bank Account (₹10,000 = 1,000,000 units)
      await txRepo.createTransaction(Transaction(
        id: 'tx_inc_1',
        transactionType: CategoryType.income,
        accountId: 'acc_bank',
        categoryId: 'cat_salary',
        amount: const Money(units: 1000000),
        description: 'Monthly Salary',
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      // Internal transfer: Bank -> Cash (₹1,000 = 100,000 units)
      await transferRepo.createTransfer(Transfer(
        id: 'tr_1',
        fromAccountId: 'acc_bank',
        toAccountId: 'acc_cash',
        amount: const Money(units: 100000),
        date: now,
        description: 'ATM Cash Withdrawal',
        createdAt: now,
        updatedAt: now,
      ));

      // 1. Query with accountId: null (All Accounts)
      final allItems = await txRepo.getUnifiedLedger(accountId: null);
      expect(allItems.length, equals(4)); // 2 expenses, 1 income, 1 transfer

      // Calculate totals excluding internal transfers
      int totalExpensesUnits = 0;
      int totalIncomeUnits = 0;
      for (final item in allItems) {
        if (item.type == LedgerItemType.transfer) continue; // EXCLUDE TRANSFERS
        if (item.type == LedgerItemType.expense) {
          totalExpensesUnits += item.amountUnits;
        } else if (item.type == LedgerItemType.income) {
          totalIncomeUnits += item.amountUnits;
        }
      }

      // Expected: ₹1500 + ₹300 = ₹1800 (180,000 units), NOT inflated by ₹1000 transfer
      expect(totalExpensesUnits, equals(180000));
      expect(totalIncomeUnits, equals(1000000)); // ₹10,000 (1,000,000 units)

      // 2. Query with specific account (Bank Account)
      final bankItems = await txRepo.getUnifiedLedger(accountId: 'acc_bank');
      int bankExpenseUnits = 0;
      for (final item in bankItems) {
        if (item.type == LedgerItemType.expense) {
          bankExpenseUnits += item.amountUnits;
        }
      }
      expect(bankExpenseUnits, equals(150000)); // Only ₹1,500
    });
  });

  group('3. Export File Location and Verification Tests', () {
    late Directory tempTestDir;

    setUp(() async {
      tempTestDir = await Directory.systemTemp.createTemp('kals_test_export_');
      StorageHelper.customExportDirectory = tempTestDir.path;
    });

    tearDown(() async {
      StorageHelper.customExportDirectory = null;
      try {
        if (await tempTestDir.exists()) {
          await tempTestDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('StorageHelper verifies existing non-empty file and rejects missing/empty files', () async {
      final validFile = File('${tempTestDir.path}/test_export.xlsx');
      await validFile.writeAsString('Dummy XLSX content');

      final emptyFile = File('${tempTestDir.path}/empty.xlsx');
      await emptyFile.create();

      final nonExistentFile = File('${tempTestDir.path}/does_not_exist.xlsx');

      expect(await StorageHelper.verifyFileExistsAndNonEmpty(validFile), isTrue);
      expect(await StorageHelper.verifyFileExistsAndNonEmpty(emptyFile), isFalse);
      expect(await StorageHelper.verifyFileExistsAndNonEmpty(nonExistentFile), isFalse);
    });

    test('StorageHelper.getExportedFiles discovers .xlsx and .mmb files accurately', () async {
      final file1 = File('${tempTestDir.path}/Kals_Transactions_2026.xlsx');
      await file1.writeAsString('Excel Data');

      final file2 = File('${tempTestDir.path}/Kals_MoneyManager_Backup_2026.mmb');
      await file2.writeAsString('{"backup": true}');

      final ignoredTxt = File('${tempTestDir.path}/notes.txt');
      await ignoredTxt.writeAsString('Text note');

      final list = await StorageHelper.getExportedFiles();
      final names = list.map((f) => f.path.split(Platform.pathSeparator).last).toList();

      expect(names, contains('Kals_Transactions_2026.xlsx'));
      expect(names, contains('Kals_MoneyManager_Backup_2026.mmb'));
      expect(names, isNot(contains('notes.txt')));
    });

    test('StorageHelper.saveToPublicDownloads handles duplicate filenames safely without overwriting', () async {
      final fileName = 'Kals_Transactions_2026-01-01_to_2026-12-31.xlsx';
      final file1 = await StorageHelper.saveToPublicDownloads(
        bytes: [1, 2, 3, 4],
        fileName: fileName,
      );
      expect(file1.existsSync(), isTrue);
      expect(p.basename(file1.path), equals(fileName));
      expect(file1.lengthSync(), equals(4));

      // Save second export with identical requested filename -> should NOT overwrite first file
      final file2 = await StorageHelper.saveToPublicDownloads(
        bytes: [5, 6, 7, 8, 9],
        fileName: fileName,
      );
      expect(file2.existsSync(), isTrue);
      expect(p.basename(file2.path), equals('Kals_Transactions_2026-01-01_to_2026-12-31 (1).xlsx'));
      expect(file2.lengthSync(), equals(5));

      // Original file remains intact and unaltered
      expect(file1.existsSync(), isTrue);
      expect(file1.lengthSync(), equals(4));

      // Save third export with identical filename
      final file3 = await StorageHelper.saveToPublicDownloads(
        bytes: [10, 11],
        fileName: fileName,
      );
      expect(p.basename(file3.path), equals('Kals_Transactions_2026-01-01_to_2026-12-31 (2).xlsx'));
      expect(file3.lengthSync(), equals(2));
    });

    testWidgets('ExportSuccessDialog displays actual file path, copy path button, Open Downloads, and View File', (tester) async {
      final validFile = File(p.join(tempTestDir.path, 'Download', 'Kals_Export_Verified.xlsx'));
      validFile.parent.createSync(recursive: true);
      validFile.writeAsStringSync('Verified content of export');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      );

      final scaffoldContext = tester.element(find.byType(Scaffold));
      await tester.runAsync(() async {
        await ExportSuccessDialog.show(
          scaffoldContext,
          file: validFile,
          type: ExportFileType.excel,
        );
      });
      await tester.pumpAndSettle();

      // Displays filename
      expect(find.text('Kals_Export_Verified.xlsx'), findsOneWidget);
      // Displays clear "Open Downloads" action when directory is Downloads
      expect(find.text('Open Downloads'), findsOneWidget);
      // Displays View File & Share buttons
      expect(find.text('View File'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Export History'), findsOneWidget);
    });

    testWidgets('ExportSuccessDialog does NOT report success when file is missing or failed', (tester) async {
      final nonExistentFile = File(p.join(tempTestDir.path, 'failed_export.xlsx'));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(),
          ),
        ),
      );

      final scaffoldContext = tester.element(find.byType(Scaffold));
      await tester.runAsync(() async {
        await ExportSuccessDialog.show(
          scaffoldContext,
          file: nonExistentFile,
          type: ExportFileType.excel,
        );
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog must NOT appear
      expect(find.text('Export Completed'), findsNothing);
      // Error notification must be displayed
      expect(find.text('Export failed: File could not be verified on device storage.'), findsOneWidget);

      // Cleanly clear snackbars so no pending timers remain
      ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
      await tester.pumpAndSettle();
    });
  });
}
