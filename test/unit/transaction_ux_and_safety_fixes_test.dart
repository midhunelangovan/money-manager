import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/navigation/navigation_service.dart';
import 'package:kals_money_manager/core/utilities/app_snack_bar.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/date_wise_timeline.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:kals_money_manager/features/transfers/presentation/providers/transfer_provider.dart';
import 'package:provider/provider.dart';
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
  late TransactionProvider txProvider;
  late TransferProvider transferProvider;
  late SettingsProvider settingsProvider;

  late Account testAccountA;
  late Account testAccountB;
  late Category testExpenseCategory;
  late Category testIncomeCategory;

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

    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    transferRepo = TransferRepositoryImpl(database: appDb);

    accountProvider = AccountProvider(repository: accountRepo);
    categoryProvider = CategoryProvider(repository: categoryRepo);
    txProvider = TransactionProvider(repository: txRepo);
    transferProvider = TransferProvider(repository: transferRepo);
    settingsProvider = SettingsProvider();

    testAccountA = Account(
      id: 'acc_a',
      name: 'Checking Account',
      accountType: AccountType.bank,
      openingBalance: const Money(units: 100000), // 1,000.00
      currency: 'USD',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    testAccountB = Account(
      id: 'acc_b',
      name: 'Savings Account',
      accountType: AccountType.bank,
      openingBalance: const Money(units: 50000), // 500.00
      currency: 'USD',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await accountRepo.createAccount(testAccountA);
    await accountRepo.createAccount(testAccountB);

    testExpenseCategory = Category(
      id: 'cat_food',
      name: 'Food',
      type: CategoryType.expense,
      icon: 'restaurant',
      color: 0xFFEF4444,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    testIncomeCategory = Category(
      id: 'cat_salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: 'work',
      color: 0xFF10B981,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await categoryRepo.createCategory(testExpenseCategory);
    await categoryRepo.createCategory(testIncomeCategory);

    await accountProvider.loadAccounts();
    await categoryProvider.loadCategories();
    await txProvider.loadLedger();
  });

  tearDown(() async {
    AppDatabase.setTestInstance(null);
    await db.close();
  });

  Widget buildTestApp(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccountProvider>.value(value: accountProvider),
        ChangeNotifierProvider<CategoryProvider>.value(value: categoryProvider),
        ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
        ChangeNotifierProvider<TransferProvider>.value(value: transferProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        navigatorKey: MainNavigationService.navigatorKey,
        home: Scaffold(body: home),
      ),
    );
  }

  group('1. Success & Undo Notifications Lifecycle', () {
    testWidgets('AppSnackBar.showSuccess automatically dismisses after ~2.5s', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBar.showSuccess(context, 'Added successfully.'),
            child: const Text('Show'),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Added successfully.'), findsOneWidget);

      // Fast forward past duration (2500ms)
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();
      expect(find.text('Added successfully.'), findsNothing);
    });

    testWidgets('AppSnackBar.showSuccessWithUndo stays for 5s and dismisses cleanly', (tester) async {
      bool undoCalled = false;
      await tester.pumpWidget(buildTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBar.showSuccessWithUndo(
              context,
              message: 'Expense added successfully.',
              onUndo: () async => undoCalled = true,
            ),
            child: const Text('Add With Undo'),
          );
        }),
      ));

      await tester.tap(find.text('Add With Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Expense added successfully.'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Advance 3 seconds (still visible within the 5s window)
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Undo'), findsOneWidget);

      // Advance another 2.5 seconds (past 5s window)
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();
      expect(find.text('Expense added successfully.'), findsNothing);
      expect(undoCalled, isFalse);
    });

    testWidgets('Undo within active window invokes onUndo callback and dismisses', (tester) async {
      bool undoCalled = false;

      await tester.pumpWidget(buildTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBar.showSuccessWithUndo(
              context,
              message: 'Expense added successfully.',
              onUndo: () async => undoCalled = true,
            ),
            child: const Text('Show Undo'),
          );
        }),
      ));

      await tester.tap(find.text('Show Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(undoCalled, isTrue);
      expect(find.text('Expense added successfully.'), findsNothing);
    });

    testWidgets('Rapid transaction additions invalidate prior Undo callbacks', (tester) async {
      int tx1UndoCount = 0;
      int tx2UndoCount = 0;

      await tester.pumpWidget(buildTestApp(
        Builder(builder: (context) {
          return Column(
            children: [
              ElevatedButton(
                onPressed: () => AppSnackBar.showSuccessWithUndo(
                  context,
                  message: 'First added',
                  onUndo: () async => tx1UndoCount++,
                ),
                child: const Text('Add 1'),
              ),
              ElevatedButton(
                onPressed: () => AppSnackBar.showSuccessWithUndo(
                  context,
                  message: 'Second added',
                  onUndo: () async => tx2UndoCount++,
                ),
                child: const Text('Add 2'),
              ),
            ],
          );
        }),
      ));

      // Tap Add 1 then immediately Add 2
      await tester.tap(find.text('Add 1'));
      await tester.pump();
      expect(find.text('First added'), findsOneWidget);

      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();
      expect(find.text('First added'), findsNothing);
      expect(find.text('Second added'), findsOneWidget);

      // Tap Undo (applies to second added)
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(tx1UndoCount, equals(0));
      expect(tx2UndoCount, equals(1));
    });
  });

  group('2. Unsaved Transaction Form Warning', () {
    testWidgets('Entering amount in Add Expense and pressing Back triggers Discard confirmation', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const AddEditTransactionScreen(
          initialMode: EntryMode.expense,
        ),
      ));
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(find.byType(TextField).first, '75.50');
      await tester.pump();

      // Simulate system back / pop
      final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      popScope.onPopInvokedWithResult(false, null);
      await tester.pumpAndSettle();

      // Warning dialog appears
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(find.text("You have entered transaction details that haven't been saved. Do you want to discard them?"), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Tapping Keep Editing preserves value and dismisses dialog
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(find.text('75.50'), findsOneWidget);
    });

    testWidgets('Selecting Discard abandons changes without saving', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddEditTransactionScreen(initialMode: EntryMode.expense),
              ),
            ),
            child: const Text('Open Form'),
          );
        }),
      ));

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(find.byType(TextField).first, '120.00');
      await tester.pump();

      // Press toolbar back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsOneWidget);

      // Tap Discard
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Returned to outer screen, no transaction created
      expect(find.text('Open Form'), findsOneWidget);
      expect(txProvider.ledgerItems.any((i) => i.amountUnits == 12000), isFalse);
    });

    testWidgets('Untouched form exits immediately without warning', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddEditTransactionScreen(initialMode: EntryMode.income),
              ),
            ),
            child: const Text('Open Form'),
          );
        }),
      ));

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      // Tap back without typing anything
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Directly popped with no warning dialog
      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(find.text('Open Form'), findsOneWidget);
    });

    testWidgets('Editing existing transaction warns only when a field is modified', (tester) async {
      final existingTx = Transaction(
        id: 'tx_edit_test',
        accountId: testAccountA.id,
        categoryId: testExpenseCategory.id,
        amount: const Money(units: 3000), // 30.00
        transactionType: CategoryType.expense,
        date: DateTime.now(),
        description: 'Original Description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditTransactionScreen(initialTransaction: existingTx),
              ),
            ),
            child: const Text('Edit Form'),
          );
        }),
      ));

      // 1. Open and immediately exit without edits -> no warning
      await tester.tap(find.text('Edit Form'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(find.text('Edit Form'), findsOneWidget);

      // 2. Open and modify amount -> warning triggers
      await tester.tap(find.text('Edit Form'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '45.00');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
    });
  });

  group('3. Direct Deletion of Income and Expense Transactions', () {
    testWidgets('DateGroupedTransactionTimeline opens contextual menu and confirms deletion', (tester) async {
      final item = LedgerItem(
        id: 'tx_delete_timeline',
        itemType: LedgerItemType.income,
        amount: const Money(units: 25000), // 250.00
        date: DateTime(2026, 10, 27),
        description: 'Salary Bonus',
        categoryName: 'Salary',
        accountName: 'Checking Account',
        createdAt: DateTime.now(),
      );

      LedgerItem? deletedItem;

      await tester.pumpWidget(buildTestApp(
        DateGroupedTransactionTimeline(
          transactions: [item],
          onItemDelete: (it) async {
            deletedItem = it;
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Salary Bonus'), findsOneWidget);

      // 1. Long press opens contextual options
      await tester.longPress(find.text('Salary Bonus'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Transaction'), findsOneWidget);

      // 2. Tap Delete Transaction option -> confirmation dialog appears
      await tester.tap(find.text('Delete Transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this transaction?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // 3. Cancel first -> leaves item intact
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deletedItem, isNull);
      expect(find.text('Salary Bonus'), findsOneWidget);

      // 4. Long press again and confirm deletion
      await tester.longPress(find.text('Salary Bonus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Transaction'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deletedItem, isNotNull);
      expect(deletedItem!.id, equals(item.id));
    });

    testWidgets('AddEditTransactionScreen header shows trash icon in edit mode and confirms deletion', (tester) async {
      final tx = Transaction(
        id: 'tx_delete_from_header',
        accountId: testAccountA.id,
        categoryId: testExpenseCategory.id,
        amount: const Money(units: 8000), // 80.00
        transactionType: CategoryType.expense,
        date: DateTime.now(),
        description: 'Groceries',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. In Add mode, trash icon is NOT present
      await tester.pumpWidget(buildTestApp(
        const AddEditTransactionScreen(initialMode: EntryMode.expense),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

      // 2. In Edit mode, trash icon IS present
      await tester.pumpWidget(buildTestApp(
        AddEditTransactionScreen(initialTransaction: tx),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // 3. Tapping trash icon shows TransactionDeleteConfirmationDialog
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Delete this transaction?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // 4. Cancel dismisses dialog without leaving form
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this transaction?'), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    test('Direct deletion of Income transaction updates balance and ledger atomically', () async {
      final tx = Transaction(
        id: 'tx_direct_income_del',
        accountId: testAccountA.id,
        categoryId: testIncomeCategory.id,
        amount: const Money(units: 25000), // 250.00
        transactionType: CategoryType.income,
        date: DateTime.now(),
        description: 'Direct Income Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txProvider.createTransaction(tx);
      await accountProvider.loadAccounts();

      var acc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == testAccountA.id);
      expect(acc.calculatedBalance.units, equals(125000)); // 1000 + 250 = 1250

      var ledger = await txRepo.getUnifiedLedger();
      expect(ledger.any((i) => i.id == tx.id), isTrue);

      // Delete transaction
      await txProvider.deleteTransaction(tx.id);
      await accountProvider.loadAccounts();

      acc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == testAccountA.id);
      expect(acc.calculatedBalance.units, equals(100000)); // Restored to 1000

      ledger = await txRepo.getUnifiedLedger();
      expect(ledger.any((i) => i.id == tx.id), isFalse);
    });

    test('Direct deletion of Expense transaction updates balance and ledger atomically', () async {
      final tx = Transaction(
        id: 'tx_direct_expense_del',
        accountId: testAccountA.id,
        categoryId: testExpenseCategory.id,
        amount: const Money(units: 15000), // 150.00
        transactionType: CategoryType.expense,
        date: DateTime.now(),
        description: 'Direct Expense Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txProvider.createTransaction(tx);
      await accountProvider.loadAccounts();

      var acc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == testAccountA.id);
      expect(acc.calculatedBalance.units, equals(85000)); // 1000 - 150 = 850

      var ledger = await txRepo.getUnifiedLedger();
      expect(ledger.any((i) => i.id == tx.id), isTrue);

      // Delete transaction
      await txProvider.deleteTransaction(tx.id);
      await accountProvider.loadAccounts();

      acc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == testAccountA.id);
      expect(acc.calculatedBalance.units, equals(100000)); // Restored to 1000

      ledger = await txRepo.getUnifiedLedger();
      expect(ledger.any((i) => i.id == tx.id), isFalse);
    });

    test('Transfer deletion adjusts both accounts atomically without orphaned records', () async {
      final transfer = Transfer(
        id: 'tr_test_atomic',
        fromAccountId: testAccountA.id,
        toAccountId: testAccountB.id,
        amount: const Money(units: 10000), // 100.00
        date: DateTime.now(),
        description: 'Transfer Between Accounts',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await transferProvider.createTransfer(transfer);
      await accountProvider.loadAccounts();

      // Check balances after transfer
      var accA = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == testAccountA.id);
      var accB = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == testAccountB.id);
      expect(accA.calculatedBalance.units, equals(90000)); // 1000 - 100 = 900
      expect(accB.calculatedBalance.units, equals(60000)); // 500 + 100 = 600

      // Delete transfer
      await transferProvider.deleteTransfer(transfer.id);
      await accountProvider.loadAccounts();

      // Balances restored
      accA = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == testAccountA.id);
      accB = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == testAccountB.id);
      expect(accA.calculatedBalance.units, equals(100000));
      expect(accB.calculatedBalance.units, equals(50000));

      final ledger = await txRepo.getUnifiedLedger();
      expect(ledger.any((i) => i.id == transfer.id), isFalse);
    });
  });
}
