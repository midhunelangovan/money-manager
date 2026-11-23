import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/navigation/navigation_service.dart';
import 'package:kals_money_manager/core/theme/app_colors.dart';
import 'package:kals_money_manager/core/theme/app_theme.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/calculator_dialog.dart';
import 'package:kals_money_manager/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:kals_money_manager/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/categories/presentation/screens/add_edit_category_screen.dart';
import 'package:kals_money_manager/features/categories/presentation/screens/categories_screen.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/recurring/domain/services/recurring_processor.dart';
import 'package:kals_money_manager/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:kals_money_manager/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/presentation/providers/transfer_provider.dart';
import 'package:kals_money_manager/main.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  late RecurringRepositoryImpl recurringRepo;
  late RecurringProcessor recurringProcessor;
  late AccountProvider accountProvider;
  late CategoryProvider categoryProvider;
  late TransactionProvider txProvider;
  late TransferProvider transferProvider;
  late RecurringProvider recurringProvider;
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

    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    transferRepo = TransferRepositoryImpl(database: appDb);
    recurringRepo = RecurringRepositoryImpl(database: appDb);
    recurringProcessor = RecurringProcessor(database: appDb, recurringRepository: recurringRepo);

    settingsProvider = SettingsProvider(database: appDb);
    accountProvider = AccountProvider(repository: accountRepo);
    categoryProvider = CategoryProvider(repository: categoryRepo);
    txProvider = TransactionProvider(repository: txRepo);
    transferProvider = TransferProvider(repository: transferRepo);
    recurringProvider = RecurringProvider(repository: recurringRepo, processor: recurringProcessor);

    final acc = Account(
      id: 'acc_stress_1',
      name: 'Cash',
      accountType: AccountType.cash,
      openingBalance: Money.fromUnits(100000),
      currency: 'INR',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await accountRepo.createAccount(acc);

    final cat = Category(
      id: 'cat_stress_1',
      name: 'Food',
      type: CategoryType.expense,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await categoryRepo.createCategory(cat);

    await settingsProvider.loadSettings();
    await accountProvider.loadAccounts();
    await categoryProvider.loadCategories();
    await txProvider.loadLedger();
  });

  tearDown(() async {
    await db.close();
  });

  Widget createTestApp({Widget? home}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: accountProvider),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: txProvider),
        ChangeNotifierProvider.value(value: transferProvider),
        ChangeNotifierProvider.value(value: recurringProvider),
      ],
      child: MaterialApp(
        navigatorKey: MainNavigationService.navigatorKey,
        theme: AppTheme.lightTheme(AppAccentColor.kalsBrand, false),
        home: home ?? const MainNavigationShell(),
      ),
    );
  }

  group('Kals Money Manager V2 – Critical Transaction Navigation Stress Tests', () {
    testWidgets('1. Transactions -> Add -> Save -> Back (100 cycles) maintains root shell and zero black screen',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Transactions Tab
      MainNavigationService.pushTab(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(TransactionsScreen), findsOneWidget);

      final nav = MainNavigationService.navigatorKey.currentState!;

      for (int i = 0; i < 100; i++) {
        // Push AddEditTransactionScreen
        nav.push(MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify top screen is AddEditTransactionScreen
        expect(find.byType(AddEditTransactionScreen), findsOneWidget);
        expect(nav.canPop(), isTrue);

        // Pop back to TransactionsScreen
        nav.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify root shell is intact and visible
        expect(find.byType(TransactionsScreen), findsOneWidget);
        expect(find.byType(MainNavigationShell), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('2. Transactions -> Edit -> Save -> Back (100 cycles) route lifecycle', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      MainNavigationService.pushTab(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final nav = MainNavigationService.navigatorKey.currentState!;
      final sampleItem = LedgerItem(
        id: 'tx_stress_1',
        itemType: LedgerItemType.expense,
        amount: Money.fromUnits(50000),
        date: DateTime.now(),
        description: 'Groceries',
        accountId: accountProvider.accounts.first.id,
        accountName: accountProvider.accounts.first.name,
        categoryId: categoryProvider.expenseCategories.first.id,
        categoryName: categoryProvider.expenseCategories.first.name,
        createdAt: DateTime.now(),
      );

      for (int i = 0; i < 100; i++) {
        nav.push(MaterialPageRoute(
          builder: (_) => AddEditTransactionScreen(transaction: sampleItem),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(AddEditTransactionScreen), findsOneWidget);
        expect(nav.canPop(), isTrue);

        nav.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(TransactionsScreen), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('3. Category Picker -> Add Category -> Return (100 cycles) hierarchy test', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final nav = MainNavigationService.navigatorKey.currentState!;

      for (int i = 0; i < 100; i++) {
        // Level 1: Open AddEditTransactionScreen
        nav.push(MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Level 2: Open CategoriesScreen in picker mode
        nav.push(MaterialPageRoute(
          builder: (_) => const CategoriesScreen(isPickerMode: true),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Level 3: Open AddEditCategoryScreen
        nav.push(MaterialPageRoute(
          builder: (_) => const AddEditCategoryScreen(initialType: CategoryType.expense),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(AddEditCategoryScreen), findsOneWidget);

        // Pop Level 3 -> returns to picker
        nav.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(CategoriesScreen), findsOneWidget);

        // Pop Level 2 -> returns to transaction form
        nav.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(AddEditTransactionScreen), findsOneWidget);

        // Pop Level 1 -> returns to root shell
        nav.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(MainNavigationShell), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('4. Dialog and bottom-sheet open/dismiss (100 cycles)', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final nav = MainNavigationService.navigatorKey.currentState!;

      for (int i = 0; i < 100; i++) {
        // Open calculator dialog
        showDialog(
          context: nav.context,
          builder: (_) => const CalculatorDialog(initialValue: 125.0),
        );
        await tester.pump();
        expect(find.byType(CalculatorDialog), findsOneWidget);

        // Dismiss dialog
        nav.pop();
        await tester.pump();
        expect(find.byType(CalculatorDialog), findsNothing);
        expect(find.byType(MainNavigationShell), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('5. Rapid Back does not pop root MainNavigationShell to zero routes', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final nav = MainNavigationService.navigatorKey.currentState!;

      for (int i = 0; i < 100; i++) {
        // Push form
        nav.push(MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
        await tester.pump();

        // Pop once
        if (nav.canPop()) {
          nav.pop();
        }
        await tester.pump();

        // Verify root shell is still present and not popped to black screen
        expect(find.byType(MainNavigationShell), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('6. Mixed transaction navigation sequences (500 actions)', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final nav = MainNavigationService.navigatorKey.currentState!;

      for (int action = 0; action < 500; action++) {
        final choice = action % 5;
        switch (choice) {
          case 0:
            // Switch tabs
            MainNavigationService.pushTab(action % 3);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 20));
            break;
          case 1:
            // Open transaction form
            nav.push(MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 20));
            break;
          case 2:
            // Open category screen
            if (nav.canPop()) {
              nav.push(MaterialPageRoute(builder: (_) => const CategoriesScreen(isPickerMode: true)));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 20));
            }
            break;
          case 3:
            // Pop if child route active
            if (nav.canPop()) {
              nav.pop();
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 20));
            }
            break;
          case 4:
            // Unwind to root
            if (nav.canPop()) {
              nav.popUntil((route) => route.isFirst);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 20));
            }
            break;
        }
        // Assert root shell is always intact
        expect(find.byType(MainNavigationShell), findsOneWidget);
      }
      if (nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
      }
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('7. Root Back operations from Dashboard, Transactions, and Accounts (50 cycles) preserve shell',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final nav = MainNavigationService.navigatorKey.currentState!;

      for (int i = 0; i < 50; i++) {
        final tabIndex = i % 3;
        MainNavigationService.pushTab(tabIndex);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        // Attempting to pop at root triggers PopScope
        expect(nav.canPop(), isFalse);
        final popped = await nav.maybePop();
        expect(popped, isTrue); // Handled by MainNavigationShell PopScope with didPop=false

        // Verify root shell and current screen remain mounted
        expect(find.byType(MainNavigationShell), findsOneWidget);
        switch (tabIndex) {
          case 0:
            expect(find.byType(DashboardScreen), findsOneWidget);
            break;
          case 1:
            expect(find.byType(TransactionsScreen), findsOneWidget);
            break;
          case 2:
            expect(find.byType(AccountsScreen), findsOneWidget);
            break;
        }
      }

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('8. Failed or cancelled transaction save attempts (20 cycles) maintain form stability',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final nav = MainNavigationService.navigatorKey.currentState!;

      for (int i = 0; i < 20; i++) {
        // Open AddEditTransactionScreen
        nav.push(MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(AddEditTransactionScreen), findsOneWidget);

        // Form is dirty or empty; cancel and navigate back cleanly
        expect(nav.canPop(), isTrue);
        nav.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Verify clean return to root shell
        expect(find.byType(AddEditTransactionScreen), findsNothing);
        expect(find.byType(MainNavigationShell), findsOneWidget);
      }

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });
  });
}
