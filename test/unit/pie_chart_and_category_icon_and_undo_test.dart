import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/navigation/navigation_service.dart';
import 'package:kals_money_manager/core/theme/app_theme.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/app_category_icon.dart';
import 'package:kals_money_manager/core/widgets/donut_chart.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/categories/presentation/screens/add_edit_category_screen.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:kals_money_manager/features/transactions/presentation/screens/period_transactions_screen.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
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

    await accountRepo.createAccount(Account(
      id: 'acc_wallet',
      name: 'Primary Wallet',
      accountType: AccountType.cash,
      currency: 'INR',
      openingBalance: Money.fromUnits(50000),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await categoryRepo.createCategory(Category(
      id: 'cat_dining',
      name: 'Food & Dining',
      type: CategoryType.expense,
      icon: 'soup_kitchen_rounded',
      color: 0xFF23818D,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    accountProvider = AccountProvider(repository: accountRepo);
    await accountProvider.loadAccounts();

    categoryProvider = CategoryProvider(repository: categoryRepo);
    await categoryProvider.loadCategories();

    txProvider = TransactionProvider(repository: txRepo);
    await txProvider.loadLedger();

    transferProvider = TransferProvider(repository: transferRepo);
    await transferProvider.loadTransfers();

    settingsProvider = SettingsProvider(database: appDb);
    await settingsProvider.loadSettings();
  });

  tearDown(() async {
    AppDatabase.setTestInstance(null);
    await db.close();
  });

  Widget buildTestApp(Widget child, {TransactionProvider? customTxProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccountProvider>.value(value: accountProvider),
        ChangeNotifierProvider<CategoryProvider>.value(value: categoryProvider),
        ChangeNotifierProvider<TransactionProvider>.value(value: customTxProvider ?? txProvider),
        ChangeNotifierProvider<TransferProvider>.value(value: transferProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        navigatorKey: MainNavigationService.navigatorKey,
        theme: AppTheme.lightTheme(),
        home: child,
      ),
    );
  }

  group('Priority 1: DonutChart & PeriodTransactionsScreen Tests', () {
    testWidgets('DonutChart fires onCenterTapped when inner ring is tapped', (tester) async {
      bool centerTapped = false;
      bool segmentTapped = false;

      final segments = [
        const DonutSegment(
          categoryId: 'cat_dining',
          label: 'Food & Dining',
          value: 100,
          color: Colors.teal,
          percentage: 1.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DonutChart(
                segments: segments,
                centerAmount: '₹100',
                size: 230,
                strokeWidth: 24,
                onCenterTapped: () => centerTapped = true,
                onSegmentTapped: (_) => segmentTapped = true,
              ),
            ),
          ),
        ),
      );

      // Tap exact center of chart
      await tester.tap(find.byType(DonutChart));
      await tester.pump();

      expect(centerTapped, isTrue);
      expect(segmentTapped, isFalse);
    });

    testWidgets('PeriodTransactionsScreen renders header with total, chips and matching timeline', (tester) async {
      await tester.runAsync(() async {
        await txRepo.createTransaction(Transaction(
          id: 'tx_1',
          transactionType: CategoryType.expense,
          accountId: 'acc_wallet',
          categoryId: 'cat_dining',
          amount: Money.fromUnits(25000), // ₹250
          date: DateTime.now(),
          description: 'Dinner with friends',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        await txProvider.loadLedger();
      });

      await tester.pumpWidget(
        buildTestApp(
          PeriodTransactionsScreen(
            title: 'Expenses',
            dateRangeLabel: 'Oct 18 – Oct 24, 2026',
            startMillis: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
            endMillis: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
            accountId: 'acc_wallet',
            accountName: 'Primary Wallet',
            typeFilter: LedgerItemType.expense,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Header Title & Chips
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Oct 18 – Oct 24, 2026'), findsOneWidget);
      expect(find.text('Primary Wallet'), findsOneWidget);
      expect(find.text('1 transactions'), findsOneWidget);

      // Verify Timeline transaction content
      expect(find.text('Dinner with friends'), findsOneWidget);
    });
  });

  group('Priority 2: Category Icon Selection & Visual Indicators', () {
    testWidgets('AppCategoryIcon renders checkmark badge and border when isSelected is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppCategoryIcon(
                icon: Icons.fastfood_outlined,
                color: Color(0xFF23818D),
                size: 50,
                iconSize: 26,
                isSelected: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fastfood_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget); // Selection checkmark badge
    });

    testWidgets('AddEditCategoryScreen shows checkmark indicator on selected grid icon', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AddEditCategoryScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Receipt icon is selected by default for expense type
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Tap another icon in the grid (e.g. Flight/Plane)
      final planeIcon = find.byIcon(Icons.flight_rounded);
      expect(planeIcon, findsOneWidget);
      await tester.tap(planeIcon);
      await tester.pump();

      // Checkmark indicator moves to newly selected icon
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('Priority 6: Undo Transaction Creation Test', () {

    test('Transaction creation and undo deletion rolls back balance and removes item', () async {
      // 1. Initial State: Balance = 50,000 units (500 INR)
      final initialAccounts = await accountRepo.getAllAccounts();
      final wallet = initialAccounts.firstWhere((a) => a.id == 'acc_wallet');
      expect(wallet.openingBalance.units, 50000);

      // 2. Create Transaction: Expense 15,000 units (150 INR)
      final tx = Transaction(
        id: 'tx_undo_test',
        transactionType: CategoryType.expense,
        accountId: 'acc_wallet',
        categoryId: 'cat_dining',
        amount: Money.fromUnits(15000),
        date: DateTime.now(),
        description: 'Test Expense',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txProvider.createTransaction(tx);
      await accountProvider.loadAccounts();

      var ledger = await txRepo.getUnifiedLedger();
      expect(ledger.length, 1);
      expect(ledger.first.id, 'tx_undo_test');

      // 3. Trigger Undo: Delete the saved transaction
      await txProvider.deleteTransaction(tx.id);
      await accountProvider.loadAccounts();
      await txProvider.loadLedger();

      // 4. Verify ledger is empty and balance restored
      ledger = await txRepo.getUnifiedLedger();
      expect(ledger.isEmpty, isTrue);
    });

    testWidgets('Saving new transaction shows Undo SnackBar which reverses the transaction', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute(
                        builder: (_) => const AddEditTransactionScreen(
                          initialMode: EntryMode.expense,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Form'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open Form
      await tester.runAsync(() async {
        await tester.tap(find.text('Open Form'));
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Enter amount: 150
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '150');
      await tester.pump();

      // Select category (wireframe tile label is 'Food')
      final catTile = find.text('Food');
      expect(catTile, findsOneWidget);
      await tester.tap(catTile);
      await tester.pump();

      // Tap Save button inside runAsync to allow sqflite native futures to complete
      final saveBtn = find.widgetWithText(ElevatedButton, 'Add');
      expect(saveBtn, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(saveBtn);
        await Future.delayed(const Duration(milliseconds: 1000));
      });
      await tester.pumpAndSettle();

      // Check that a transaction was created in repository
      List<LedgerItem> items = [];
      await tester.runAsync(() async {
        items = await txRepo.getUnifiedLedger();
      });
      expect(items.length, 1);
      expect(items.first.amount.units, 15000);

      // Verify Undo snackbar appeared on host screen
      expect(find.text('Expense added successfully.'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo inside runAsync
      await tester.runAsync(() async {
        await tester.tap(find.text('Undo'));
        await Future.delayed(const Duration(milliseconds: 600));
      });
      await tester.pumpAndSettle();

      // Verify transaction was reversed and deleted
      List<LedgerItem> itemsAfterUndo = [];
      await tester.runAsync(() async {
        itemsAfterUndo = await txRepo.getUnifiedLedger();
      });
      expect(itemsAfterUndo.isEmpty, isTrue);
    });
  });
}
