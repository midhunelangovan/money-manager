import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/error/exceptions.dart';
import 'package:kals_money_manager/core/utilities/id_generator.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:kals_money_manager/features/recurring/domain/services/recurring_processor.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:kals_money_manager/core/database/app_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Financial Ledger & Database Tests', () {
    late Database db;
    late AppDatabase appDb;
    late AccountRepositoryImpl accountRepo;
    late CategoryRepositoryImpl categoryRepo;
    late TransactionRepositoryImpl txRepo;
    late TransferRepositoryImpl transferRepo;
    late RecurringRepositoryImpl recurringRepo;
    late RecurringProcessor recurringProcessor;

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
      transferRepo = TransferRepositoryImpl(database: appDb);
      recurringRepo = RecurringRepositoryImpl(database: appDb);
      recurringProcessor = RecurringProcessor(
        database: appDb,
        recurringRepository: recurringRepo,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Ledger balance calculation: Opening + Income - Expense + Transfers In - Transfers Out', () async {
      final now = DateTime.now();

      // 1. Create 2 Accounts
      final hdfcId = IdGenerator.generate();
      final cashId = IdGenerator.generate();

      await accountRepo.createAccount(Account(
        id: hdfcId,
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: const Money(units: 1000000), // ₹10,000.00
        createdAt: now,
        updatedAt: now,
      ));

      await accountRepo.createAccount(Account(
        id: cashId,
        name: 'Cash in Hand',
        accountType: AccountType.cash,
        openingBalance: const Money(units: 200000), // ₹2,000.00
        createdAt: now,
        updatedAt: now,
      ));

      // 2. Fetch seeded categories
      final incomeCats = await categoryRepo.getAllCategories(type: CategoryType.income);
      final expenseCats = await categoryRepo.getAllCategories(type: CategoryType.expense);
      final salaryCat = incomeCats.first;
      final foodCat = expenseCats.first;

      // 3. Add Income of ₹50,000 to HDFC
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        transactionType: CategoryType.income,
        accountId: hdfcId,
        categoryId: salaryCat.id,
        amount: const Money(units: 5000000), // ₹50,000.00
        date: now,
        description: 'September Salary',
        createdAt: now,
        updatedAt: now,
      ));

      // 4. Add Expense of ₹1,500 from HDFC
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        transactionType: CategoryType.expense,
        accountId: hdfcId,
        categoryId: foodCat.id,
        amount: const Money(units: 150000), // ₹1,500.00
        date: now,
        description: 'Grocery bill',
        createdAt: now,
        updatedAt: now,
      ));

      // 5. Transfer ₹5,000 from HDFC to Cash
      await transferRepo.createTransfer(Transfer(
        id: IdGenerator.generate(),
        fromAccountId: hdfcId,
        toAccountId: cashId,
        amount: const Money(units: 500000), // ₹5,000.00
        date: now,
        description: 'ATM Withdrawal',
        createdAt: now,
        updatedAt: now,
      ));

      // 6. Check Balances
      // HDFC: 10,000 (opening) + 50,000 (income) - 1,500 (expense) - 5,000 (transfer out) = ₹53,500.00 (5350000 units)
      final hdfcBalance = await accountRepo.getAccountWithBalance(hdfcId);
      expect(hdfcBalance, isNotNull);
      expect(hdfcBalance!.calculatedBalance.units, equals(5350000));
      expect(hdfcBalance.totalIncome.units, equals(5000000));
      expect(hdfcBalance.totalExpense.units, equals(150000));
      expect(hdfcBalance.totalTransfersOut.units, equals(500000));

      // Cash: 2,000 (opening) + 5,000 (transfer in) = ₹7,000.00 (700000 units)
      final cashBalance = await accountRepo.getAccountWithBalance(cashId);
      expect(cashBalance, isNotNull);
      expect(cashBalance!.calculatedBalance.units, equals(700000));
      expect(cashBalance.totalTransfersIn.units, equals(500000));
    });

    test('Foreign key enforcement rejects invalid account reference', () async {
      final now = DateTime.now();
      final cats = await categoryRepo.getAllCategories();

      expect(
        () => txRepo.createTransaction(Transaction(
          id: IdGenerator.generate(),
          transactionType: CategoryType.expense,
          accountId: 'non_existent_acc',
          categoryId: cats.first.id,
          amount: const Money(units: 1000),
          date: now,
          description: 'Test',
          createdAt: now,
          updatedAt: now,
        )),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Recurring transaction processor is strictly idempotent and prevents duplicates', () async {
      final now = DateTime.now();
      final accounts = await accountRepo.getAllAccounts();
      final cats = await categoryRepo.getAllCategories(type: CategoryType.expense);

      final recurringSchedule = RecurringTransaction(
        id: 'rec_rent_101',
        transactionType: CategoryType.expense,
        accountId: accounts.first.id,
        categoryId: cats.first.id,
        amount: const Money(units: 1500000), // ₹15,000
        description: 'House Rent',
        frequency: RecurringFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 1),
        nextExecutionDate: DateTime(2026, 1, 1),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await recurringRepo.createRecurring(recurringSchedule);

      // Run processor for asOfDate: Jan 2, 2026
      final res1 = await recurringProcessor.processDueTransactions(
        asOfDate: DateTime(2026, 1, 2),
      );
      expect(res1.generatedTransactionsCount, equals(1));

      // Run processor second time on same date -> MUST produce 0 duplicate transactions!
      final res2 = await recurringProcessor.processDueTransactions(
        asOfDate: DateTime(2026, 1, 2),
      );
      expect(res2.generatedTransactionsCount, equals(0));

      // Verify transaction list only has 1 instance
      final txs = await txRepo.getTransactions(const TransactionFilter());
      final rentTxs = txs.where((t) => t.recurringTransactionId == 'rec_rent_101').toList();
      expect(rentTxs.length, equals(1));
    });
  });
}
