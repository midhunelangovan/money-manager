import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/constants/app_category_icons.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  late Database db;
  late AppDatabase appDb;
  late TransactionRepositoryImpl txRepo;
  late TransferRepositoryImpl transferRepo;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;

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
    AppDatabase.setTestInstance(appDb);

    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    transferRepo = TransferRepositoryImpl(database: appDb);
  });

  tearDown(() async {
    await db.close();
  });

  group('Category Icons Semantic Mapping & Distinction Tests', () {
    test('1. Food & Dining and Groceries have distinct and semantically relatable icons', () {
      final foodIcon = AppCategoryIcons.getIconData('restaurant_rounded');
      final foodLegacy1 = AppCategoryIcons.getIconData('restaurant_outlined');
      final foodLegacy2 = AppCategoryIcons.getIconData('restaurant');
      final foodLegacy3 = AppCategoryIcons.getIconData('food & dining');

      expect(foodIcon, equals(Icons.restaurant_rounded));
      expect(foodLegacy1, equals(Icons.restaurant_rounded));
      expect(foodLegacy2, equals(Icons.restaurant_rounded));
      expect(foodLegacy3, equals(Icons.restaurant_rounded));

      final groceryIcon = AppCategoryIcons.getIconData('shopping_basket_rounded');
      final groceryLegacy = AppCategoryIcons.getIconData('groceries');
      expect(groceryIcon, equals(Icons.shopping_basket_rounded));
      expect(groceryLegacy, equals(Icons.shopping_basket_rounded));

      // Must be distinct
      expect(foodIcon, isNot(equals(groceryIcon)));
    });

    test('2. All default category icons map to clear vector icons', () {
      expect(AppCategoryIcons.getIconData('directions_car_rounded'), equals(Icons.directions_car_rounded));
      expect(AppCategoryIcons.getIconData('local_gas_station_rounded'), equals(Icons.local_gas_station_rounded));
      expect(AppCategoryIcons.getIconData('shopping_bag_rounded'), equals(Icons.shopping_bag_rounded));
      expect(AppCategoryIcons.getIconData('receipt_long_rounded'), equals(Icons.receipt_long_rounded));
      expect(AppCategoryIcons.getIconData('medical_services_rounded'), equals(Icons.medical_services_rounded));
      expect(AppCategoryIcons.getIconData('school_rounded'), equals(Icons.school_rounded));
      expect(AppCategoryIcons.getIconData('luggage_rounded'), equals(Icons.luggage_rounded));
      expect(AppCategoryIcons.getIconData('movie_rounded'), equals(Icons.movie_rounded));
      expect(AppCategoryIcons.getIconData('home_rounded'), equals(Icons.home_rounded));
      expect(AppCategoryIcons.getIconData('spa_rounded'), equals(Icons.spa_rounded));
      expect(AppCategoryIcons.getIconData('subscriptions_rounded'), equals(Icons.subscriptions_rounded));
      expect(AppCategoryIcons.getIconData('trending_up_rounded'), equals(Icons.trending_up_rounded));
      expect(AppCategoryIcons.getIconData('account_balance_rounded'), equals(Icons.account_balance_rounded));
      expect(AppCategoryIcons.getIconData('account_balance_wallet_rounded'), equals(Icons.account_balance_wallet_rounded));
    });

    test('3. Database migration seed provides distinct category icons on fresh database', () async {
      final categories = await categoryRepo.getAllCategories();
      final foodCat = categories.firstWhere((c) => c.name == 'Food & Dining');
      final grocCat = categories.firstWhere((c) => c.name == 'Groceries');
      final transCat = categories.firstWhere((c) => c.name == 'Transportation');
      final fuelCat = categories.firstWhere((c) => c.name == 'Bills & Utilities');

      expect(foodCat.icon, equals('restaurant_rounded'));
      expect(grocCat.icon, equals('shopping_basket_rounded'));
      expect(transCat.icon, equals('directions_car_rounded'));
      expect(fuelCat.icon, equals('receipt_long_rounded'));

      expect(foodCat.iconData, equals(Icons.restaurant_rounded));
      expect(grocCat.iconData, equals(Icons.shopping_basket_rounded));
    });

    test('4. Custom user category icon is preserved during migration reconciliation', () async {
      final customCat = Category(
        id: 'cat_custom',
        name: 'Special Food',
        type: CategoryType.expense,
        color: 0xFF123456,
        icon: 'local_pizza_rounded',
        isArchived: false,
        sortOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.createCategory(customCat);

      await DatabaseMigrations.reconcileLegacyCategories(db);

      final reloaded = await categoryRepo.getCategoryById('cat_custom');
      expect(reloaded?.icon, equals('local_pizza_rounded'));
    });
  });

  group('Transaction Repository Filter & Direct Date Picker Tests', () {
    late Account hdfc;
    late Account sbi;
    late Category foodCat;
    late Category salaryCat;

    setUp(() async {
      hdfc = Account(
        id: 'acc_hdfc',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(100000),
        color: 0xFF1E3A5F,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      sbi = Account(
        id: 'acc_sbi',
        name: 'SBI Bank',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(50000),
        color: 0xFF0284C7,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await accountRepo.createAccount(hdfc);
      await accountRepo.createAccount(sbi);

      final cats = await categoryRepo.getAllCategories();
      foodCat = cats.firstWhere((c) => c.name == 'Food & Dining');
      salaryCat = cats.firstWhere((c) => c.name == 'Salary');

      // Seed sample transactions on specific dates
      // 1. Expense: Food, HDFC, 2026-01-15 12:00
      await txRepo.createTransaction(Transaction(
        id: 'tx_1',
        transactionType: CategoryType.expense,
        accountId: hdfc.id,
        categoryId: foodCat.id,
        amount: Money.fromUnits(50000),
        date: DateTime(2026, 1, 15, 12, 0),
        description: 'Dinner at Bistro',
        notes: 'Delicious pasta',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      ));

      // 2. Expense: Food, SBI, 2026-01-15 18:00
      await txRepo.createTransaction(Transaction(
        id: 'tx_2',
        transactionType: CategoryType.expense,
        accountId: sbi.id,
        categoryId: foodCat.id,
        amount: Money.fromUnits(25000),
        date: DateTime(2026, 1, 15, 18, 0),
        description: 'Snacks at Cafe',
        notes: 'Coffee and sandwich',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      ));

      // 3. Income: Salary, HDFC, 2026-01-15 09:00
      await txRepo.createTransaction(Transaction(
        id: 'tx_3',
        transactionType: CategoryType.income,
        accountId: hdfc.id,
        categoryId: salaryCat.id,
        amount: Money.fromUnits(500000),
        date: DateTime(2026, 1, 15, 9, 0),
        description: 'Consulting Income',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      ));

      // 4. Transfer: HDFC -> SBI, 2026-01-15 14:00
      await transferRepo.createTransfer(Transfer(
        id: 'tr_1',
        fromAccountId: hdfc.id,
        toAccountId: sbi.id,
        amount: Money.fromUnits(100000),
        date: DateTime(2026, 1, 15, 14, 0),
        description: 'Monthly savings transfer',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      ));

      // 5. Expense on different date: 2026-10-04
      await txRepo.createTransaction(Transaction(
        id: 'tx_4',
        transactionType: CategoryType.expense,
        accountId: hdfc.id,
        categoryId: foodCat.id,
        amount: Money.fromUnits(15000),
        date: DateTime(2026, 10, 4, 10, 0),
        description: 'Breakfast',
        createdAt: DateTime(2026, 10, 4),
        updatedAt: DateTime(2026, 10, 4),
      ));
    });

    test('5. getUnifiedLedger returns all items when no filter is active', () async {
      final items = await txRepo.getUnifiedLedger();
      expect(items.length, equals(5));
    });

    test('6. Type filter returns only EXPENSE, INCOME, or TRANSFER items', () async {
      final expenses = await txRepo.getUnifiedLedger(typeFilter: LedgerItemType.expense);
      expect(expenses.length, equals(3));
      expect(expenses.every((i) => i.itemType == LedgerItemType.expense), isTrue);

      final incomes = await txRepo.getUnifiedLedger(typeFilter: LedgerItemType.income);
      expect(incomes.length, equals(1));
      expect(incomes.first.id, equals('tx_3'));

      final transfers = await txRepo.getUnifiedLedger(typeFilter: LedgerItemType.transfer);
      expect(transfers.length, equals(1));
      expect(transfers.first.id, equals('tr_1'));
    });

    test('7. Account filter returns matching transactions and transfers for source/dest', () async {
      final hdfcItems = await txRepo.getUnifiedLedger(accountId: hdfc.id);
      expect(hdfcItems.length, equals(4)); // tx_1, tx_3, tr_1, tx_4

      final sbiItems = await txRepo.getUnifiedLedger(accountId: sbi.id);
      expect(sbiItems.length, equals(2)); // tx_2, tr_1 (since sbi is destination)
    });

    test('8. Category filter matches categoryId directly and excludes transfers', () async {
      final foodItems = await txRepo.getUnifiedLedger(categoryId: foodCat.id);
      expect(foodItems.length, equals(3));
      expect(foodItems.every((i) => i.categoryId == foodCat.id), isTrue);
    });

    test('9. Direct Date query filters exactly to [startDate, endDate) boundaries', () async {
      // Query Jan 15, 2026 (00:00:00 to 2026-01-16 00:00:00 exclusive)
      final jan15Items = await txRepo.getUnifiedLedger(
        startDate: DateTime(2026, 1, 15, 0, 0, 0),
        endDate: DateTime(2026, 1, 16, 0, 0, 0),
        exclusiveEndDate: true,
      );
      expect(jan15Items.length, equals(4)); // tx_1, tx_2, tx_3, tr_1
      expect(jan15Items.any((i) => i.id == 'tx_4'), isFalse); // Oct 4 excluded

      // Query Oct 4, 2026
      final oct4Items = await txRepo.getUnifiedLedger(
        startDate: DateTime(2026, 10, 4, 0, 0, 0),
        endDate: DateTime(2026, 10, 5, 0, 0, 0),
        exclusiveEndDate: true,
      );
      expect(oct4Items.length, equals(1));
      expect(oct4Items.first.id, equals('tx_4'));
    });

    test('10. Combined Filters: Expense + HDFC + Food & Dining + 2026-01-15', () async {
      final result = await txRepo.getUnifiedLedger(
        typeFilter: LedgerItemType.expense,
        accountId: hdfc.id,
        categoryId: foodCat.id,
        startDate: DateTime(2026, 1, 15, 0, 0, 0),
        endDate: DateTime(2026, 1, 16, 0, 0, 0),
        exclusiveEndDate: true,
      );

      expect(result.length, equals(1));
      expect(result.first.id, equals('tx_1'));
      expect(result.first.description, equals('Dinner at Bistro'));
    });

    test('11. Search filter matches description, notes, account or category', () async {
      final searchBistro = await txRepo.getUnifiedLedger(searchQuery: 'Bistro');
      expect(searchBistro.length, equals(1));
      expect(searchBistro.first.id, equals('tx_1'));

      final searchNotes = await txRepo.getUnifiedLedger(searchQuery: 'pasta');
      expect(searchNotes.length, equals(1));
      expect(searchNotes.first.id, equals('tx_1'));

      final searchTransfer = await txRepo.getUnifiedLedger(searchQuery: 'savings');
      expect(searchTransfer.length, equals(1));
      expect(searchTransfer.first.id, equals('tr_1'));
    });

    test('12. Sorting orders by transaction date newest first', () async {
      final items = await txRepo.getUnifiedLedger();
      expect(items.first.id, equals('tx_4')); // Oct 4, 2026
      expect(items[1].date.isAfter(items[2].date) || items[1].date.isAtSameMomentAs(items[2].date), isTrue);
    });
  });
}
