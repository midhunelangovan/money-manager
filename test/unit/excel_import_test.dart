import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_import_service.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  late Database db;
  late AppDatabase appDb;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl txRepo;
  late TransferRepositoryImpl transferRepo;
  late RecurringRepositoryImpl recurringRepo;
  late ExcelImportService importService;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('excel_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
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
    importService = ExcelImportService(database: appDb);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  File createMockLegacyExcelFile() {
    final excel = Excel.createExcel();
    // Default sheet is 'Sheet1'
    excel.rename('Sheet1', 'Expenses');

    // 1. Expenses Sheet
    final expensesSheet = excel['Expenses'];
    // Row 1: Title row
    expensesSheet.appendRow([
      TextCellValue('expenses list for the period January 1, 2025 – January 1, 2026'),
    ]);
    // Row 2: Header row
    expensesSheet.appendRow([
      TextCellValue('Date and time'),
      TextCellValue('Category'),
      TextCellValue('Account'),
      TextCellValue('Amount in default currency'),
      TextCellValue('Default currency'),
      TextCellValue('Amount in account currency'),
      TextCellValue('Account currency'),
      TextCellValue('Transaction amount in transaction currency'),
      TextCellValue('Transaction currency'),
      TextCellValue('Tags'),
      TextCellValue('Comment'),
    ]);
    // Row 3: Data row 1
    expensesSheet.appendRow([
      TextCellValue('2025-12-31 14:30:00'),
      TextCellValue('CBE Hostel split payback'),
      TextCellValue('HDFC'),
      TextCellValue('126.67'),
      TextCellValue('INR'),
      TextCellValue('126.67'),
      TextCellValue('INR'),
      TextCellValue('126.67'),
      TextCellValue('INR'),
      TextCellValue('legacyTag1'),
      TextCellValue('appa gave for monthly expenses'),
    ]);
    // Row 4: Data row 2
    expensesSheet.appendRow([
      TextCellValue('2025-12-30 10:15:00'),
      TextCellValue('Food & Dining'),
      TextCellValue('Cash'),
      DoubleCellValue(50.00),
      TextCellValue('INR'),
      DoubleCellValue(50.00),
      TextCellValue('INR'),
      DoubleCellValue(50.00),
      TextCellValue('INR'),
      TextCellValue('foodTag'),
      TextCellValue('Lunch at restaurant'),
    ]);
    // Row 5: Data row 3 (for testing suggestions and unmapped)
    expensesSheet.appendRow([
      TextCellValue('2025-12-29 11:00:00'),
      TextCellValue('Medical'),
      TextCellValue('SBI Bank'),
      DoubleCellValue(250.00),
      TextCellValue('INR'),
      DoubleCellValue(250.00),
      TextCellValue('INR'),
      DoubleCellValue(250.00),
      TextCellValue('INR'),
      TextCellValue(''),
      TextCellValue('Pharmacy prescription'),
    ]);

    // 2. Income Sheet
    final incomeSheet = excel['Income'];
    // Row 1: Title row
    incomeSheet.appendRow([
      TextCellValue('income list for the period January 1, 2025 – January 1, 2026'),
    ]);
    // Row 2: Header row
    incomeSheet.appendRow([
      TextCellValue('Date and time'),
      TextCellValue('Category'),
      TextCellValue('Account'),
      TextCellValue('Amount in default currency'),
      TextCellValue('Default currency'),
      TextCellValue('Amount in account currency'),
      TextCellValue('Account currency'),
      TextCellValue('Transaction amount in transaction currency'),
      TextCellValue('Transaction currency'),
      TextCellValue('Tags'),
      TextCellValue('Comment'),
    ]);
    // Row 3: Data row
    incomeSheet.appendRow([
      TextCellValue('2025-12-01 09:00:00'),
      TextCellValue('Salary'),
      TextCellValue('HDFC'),
      TextCellValue('50000.00'),
      TextCellValue('INR'),
      TextCellValue('50000.00'),
      TextCellValue('INR'),
      TextCellValue('50000.00'),
      TextCellValue('INR'),
      TextCellValue(''),
      TextCellValue('Monthly salary payment'),
    ]);

    // 3. Transfers Sheet
    final transfersSheet = excel['Transfers'];
    // Row 1: Title row
    transfersSheet.appendRow([
      TextCellValue('transfers list for the period January 1, 2025 – January 1, 2026'),
    ]);
    // Row 2: Header row
    transfersSheet.appendRow([
      TextCellValue('Date and time'),
      TextCellValue('Outgoing'),
      TextCellValue('Incoming'),
      TextCellValue('Amount in outgoing currency'),
      TextCellValue('Outgoing currency'),
      TextCellValue('Amount in incoming currency'),
      TextCellValue('Incoming currency'),
      TextCellValue('Comment'),
    ]);
    // Row 3: Data row
    transfersSheet.appendRow([
      TextCellValue('2025-12-15 18:00:00'),
      TextCellValue('HDFC'),
      TextCellValue('CANARA BANK'),
      TextCellValue('1500.00'),
      TextCellValue('INR'),
      TextCellValue('1500.00'),
      TextCellValue('INR'),
      TextCellValue('ATM cash withdrawal transfer'),
    ]);

    final filePath = '${tempDir.path}/2025 FY.xlsx';
    final file = File(filePath);
    final bytes = excel.encode()!;
    file.writeAsBytesSync(bytes);
    return file;
  }

  group('Legacy Excel Importer Tests', () {
    test('1. Workbook reading detects sheets properly', () async {
      final file = createMockLegacyExcelFile();
      final info = await importService.readWorkbook(file);

      expect(info.fileName, '2025 FY.xlsx');
      expect(info.sheetNames.contains('Expenses'), isTrue);
      expect(info.sheetNames.contains('Income'), isTrue);
      expect(info.sheetNames.contains('Transfers'), isTrue);
    });

    test('2. Header detection ignores title row and identifies Row 2', () async {
      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Expenses',
      );

      expect(analysis.columnMapping.headerRowIndex, 1); // 0-indexed: row 1 is 2nd row
      expect(analysis.sheetType, ExcelSheetType.expenses);
      expect(analysis.totalRows, 3);
      expect(analysis.rawRows.length, 3);
    });

    test('3. Field mapping preserves comment, INR currency, amounts, and ignores Tags', () async {
      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Expenses',
      );

      final row1 = analysis.rawRows[0];
      expect(row1.legacyCategory, 'CBE Hostel split payback');
      expect(row1.legacyAccount, 'HDFC');
      expect(row1.parsedAmount?.units, Money.parse('126.67').units);
      expect(row1.currency, 'INR');
      expect(row1.comment, 'appa gave for monthly expenses');
      expect(row1.parsedDate?.year, 2025);
      expect(row1.parsedDate?.month, 12);
      expect(row1.parsedDate?.day, 31);

      final row2 = analysis.rawRows[1];
      expect(row2.legacyCategory, 'Food & Dining');
      expect(row2.legacyAccount, 'Cash');
      expect(row2.parsedAmount?.units, Money.parse('50.00').units);
    });

    test('4. Missing accounts and categories are detected and default to Create New with safe persistence', () async {
      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Expenses',
      );

      // Initially DB has no HDFC or CBE Hostel category -> detected and defaulted to createNew (pending creation)
      expect(analysis.accountMappings['HDFC']!.status, MappingStatus.createNew);
      expect(analysis.categoryMappings['CBE Hostel split payback']!.status, MappingStatus.createNew);

      // User creates/maps the target accounts and categories
      final targetAcc = Account(
        id: 'acc_hdfc_mapped',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await accountRepo.createAccount(targetAcc);

      final targetCat = Category(
        id: 'cat_cbe_mapped',
        name: 'CBE Hostel split payback',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.createCategory(targetCat);

      final mappedAccounts = {
        'HDFC': const AccountMappingEntry(
          legacyName: 'HDFC',
          targetAccountId: 'acc_hdfc_mapped',
          targetAccountName: 'HDFC Bank',
          status: MappingStatus.exactMatch,
        ),
        'Cash': const AccountMappingEntry(
          legacyName: 'Cash',
          targetAccountId: 'acc_hdfc_mapped',
          targetAccountName: 'HDFC Bank',
          status: MappingStatus.exactMatch,
        ),
        'SBI Bank': const AccountMappingEntry(
          legacyName: 'SBI Bank',
          targetAccountId: 'acc_hdfc_mapped',
          targetAccountName: 'HDFC Bank',
          status: MappingStatus.exactMatch,
        ),
      };

      final mappedCategories = {
        'CBE Hostel split payback': const CategoryMappingEntry(
          legacyName: 'CBE Hostel split payback',
          targetCategoryId: 'cat_cbe_mapped',
          targetCategoryName: 'CBE Hostel split payback',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
        'Food & Dining': const CategoryMappingEntry(
          legacyName: 'Food & Dining',
          targetCategoryId: 'cat_cbe_mapped',
          targetCategoryName: 'CBE Hostel split payback',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
        'Medical': const CategoryMappingEntry(
          legacyName: 'Medical',
          targetCategoryId: 'cat_cbe_mapped',
          targetCategoryName: 'CBE Hostel split payback',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
      };

      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: mappedAccounts,
        categoryMappings: mappedCategories,
      );

      final result = await importService.executeImport(
        preview: preview,
        skipDuplicates: true,
      );

      expect(result.importedCount, 3);

      // Verify transactions in DB
      final txs = await txRepo.getTransactions(const TransactionFilter(limit: 100));
      expect(txs.length, 3);
      expect(txs.any((t) => t.notes == 'appa gave for monthly expenses'), isTrue);
    });

    test('5. Income sheet import maps to Income transactions correctly', () async {
      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Income',
      );

      expect(analysis.sheetType, ExcelSheetType.income);
      expect(analysis.totalRows, 1);

      await accountRepo.createAccount(Account(
        id: 'acc_inc_hdfc',
        name: 'HDFC',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await categoryRepo.createCategory(Category(
        id: 'cat_inc_salary',
        name: 'Salary',
        type: CategoryType.income,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: {
          'HDFC': const AccountMappingEntry(
            legacyName: 'HDFC',
            targetAccountId: 'acc_inc_hdfc',
            targetAccountName: 'HDFC',
            status: MappingStatus.exactMatch,
          ),
        },
        categoryMappings: {
          'Salary': const CategoryMappingEntry(
            legacyName: 'Salary',
            targetCategoryId: 'cat_inc_salary',
            targetCategoryName: 'Salary',
            categoryType: CategoryType.income,
            status: MappingStatus.exactMatch,
          ),
        },
      );

      expect(preview.validItems.length, 1);

      final result = await importService.executeImport(
        preview: preview,
        skipDuplicates: true,
      );

      expect(result.importedCount, 1);

      final txs = await txRepo.getTransactions(const TransactionFilter(limit: 100));
      expect(txs.length, 1);
      expect(txs.first.transactionType, CategoryType.income);
      expect(txs.first.amount.units, Money.parse('50000.00').units);
    });

    test('6. Transfers sheet import maps to Transfers correctly without altering income/expense', () async {
      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Transfers',
      );
      expect(analysis.accountMappings['CANARA BANK']!.status, MappingStatus.createNew);

      await accountRepo.createAccount(Account(
        id: 'acc_tr_hdfc',
        name: 'HDFC',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await accountRepo.createAccount(Account(
        id: 'acc_tr_canara',
        name: 'CANARA BANK',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: {
          'HDFC': const AccountMappingEntry(
            legacyName: 'HDFC',
            targetAccountId: 'acc_tr_hdfc',
            targetAccountName: 'HDFC',
            status: MappingStatus.exactMatch,
          ),
          'CANARA BANK': const AccountMappingEntry(
            legacyName: 'CANARA BANK',
            targetAccountId: 'acc_tr_canara',
            targetAccountName: 'CANARA BANK',
            status: MappingStatus.exactMatch,
          ),
        },
        categoryMappings: {},
      );

      expect(preview.validItems.length, 1);

      final result = await importService.executeImport(
        preview: preview,
        skipDuplicates: true,
      );

      expect(result.importedCount, 1);

      // Transfers table should have the transfer
      final transfers = await transferRepo.getAllTransfers();
      expect(transfers.length, 1);
      expect(transfers.first.description, 'ATM cash withdrawal transfer');
      expect(transfers.first.amount.units, Money.parse('1500.00').units);

      // Transactions table should NOT have income/expense records for this transfer
      final txs = await txRepo.getTransactions(const TransactionFilter(limit: 100));
      expect(txs.isEmpty, isTrue);
    });

    test('7. Duplicate detection identifies duplicates and respects skipDuplicates setting', () async {
      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Expenses',
      );

      await accountRepo.createAccount(Account(
        id: 'acc_dup_hdfc',
        name: 'HDFC',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await categoryRepo.createCategory(Category(
        id: 'cat_dup_gen',
        name: 'General',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final mappings = {
        'HDFC': const AccountMappingEntry(legacyName: 'HDFC', targetAccountId: 'acc_dup_hdfc', targetAccountName: 'HDFC', status: MappingStatus.exactMatch),
        'Cash': const AccountMappingEntry(legacyName: 'Cash', targetAccountId: 'acc_dup_hdfc', targetAccountName: 'HDFC', status: MappingStatus.exactMatch),
        'SBI Bank': const AccountMappingEntry(legacyName: 'SBI Bank', targetAccountId: 'acc_dup_hdfc', targetAccountName: 'HDFC', status: MappingStatus.exactMatch),
      };

      final catMappings = {
        'CBE Hostel split payback': const CategoryMappingEntry(legacyName: 'CBE Hostel split payback', targetCategoryId: 'cat_dup_gen', targetCategoryName: 'General', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
        'Food & Dining': const CategoryMappingEntry(legacyName: 'Food & Dining', targetCategoryId: 'cat_dup_gen', targetCategoryName: 'General', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
        'Medical': const CategoryMappingEntry(legacyName: 'Medical', targetCategoryId: 'cat_dup_gen', targetCategoryName: 'General', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
      };

      final preview1 = await importService.buildPreview(
        analysis: analysis,
        accountMappings: mappings,
        categoryMappings: catMappings,
      );

      // First import
      await importService.executeImport(
        preview: preview1,
        skipDuplicates: true,
      );

      // Second import analysis of the same file
      final preview2 = await importService.buildPreview(
        analysis: analysis,
        accountMappings: mappings,
        categoryMappings: catMappings,
      );

      expect(preview2.duplicateItems.length, 3);

      // Execute with skipDuplicates = true
      final result2 = await importService.executeImport(
        preview: preview2,
        skipDuplicates: true,
      );

      expect(result2.importedCount, 0);
      expect(result2.skippedDuplicates, 3);

      // Verify no duplicate transactions were added
      final txs = await txRepo.getTransactions(const TransactionFilter(limit: 100));
      expect(txs.length, 3);
    });

    test('8. Existing Kals data remains untouched (pure ADD operation)', () async {
      // Create existing account, category and transaction
      final existingAccount = Account(
        id: 'existing_acc_1',
        name: 'My Personal Savings',
        accountType: AccountType.bank,
        openingBalance: Money(units: 100000),
        color: 0xFF2196F3,
        icon: 'savings',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await accountRepo.createAccount(existingAccount);

      final existingCat = Category(
        id: 'cat_food_drinks',
        name: 'Food & Drinks',
        type: CategoryType.expense,
        icon: 'fastfood',
        color: 0xFFFF5722,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.createCategory(existingCat);

      final existingTx = Transaction(
        id: 'existing_tx_1',
        transactionType: CategoryType.expense,
        amount: Money(units: 50000),
        accountId: 'existing_acc_1',
        categoryId: 'cat_food_drinks',
        date: DateTime(2025, 1, 1),
        description: 'Food',
        notes: 'Pre-existing transaction',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txRepo.createTransaction(existingTx);

      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Expenses',
      );

      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: {
          'HDFC': const AccountMappingEntry(legacyName: 'HDFC', targetAccountId: 'existing_acc_1', targetAccountName: 'My Personal Savings', status: MappingStatus.exactMatch),
          'Cash': const AccountMappingEntry(legacyName: 'Cash', targetAccountId: 'existing_acc_1', targetAccountName: 'My Personal Savings', status: MappingStatus.exactMatch),
          'SBI Bank': const AccountMappingEntry(legacyName: 'SBI Bank', targetAccountId: 'existing_acc_1', targetAccountName: 'My Personal Savings', status: MappingStatus.exactMatch),
        },
        categoryMappings: {
          'CBE Hostel split payback': const CategoryMappingEntry(legacyName: 'CBE Hostel split payback', targetCategoryId: 'cat_food_drinks', targetCategoryName: 'Food & Drinks', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
          'Food & Dining': const CategoryMappingEntry(legacyName: 'Food & Dining', targetCategoryId: 'cat_food_drinks', targetCategoryName: 'Food & Drinks', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
          'Medical': const CategoryMappingEntry(legacyName: 'Medical', targetCategoryId: 'cat_food_drinks', targetCategoryName: 'Food & Drinks', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
        },
      );

      await importService.executeImport(
        preview: preview,
        skipDuplicates: true,
      );

      // Verify original account and transaction still exist untouched
      final acc = await accountRepo.getAccountById('existing_acc_1');
      expect(acc, isNotNull);
      expect(acc!.name, 'My Personal Savings');

      final tx = await txRepo.getTransactionById('existing_tx_1');
      expect(tx, isNotNull);
      expect(tx!.notes, 'Pre-existing transaction');
    });

    test('9. Legacy analysis classifies exact match, suggested match, and unmapped values', () async {
      // Create some existing accounts and categories
      await accountRepo.createAccount(Account(
        id: 'acc_hdfc_id',
        name: 'HDFC',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await accountRepo.createAccount(Account(
        id: 'acc_canara_id',
        name: 'CANARA BANK',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await accountRepo.createAccount(Account(
        id: 'acc_cash_id',
        name: 'Cash',
        accountType: AccountType.cash,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Expenses',
      );

      // Legacy 'HDFC' matches existing 'HDFC'
      final hdfcMapping = analysis.accountMappings['HDFC'];
      expect(hdfcMapping, isNotNull);
      expect(hdfcMapping!.status, MappingStatus.exactMatch);
      expect(hdfcMapping.targetAccountId, 'acc_hdfc_id');

      // Legacy 'Cash' matches default seeded Cash account
      final cashMapping = analysis.accountMappings['Cash'];
      expect(cashMapping, isNotNull);
      expect(cashMapping!.status, MappingStatus.exactMatch);

      // Legacy 'Food & Dining' matches seeded 'Food & Dining'
      final foodMapping = analysis.categoryMappings['Food & Dining'];
      expect(foodMapping, isNotNull);
      expect(foodMapping!.status, MappingStatus.exactMatch);

      // Legacy 'Medical' should suggest existing seeded 'Health' (via alias)
      final medicalMapping = analysis.categoryMappings['Medical'];
      expect(medicalMapping, isNotNull);
      expect(medicalMapping!.status, MappingStatus.suggested);
      expect(medicalMapping.targetCategoryName?.toLowerCase(), contains('health'));

      // Legacy 'CBE Hostel split payback' has no match -> defaults to createNew (pending creation)
      final cbeMapping = analysis.categoryMappings['CBE Hostel split payback'];
      expect(cbeMapping, isNotNull);
      expect(cbeMapping!.status, MappingStatus.createNew);
    });

    test('10. Interactive mapping transforms transactions into chosen Kals accounts and categories', () async {
      // 1. Create target accounts & categories
      await accountRepo.createAccount(Account(
        id: 'acc_primary_bank',
        name: 'HDFC Bank Savings',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await categoryRepo.createCategory(Category(
        id: 'cat_general_expense',
        name: 'General',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await categoryRepo.createCategory(Category(
        id: 'cat_meals',
        name: 'Meals & Groceries',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final file = createMockLegacyExcelFile();
      final analysis = await importService.analyzeSheet(
        file: file,
        sheetName: 'Expenses',
      );

      // 2. User maps legacy 'HDFC', 'Cash', 'SBI Bank' -> 'HDFC Bank Savings'
      final userAccountMappings = {
        'HDFC': AccountMappingEntry(
          legacyName: 'HDFC',
          targetAccountId: 'acc_primary_bank',
          targetAccountName: 'HDFC Bank Savings',
          status: MappingStatus.exactMatch,
        ),
        'Cash': AccountMappingEntry(
          legacyName: 'Cash',
          targetAccountId: 'acc_primary_bank',
          targetAccountName: 'HDFC Bank Savings',
          status: MappingStatus.exactMatch,
        ),
        'SBI Bank': AccountMappingEntry(
          legacyName: 'SBI Bank',
          targetAccountId: 'acc_primary_bank',
          targetAccountName: 'HDFC Bank Savings',
          status: MappingStatus.exactMatch,
        ),
      };

      // 3. User maps 'CBE Hostel split payback' -> 'General', 'Food & Dining' -> 'Meals & Groceries', 'Medical' -> 'General'
      final userCategoryMappings = {
        'CBE Hostel split payback': const CategoryMappingEntry(
          legacyName: 'CBE Hostel split payback',
          targetCategoryId: 'cat_general_expense',
          targetCategoryName: 'General',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
        'Food & Dining': const CategoryMappingEntry(
          legacyName: 'Food & Dining',
          targetCategoryId: 'cat_meals',
          targetCategoryName: 'Meals & Groceries',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
        'Medical': const CategoryMappingEntry(
          legacyName: 'Medical',
          targetCategoryId: 'cat_general_expense',
          targetCategoryName: 'General',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
      };

      // 4. Build preview with user's mappings
      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: userAccountMappings,
        categoryMappings: userCategoryMappings,
      );

      expect(preview.validItems.length, 3);
      expect(preview.validItems[0].mappedAccountId, 'acc_primary_bank');
      expect(preview.validItems[0].mappedCategoryId, 'cat_general_expense');
      expect(preview.validItems[1].mappedAccountId, 'acc_primary_bank');
      expect(preview.validItems[1].mappedCategoryId, 'cat_meals');
      expect(preview.validItems[2].mappedAccountId, 'acc_primary_bank');
      expect(preview.validItems[2].mappedCategoryId, 'cat_general_expense');

      // 5. Execute import
      final result = await importService.executeImport(
        preview: preview,
        skipDuplicates: true,
      );

      expect(result.importedCount, 3);

      final txs = await txRepo.getTransactions(const TransactionFilter(limit: 10));
      expect(txs.length, 3);
      expect(txs.every((t) => t.accountId == 'acc_primary_bank'), isTrue);
      expect(txs.any((t) => t.categoryId == 'cat_general_expense'), isTrue);
      expect(txs.any((t) => t.categoryId == 'cat_meals'), isTrue);
    });

    test('11. Multi-sheet import (Expenses + Income + Transfers) imports all sheets in single atomic transaction', () async {
      final file = createMockLegacyExcelFile();

      // Analyze all 3 sheets simultaneously
      final multiAnalysis = await importService.analyzeSheets(
        file: file,
        sheetNames: ['Expenses', 'Income', 'Transfers'],
      );

      expect(multiAnalysis.totalRows, 5); // 3 expenses + 1 income + 1 transfer
      // Legacy accounts detected across all sheets: HDFC, Cash, SBI Bank, CANARA BANK
      expect(multiAnalysis.accountMappings.containsKey('HDFC'), isTrue);
      expect(multiAnalysis.accountMappings.containsKey('CANARA BANK'), isTrue);

      // Create target accounts
      await accountRepo.createAccount(Account(
        id: 'acc_target_hdfc',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await accountRepo.createAccount(Account(
        id: 'acc_target_canara',
        name: 'Canara Savings',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // User maps all unique accounts once
      final mappedAccounts = {
        'HDFC': const AccountMappingEntry(
          legacyName: 'HDFC',
          targetAccountId: 'acc_target_hdfc',
          targetAccountName: 'HDFC Bank',
          status: MappingStatus.exactMatch,
        ),
        'Cash': const AccountMappingEntry(
          legacyName: 'Cash',
          targetAccountId: 'acc_target_hdfc',
          targetAccountName: 'HDFC Bank',
          status: MappingStatus.exactMatch,
        ),
        'SBI Bank': const AccountMappingEntry(
          legacyName: 'SBI Bank',
          targetAccountId: 'acc_target_hdfc',
          targetAccountName: 'HDFC Bank',
          status: MappingStatus.exactMatch,
        ),
        'CANARA BANK': const AccountMappingEntry(
          legacyName: 'CANARA BANK',
          targetAccountId: 'acc_target_canara',
          targetAccountName: 'Canara Savings',
          status: MappingStatus.exactMatch,
        ),
      };

      // Create category for income & general
      await categoryRepo.createCategory(Category(
        id: 'cat_salary_id',
        name: 'Salary',
        type: CategoryType.income,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_general_exp',
        name: 'General Expenses',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final mappedCategories = {
        'CBE Hostel split payback': const CategoryMappingEntry(
          legacyName: 'CBE Hostel split payback',
          targetCategoryId: 'cat_general_exp',
          targetCategoryName: 'General Expenses',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
        'Food & Dining': const CategoryMappingEntry(
          legacyName: 'Food & Dining',
          targetCategoryId: 'cat_general_exp',
          targetCategoryName: 'General Expenses',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
        'Medical': const CategoryMappingEntry(
          legacyName: 'Medical',
          targetCategoryId: 'cat_general_exp',
          targetCategoryName: 'General Expenses',
          categoryType: CategoryType.expense,
          status: MappingStatus.exactMatch,
        ),
        'Salary': const CategoryMappingEntry(
          legacyName: 'Salary',
          targetCategoryId: 'cat_salary_id',
          targetCategoryName: 'Salary',
          categoryType: CategoryType.income,
          status: MappingStatus.exactMatch,
        ),
      };

      final preview = await importService.buildPreview(
        analysis: multiAnalysis,
        accountMappings: mappedAccounts,
        categoryMappings: mappedCategories,
      );

      expect(preview.validCount, 5);
      expect(preview.expensesCount, 3);
      expect(preview.incomeCount, 1);
      expect(preview.transfersCount, 1);

      final result = await importService.executeImport(
        preview: preview,
        skipDuplicates: true,
      );

      expect(result.importedCount, 5);
      expect(result.expensesImported, 3);
      expect(result.incomeImported, 1);
      expect(result.transfersImported, 1);

      // Verify transfers and transactions exist
      final allTransfers = await transferRepo.getAllTransfers();
      expect(allTransfers.length, 1);
      expect(allTransfers.first.fromAccountId, 'acc_target_hdfc');
      expect(allTransfers.first.toAccountId, 'acc_target_canara');

      final allTxs = await txRepo.getTransactions(const TransactionFilter(limit: 100));
      expect(allTxs.length, 4); // 3 expenses + 1 income
      expect(allTxs.where((t) => t.transactionType == CategoryType.income).length, 1);
      expect(allTxs.where((t) => t.transactionType == CategoryType.expense).length, 3);
    });

    test('12. Account deletion preserves historical transactions and marks account as (Deleted) in ledger', () async {
      final acc = Account(
        id: 'acc_delete_test',
        name: 'Kotak Bank',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await accountRepo.createAccount(acc);

      final cat = Category(
        id: 'cat_misc',
        name: 'Misc',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.createCategory(cat);

      final tx = Transaction(
        id: 'tx_historical_1',
        accountId: 'acc_delete_test',
        categoryId: 'cat_misc',
        amount: const Money(units: 15000),
        transactionType: CategoryType.expense,
        date: DateTime.now(),
        description: 'Test payment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txRepo.createTransaction(tx);

      // Soft delete account
      await accountRepo.archiveAccount('acc_delete_test', true);

      // 1. Active accounts list should not include deleted account
      final activeAccounts = await accountRepo.getAllAccounts(includeArchived: false);
      expect(activeAccounts.any((a) => a.id == 'acc_delete_test'), isFalse);

      // 2. Historical transactions remain intact and display 'Kotak Bank (Deleted)'
      final ledger = await txRepo.getUnifiedLedger(limit: 10);
      final item = ledger.firstWhere((i) => i.id == 'tx_historical_1');
      expect(item, isNotNull);
      expect(item.accountName, 'Kotak Bank (Deleted)');
    });

    test('13. Legacy Comment preservation across Expenses, Income, Transfers including special characters, Unicode/Tamil, ₹ symbol, and long comments', () async {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Expenses');

      final expSheet = excel['Expenses'];
      expSheet.appendRow([TextCellValue('Header Row Title')]);
      expSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Account'),
        TextCellValue('Amount in default currency'),
        TextCellValue('Default currency'),
        TextCellValue('Comment'),
      ]);
      // Row with special characters, currency symbol, hyphens, and Tamil unicode
      const specialComment = 'Paid ₹500 for food - CBE trip (மதிய உணவு & coffee)';
      const longComment = 'Monthly rent and maintenance breakdown: Base ₹12,000 + Water ₹500 + Electricity bill ₹1,250. Paid via Google Pay ref #4928372910, shared with roommate.';
      
      expSheet.appendRow([
        TextCellValue('2025-08-15 12:00:00'),
        TextCellValue('Food'),
        TextCellValue('HDFC'),
        TextCellValue('500.00'),
        TextCellValue('INR'),
        TextCellValue(specialComment),
      ]);
      expSheet.appendRow([
        TextCellValue('2025-08-16 14:00:00'),
        TextCellValue('Rent'),
        TextCellValue('HDFC'),
        TextCellValue('13750.00'),
        TextCellValue('INR'),
        TextCellValue(longComment),
      ]);

      final incSheet = excel['Income'];
      incSheet.appendRow([TextCellValue('Header Row Title')]);
      incSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Account'),
        TextCellValue('Amount in default currency'),
        TextCellValue('Default currency'),
        TextCellValue('Comment'),
      ]);
      const incomeComment = 'Freelance UI/UX project milestone 1: Client "TechCorp" (50% advance)';
      incSheet.appendRow([
        TextCellValue('2025-08-17 10:00:00'),
        TextCellValue('Freelance'),
        TextCellValue('HDFC'),
        TextCellValue('25000.00'),
        TextCellValue('INR'),
        TextCellValue(incomeComment),
      ]);

      final trSheet = excel['Transfers'];
      trSheet.appendRow([TextCellValue('Header Row Title')]);
      trSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Outgoing'),
        TextCellValue('Incoming'),
        TextCellValue('Amount in outgoing currency'),
        TextCellValue('Outgoing currency'),
        TextCellValue('Comment'),
      ]);
      const transferComment = 'Fund transfer for emergency medical fund (Savings -> Health Acc)';
      trSheet.appendRow([
        TextCellValue('2025-08-18 16:00:00'),
        TextCellValue('HDFC'),
        TextCellValue('SBI'),
        TextCellValue('10000.00'),
        TextCellValue('INR'),
        TextCellValue(transferComment),
      ]);

      final file = File('${tempDir.path}/comment_preservation_test.xlsx');
      file.writeAsBytesSync(excel.encode()!);

      await accountRepo.createAccount(Account(
        id: 'acc_hdfc',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await accountRepo.createAccount(Account(
        id: 'acc_sbi',
        name: 'SBI Savings',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_food',
        name: 'Food',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_rent',
        name: 'Rent',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_freelance',
        name: 'Freelance',
        type: CategoryType.income,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final analysis = await importService.analyzeSheets(
        file: file,
        sheetNames: ['Expenses', 'Income', 'Transfers'],
      );

      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: {
          'HDFC': const AccountMappingEntry(legacyName: 'HDFC', targetAccountId: 'acc_hdfc', targetAccountName: 'HDFC Bank', status: MappingStatus.exactMatch),
          'SBI': const AccountMappingEntry(legacyName: 'SBI', targetAccountId: 'acc_sbi', targetAccountName: 'SBI Savings', status: MappingStatus.exactMatch),
        },
        categoryMappings: {
          'Food': const CategoryMappingEntry(legacyName: 'Food', targetCategoryId: 'cat_food', targetCategoryName: 'Food', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
          'Rent': const CategoryMappingEntry(legacyName: 'Rent', targetCategoryId: 'cat_rent', targetCategoryName: 'Rent', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
          'Freelance': const CategoryMappingEntry(legacyName: 'Freelance', targetCategoryId: 'cat_freelance', targetCategoryName: 'Freelance', categoryType: CategoryType.income, status: MappingStatus.exactMatch),
        },
      );

      expect(preview.validCount, 4);
      expect(preview.validItems[0].comment, specialComment);
      expect(preview.validItems[1].comment, longComment);
      expect(preview.validItems[2].comment, incomeComment);
      expect(preview.validItems[3].comment, transferComment);

      final result = await importService.executeImport(
        preview: preview,
        skipDuplicates: true,
      );
      expect(result.importedCount, 4);

      // Verify directly from database
      final ledger = await txRepo.getUnifiedLedger(limit: 100);
      expect(ledger.length, 4);

      final specialItem = ledger.firstWhere((i) => i.amount.units == 50000);
      expect(specialItem.notes, specialComment);
      expect(specialItem.description, specialComment);

      final longItem = ledger.firstWhere((i) => i.amount.units == 1375000);
      expect(longItem.notes, longComment);
      expect(longItem.description, longComment);

      final incItem = ledger.firstWhere((i) => i.amount.units == 2500000);
      expect(incItem.notes, incomeComment);
      expect(incItem.description, incomeComment);

      final trItem = ledger.firstWhere((i) => i.itemType == LedgerItemType.transfer);
      expect(trItem.description, transferComment);
      expect(trItem.notes, transferComment);
    });

    test('14. Empty comments are stored as null and not displayed as artificial strings', () async {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Expenses');
      final expSheet = excel['Expenses'];
      expSheet.appendRow([TextCellValue('Header')]);
      expSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Account'),
        TextCellValue('Amount in default currency'),
        TextCellValue('Default currency'),
        TextCellValue('Comment'),
      ]);
      expSheet.appendRow([
        TextCellValue('2025-09-01 12:00:00'),
        TextCellValue('Groceries'),
        TextCellValue('HDFC'),
        TextCellValue('350.00'),
        TextCellValue('INR'),
        TextCellValue(''), // Empty comment
      ]);

      final file = File('${tempDir.path}/empty_comment_test.xlsx');
      file.writeAsBytesSync(excel.encode()!);

      await accountRepo.createAccount(Account(
        id: 'acc_hdfc_groceries',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_groceries',
        name: 'Groceries',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final analysis = await importService.analyzeSheet(file: file, sheetName: 'Expenses');
      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: {
          'HDFC': const AccountMappingEntry(legacyName: 'HDFC', targetAccountId: 'acc_hdfc_groceries', targetAccountName: 'HDFC Bank', status: MappingStatus.exactMatch),
        },
        categoryMappings: {
          'Groceries': const CategoryMappingEntry(legacyName: 'Groceries', targetCategoryId: 'cat_groceries', targetCategoryName: 'Groceries', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
        },
      );

      expect(preview.validItems.first.comment, isNull);

      final result = await importService.executeImport(preview: preview, skipDuplicates: true);
      expect(result.importedCount, 1);

      final tx = (await txRepo.getTransactions(const TransactionFilter(limit: 10))).first;
      expect(tx.notes, isNull);
      expect(tx.notes, isNot('null'));
      expect(tx.notes, isNot('undefined'));
      expect(tx.notes, isNot('N/A'));
    });

    test('15. Transaction edit preserves imported comment and updates existing record without duplicating', () async {
      await accountRepo.createAccount(Account(
        id: 'acc_hdfc_edit',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_food_edit',
        name: 'Food',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Create imported transaction
      final tx = Transaction(
        id: 'tx_imported_edit_test',
        accountId: 'acc_hdfc_edit',
        categoryId: 'cat_food_edit',
        amount: const Money(units: 50000),
        transactionType: CategoryType.expense,
        date: DateTime(2025, 8, 15),
        description: 'Paid ₹500 for food - CBE trip',
        notes: 'Paid ₹500 for food - CBE trip',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txRepo.createTransaction(tx);

      final fetched = await txRepo.getTransactionById('tx_imported_edit_test');
      expect(fetched, isNotNull);
      expect(fetched!.notes, 'Paid ₹500 for food - CBE trip');

      // User edits the comment
      final updatedTx = fetched.copyWith(
        description: 'Paid ₹500 for food - CBE trip (updated: dinner split)',
        notes: 'Paid ₹500 for food - CBE trip (updated: dinner split)',
      );
      await txRepo.updateTransaction(updatedTx);

      // Verify updated in DB without duplicates
      final allTxs = await txRepo.getTransactions(const TransactionFilter(limit: 100));
      expect(allTxs.where((t) => t.id == 'tx_imported_edit_test').length, 1);
      final verified = await txRepo.getTransactionById('tx_imported_edit_test');
      expect(verified!.notes, 'Paid ₹500 for food - CBE trip (updated: dinner split)');
      expect(verified.description, 'Paid ₹500 for food - CBE trip (updated: dinner split)');
    });

    test('16. Export round-trip preserves imported comment in Comment column', () async {
      await accountRepo.createAccount(Account(
        id: 'acc_hdfc_export',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_food_export',
        name: 'Food',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final tx = Transaction(
        id: 'tx_export_roundtrip',
        accountId: 'acc_hdfc_export',
        categoryId: 'cat_food_export',
        amount: const Money(units: 50000),
        transactionType: CategoryType.expense,
        date: DateTime(2025, 8, 15),
        description: 'Paid ₹500 for food - CBE trip (dinner split)',
        notes: 'Paid ₹500 for food - CBE trip (dinner split)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txRepo.createTransaction(tx);

      final exportService = ExcelExportService(
        transactionRepository: txRepo,
        accountRepository: accountRepo,
        categoryRepository: categoryRepo,
        transferRepository: transferRepo,
        recurringRepository: recurringRepo,
      );

      final exportedFile = await exportService.generateExcelWorkbook();
      expect(exportedFile.existsSync(), isTrue);

      final exportedBytes = exportedFile.readAsBytesSync();
      final excel = Excel.decodeBytes(exportedBytes);
      final txSheet = excel['Transactions'];
      expect(txSheet, isNotNull);

      // Verify header contains Comment
      final headerRow = txSheet.rows[0].map((c) => c?.value.toString() ?? '').toList();
      expect(headerRow.contains('Comment'), isTrue);

      // Verify row contains our imported/updated comment
      final commentColIndex = headerRow.indexOf('Comment');
      final comments = txSheet.rows.skip(1).map((r) => r[commentColIndex]?.value.toString() ?? '').toList();
      expect(comments.any((c) => c.contains('dinner split')), isTrue);
    });

    test('17. Full-year 12-month workbook (Jan-Dec) imports all 12 months with complete coverage and reconciliation', () async {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Expenses');
      final expSheet = excel['Expenses'];
      expSheet.appendRow([TextCellValue('Full Year 2025 Statement')]);
      expSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Account'),
        TextCellValue('Amount in default currency'),
        TextCellValue('Default currency'),
        TextCellValue('Comment'),
      ]);

      // Create transactions for all 12 months of 2025
      final monthsData = [
        {'month': 1, 'count': 5, 'name': 'Jan'},
        {'month': 2, 'count': 4, 'name': 'Feb'},
        {'month': 3, 'count': 6, 'name': 'Mar'},
        {'month': 4, 'count': 4, 'name': 'Apr'},
        {'month': 5, 'count': 5, 'name': 'May'},
        {'month': 6, 'count': 4, 'name': 'Jun'},
        {'month': 7, 'count': 5, 'name': 'Jul'},
        {'month': 8, 'count': 5, 'name': 'Aug'},
        {'month': 9, 'count': 6, 'name': 'Sep'},
        {'month': 10, 'count': 4, 'name': 'Oct'},
        {'month': 11, 'count': 5, 'name': 'Nov'},
        {'month': 12, 'count': 5, 'name': 'Dec'},
      ];

      int totalGenerated = 0;
      for (final m in monthsData) {
        final monthNum = m['month'] as int;
        final count = m['count'] as int;
        final monthStr = monthNum.toString().padLeft(2, '0');

        for (int i = 1; i <= count; i++) {
          final dayStr = (i * 2).toString().padLeft(2, '0');
          expSheet.appendRow([
            TextCellValue('2025-$monthStr-$dayStr 12:00:00'),
            TextCellValue('General Expense'),
            TextCellValue('HDFC'),
            TextCellValue('${100.00 + (monthNum * 10) + i}'),
            TextCellValue('INR'),
            TextCellValue('Expense for month $monthNum item $i'),
          ]);
          totalGenerated++;
        }
      }

      expect(totalGenerated, 58);

      final file = File('${tempDir.path}/full_year_2025.xlsx');
      file.writeAsBytesSync(excel.encode()!);

      await accountRepo.createAccount(Account(
        id: 'acc_hdfc_fy',
        name: 'HDFC',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_gen_fy',
        name: 'General Expense',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final analysis = await importService.analyzeSheet(file: file, sheetName: 'Expenses');

      // 1. Authoritative source row count must be 58
      expect(analysis.totalRows, 58);
      // 2. All 12 months must be present in source monthly coverage
      expect(analysis.sourceMonthlyCoverage.length, 12);
      expect(analysis.sourceMonthlyCoverage['Jan 2025'], 5);
      expect(analysis.sourceMonthlyCoverage['Feb 2025'], 4);
      expect(analysis.sourceMonthlyCoverage['Dec 2025'], 5);
      expect(analysis.earliestDate?.month, 1);
      expect(analysis.latestDate?.month, 12);

      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: {
          'HDFC': const AccountMappingEntry(legacyName: 'HDFC', targetAccountId: 'acc_hdfc_fy', targetAccountName: 'HDFC', status: MappingStatus.exactMatch),
        },
        categoryMappings: {
          'General Expense': const CategoryMappingEntry(legacyName: 'General Expense', targetCategoryId: 'cat_gen_fy', targetCategoryName: 'General Expense', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
        },
      );

      expect(preview.validCount, 58);
      expect(preview.validMonthlyCoverage.length, 12);

      final result = await importService.executeImport(preview: preview, skipDuplicates: true);

      // 3. All 58 records imported and reconciled
      expect(result.importedCount, 58);
      expect(result.isReconciled, isTrue);
      expect(result.importedMonthlyCoverage.length, 12);

      // 4. Verify all 58 records exist in SQLite DB across all 12 months
      final allDbTxs = await txRepo.getTransactions(const TransactionFilter(limit: 100));
      expect(allDbTxs.length, 58);

      final dbMonths = allDbTxs.map((t) => t.date.month).toSet();
      expect(dbMonths.length, 12);
      for (int m = 1; m <= 12; m++) {
        expect(dbMonths.contains(m), isTrue, reason: 'Month $m must be present in DB');
      }
    });

    test('18. Excel numeric serial dates (e.g. 45658 = 2025-01-01) parse correctly across all months', () async {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Expenses');
      final expSheet = excel['Expenses'];
      expSheet.appendRow([TextCellValue('Header')]);
      expSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Account'),
        TextCellValue('Amount'),
      ]);

      // Serial 45658 = 2025-01-01, Serial 45992 = 2025-12-01
      expSheet.appendRow([
        IntCellValue(45658), // 2025-01-01
        TextCellValue('Shopping'),
        TextCellValue('HDFC'),
        DoubleCellValue(500.0),
      ]);
      expSheet.appendRow([
        DoubleCellValue(45992.5), // 2025-12-01 12:00 PM
        TextCellValue('Shopping'),
        TextCellValue('HDFC'),
        DoubleCellValue(750.0),
      ]);

      final file = File('${tempDir.path}/serial_dates_test.xlsx');
      file.writeAsBytesSync(excel.encode()!);

      final analysis = await importService.analyzeSheet(file: file, sheetName: 'Expenses');
      expect(analysis.rawRows.length, 2);
      expect(analysis.rawRows[0].parsedDate?.year, 2025);
      expect(analysis.rawRows[0].parsedDate?.month, 1);
      expect(analysis.rawRows[0].parsedDate?.day, 1);

      expect(analysis.rawRows[1].parsedDate?.year, 2025);
      expect(analysis.rawRows[1].parsedDate?.month, 12);
      expect(analysis.rawRows[1].parsedDate?.day, 1);
    });

    test('19. Blank rows between months do not stop parsing the remaining rows', () async {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Expenses');
      final expSheet = excel['Expenses'];
      expSheet.appendRow([TextCellValue('Header')]);
      expSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Account'),
        TextCellValue('Amount'),
      ]);

      // Jan row
      expSheet.appendRow([
        TextCellValue('2025-01-10'),
        TextCellValue('Food'),
        TextCellValue('Cash'),
        TextCellValue('100.00'),
      ]);

      // Blank rows
      expSheet.appendRow([TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue('')]);
      expSheet.appendRow([TextCellValue(' '), TextCellValue(' ')]);

      // Dec row after blank rows
      expSheet.appendRow([
        TextCellValue('2025-12-25'),
        TextCellValue('Food'),
        TextCellValue('Cash'),
        TextCellValue('250.00'),
      ]);

      final file = File('${tempDir.path}/blank_rows_test.xlsx');
      file.writeAsBytesSync(excel.encode()!);

      final analysis = await importService.analyzeSheet(file: file, sheetName: 'Expenses');
      expect(analysis.totalRows, 2);
      expect(analysis.rawRows.first.parsedDate?.month, 1);
      expect(analysis.rawRows.last.parsedDate?.month, 12);
    });

    test('20. Multiset duplicate detection allows legitimate identical source rows while skipping true DB duplicates', () async {
      // Create 1 existing transaction in DB
      await accountRepo.createAccount(Account(
        id: 'acc_dup_multi',
        name: 'HDFC',
        accountType: AccountType.bank,
        openingBalance: const Money.zero(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_dup_multi',
        name: 'Food',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await txRepo.createTransaction(Transaction(
        id: 'tx_existing_dup',
        accountId: 'acc_dup_multi',
        categoryId: 'cat_dup_multi',
        amount: const Money(units: 2000), // ₹20
        transactionType: CategoryType.expense,
        date: DateTime(2025, 8, 1),
        description: 'Snacks',
        notes: 'Snacks',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Excel contains 2 identical transactions for ₹20 on 2025-08-01 with comment "Snacks"
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Expenses');
      final expSheet = excel['Expenses'];
      expSheet.appendRow([TextCellValue('Header')]);
      expSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Account'),
        TextCellValue('Amount'),
        TextCellValue('Currency'),
        TextCellValue('Comment'),
      ]);
      expSheet.appendRow([
        TextCellValue('2025-08-01 10:00:00'),
        TextCellValue('Food'),
        TextCellValue('HDFC'),
        TextCellValue('20.00'),
        TextCellValue('INR'),
        TextCellValue('Snacks'),
      ]);
      expSheet.appendRow([
        TextCellValue('2025-08-01 10:00:00'),
        TextCellValue('Food'),
        TextCellValue('HDFC'),
        TextCellValue('20.00'),
        TextCellValue('INR'),
        TextCellValue('Snacks'),
      ]);

      final file = File('${tempDir.path}/multiset_dup_test.xlsx');
      file.writeAsBytesSync(excel.encode()!);

      final analysis = await importService.analyzeSheet(file: file, sheetName: 'Expenses');
      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: {
          'HDFC': const AccountMappingEntry(legacyName: 'HDFC', targetAccountId: 'acc_dup_multi', targetAccountName: 'HDFC', status: MappingStatus.exactMatch),
        },
        categoryMappings: {
          'Food': const CategoryMappingEntry(legacyName: 'Food', targetCategoryId: 'cat_dup_multi', targetCategoryName: 'Food', categoryType: CategoryType.expense, status: MappingStatus.exactMatch),
        },
      );

      // Total source rows: 2
      // 1 should be flagged as duplicate (matching the 1 in DB)
      // The 2nd should be recognized as a valid new row
      expect(preview.totalRows, 2);
      expect(preview.duplicateCount, 1);
      expect(preview.validCount, 2);

      final result = await importService.executeImport(preview: preview, skipDuplicates: true);
      expect(result.importedCount, 1);
      expect(result.skippedDuplicates, 1);

      // In total, DB now has 2 transactions (1 pre-existing + 1 newly imported)
      final allDbTxs = await txRepo.getTransactions(const TransactionFilter(limit: 10));
      expect(allDbTxs.length, 2);
    });
  });
}
