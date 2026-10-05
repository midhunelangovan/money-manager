import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/id_generator.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:kals_money_manager/features/transfers/presentation/providers/transfer_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Category, Reports Filter, Drill-Down & Transfer Tests', () {
    late Database db;
    late AppDatabase appDb;
    late CategoryRepositoryImpl catRepo;
    late CategoryProvider catProvider;
    late AccountRepositoryImpl accountRepo;
    late AccountProvider accountProvider;
    late TransactionRepositoryImpl txRepo;
    late TransactionProvider txProvider;
    late TransferRepositoryImpl transferRepo;
    late TransferProvider transferProvider;

    late String canaraBankId;
    late String hdfcBankId;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      );
      appDb = AppDatabase.withDatabase(db);
      catRepo = CategoryRepositoryImpl(database: appDb);
      catProvider = CategoryProvider(repository: catRepo);
      accountRepo = AccountRepositoryImpl(database: appDb);
      accountProvider = AccountProvider(repository: accountRepo);
      txRepo = TransactionRepositoryImpl(database: appDb);
      txProvider = TransactionProvider(repository: txRepo);
      transferRepo = TransferRepositoryImpl(database: appDb);
      transferProvider = TransferProvider(repository: transferRepo);

      final now = DateTime.now();
      canaraBankId = IdGenerator.generate();
      hdfcBankId = IdGenerator.generate();

      await accountRepo.createAccount(Account(
        id: canaraBankId,
        name: 'Canara Bank',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 404376), // ₹4,043.76
        createdAt: now,
        updatedAt: now,
      ));

      await accountRepo.createAccount(Account(
        id: hdfcBankId,
        name: 'HDFC',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 562083), // ₹5,620.83
        createdAt: now,
        updatedAt: now,
      ));

      await accountProvider.loadAccounts();
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Category Creation & Immediate Persistence in Database', () async {
      final now = DateTime.now();
      final newCat = Category(
        id: IdGenerator.generate(),
        name: 'Doctor & Medicine',
        type: CategoryType.expense,
        icon: 'local_hospital_rounded',
        color: 0xFFEF4444,
        createdAt: now,
        updatedAt: now,
      );

      // Create via provider
      await catProvider.createCategory(newCat);

      // Verify category exists in provider immediately
      expect(catProvider.expenseCategories.any((c) => c.id == newCat.id), isTrue);
      expect(catProvider.expenseCategories.firstWhere((c) => c.id == newCat.id).name, 'Doctor & Medicine');

      // Verify category persisted directly in database
      final fromDb = await catRepo.getCategoryById(newCat.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.name, 'Doctor & Medicine');
      expect(fromDb.icon, 'local_hospital_rounded');
      expect(fromDb.color, 0xFFEF4444);
    });

    test('2. Reports Drill-Down: Chart Category Total matches SUM of Drill-Down Transactions', () async {
      final now = DateTime(2026, 1, 15);
      final foodCatId = IdGenerator.generate();
      await catRepo.createCategory(Category(
        id: foodCatId,
        name: 'Food & Dining',
        type: CategoryType.expense,
        createdAt: now,
        updatedAt: now,
      ));

      // Insert 3 Food transactions in Jan 2026
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: foodCatId,
        amount: const Money(units: 45000), // ₹450
        transactionType: CategoryType.expense,
        date: DateTime(2026, 1, 3),
        description: 'Dinner',
        createdAt: now,
        updatedAt: now,
      ));

      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: foodCatId,
        amount: const Money(units: 28000), // ₹280
        transactionType: CategoryType.expense,
        date: DateTime(2026, 1, 7),
        description: 'Lunch',
        createdAt: now,
        updatedAt: now,
      ));

      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: foodCatId,
        amount: const Money(units: 62000), // ₹620
        transactionType: CategoryType.expense,
        date: DateTime(2026, 1, 12),
        description: 'Groceries',
        createdAt: now,
        updatedAt: now,
      ));

      // Query month range [2026-01-01, 2026-02-01)
      final janStart = DateTime(2026, 1, 1);
      final janEnd = DateTime(2026, 2, 1);
      final monthItems = await txProvider.getItemsForRange(
        startDate: janStart,
        endDate: janEnd,
        exclusiveEndDate: true,
      );

      // Calculate category sum from month dataset
      final foodMonthItems = monthItems.where((i) => i.categoryId == foodCatId).toList();
      final totalFoodUnits = foodMonthItems.fold<int>(0, (sum, i) => sum + i.amountUnits);
      expect(totalFoodUnits, 45000 + 28000 + 62000); // 135000 (₹1,350)
      expect(foodMonthItems.length, 3);
    });

    test('3. Account-to-Account Transfer: Updates Balances, No Income or Expense Created', () async {
      // Starting balances:
      // Canara Bank: ₹4,043.76
      // HDFC: ₹5,620.83
      final canaraBefore = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == canaraBankId);
      final hdfcBefore = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == hdfcBankId);

      expect(canaraBefore.balanceUnits, 404376);
      expect(hdfcBefore.balanceUnits, 562083);

      // Transfer ₹1,000.00 from Canara Bank to HDFC
      final transferAmount = const Money(units: 100000); // ₹1,000.00
      final now = DateTime(2026, 10, 3);

      await transferProvider.createTransfer(Transfer(
        id: IdGenerator.generate(),
        fromAccountId: canaraBankId,
        toAccountId: hdfcBankId,
        amount: transferAmount,
        date: now,
        description: 'Monthly savings transfer',
        createdAt: now,
        updatedAt: now,
      ));

      // Reload accounts
      await accountProvider.loadAccounts();

      final canaraAfter = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == canaraBankId);
      final hdfcAfter = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == hdfcBankId);

      // Verify Canara Bank balance decreased by ₹1,000.00
      expect(canaraAfter.balanceUnits, 404376 - 100000); // ₹3,043.76

      // Verify HDFC balance increased by ₹1,000.00
      expect(hdfcAfter.balanceUnits, 562083 + 100000); // ₹6,620.83

      // Verify reports / summary: Total income and expense remain 0
      final summary = await txProvider.getSummaryForRange();
      expect(summary.totalIncome.units, 0, reason: 'Transfers must not create Income');
      expect(summary.totalExpense.units, 0, reason: 'Transfers must not create Expense');
    });

    test('4. Account Detail Transaction Query: Shows only transactions related to that account', () async {
      final now = DateTime(2026, 10, 3);
      final salaryCatId = IdGenerator.generate();
      await catRepo.createCategory(Category(
        id: salaryCatId,
        name: 'Salary',
        type: CategoryType.income,
        createdAt: now,
        updatedAt: now,
      ));

      // Canara Bank transaction
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: canaraBankId,
        categoryId: salaryCatId,
        amount: const Money(units: 500000), // ₹5,000
        transactionType: CategoryType.income,
        date: DateTime(2026, 10, 1),
        description: 'October Salary',
        createdAt: now,
        updatedAt: now,
      ));

      // HDFC transaction
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        accountId: hdfcBankId,
        categoryId: salaryCatId,
        amount: const Money(units: 200000), // ₹2,000
        transactionType: CategoryType.income,
        date: DateTime(2026, 10, 2),
        description: 'Bonus',
        createdAt: now,
        updatedAt: now,
      ));

      // Transfer from Canara to HDFC
      await transferRepo.createTransfer(Transfer(
        id: IdGenerator.generate(),
        fromAccountId: canaraBankId,
        toAccountId: hdfcBankId,
        amount: const Money(units: 50000),
        date: DateTime(2026, 10, 3),
        description: 'Transfer',
        createdAt: now,
        updatedAt: now,
      ));

      // Query Canara Bank history: Should have Salary + Transfer = 2 items
      final canaraItems = await txProvider.getItemsForRange(accountId: canaraBankId);
      expect(canaraItems.length, 2);

      // Query HDFC history: Should have Bonus + Transfer = 2 items
      final hdfcItems = await txProvider.getItemsForRange(accountId: hdfcBankId);
      expect(hdfcItems.length, 2);
    });

    test('5. Onboarding State Detection: Fresh Install shows Onboarding, Existing User Skips', () async {
      // 1. Fresh empty database instance
      final freshDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      );
      final freshAppDb = AppDatabase.withDatabase(freshDb);
      final settings = SettingsProvider(database: freshAppDb);
      await settings.loadSettings();

      // Should be false on fresh install
      expect(settings.isOnboardingCompleted, isFalse);

      // Complete onboarding
      settings.setProfileName('Midhun');
      settings.setOnboardingCompleted(true);
      expect(settings.profileName, 'Midhun');
      expect(settings.isOnboardingCompleted, isTrue);

      // Verify reloaded settings retains completion state
      final reloadedSettings = SettingsProvider(database: freshAppDb);
      await reloadedSettings.loadSettings();
      expect(reloadedSettings.profileName, 'Midhun');
      expect(reloadedSettings.isOnboardingCompleted, isTrue);

      await freshDb.close();
    });
  });
}
