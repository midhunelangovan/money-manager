import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kals_money_manager/core/constants/app_currency.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/utilities/id_generator.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_import_service.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AppDatabase appDb;
  late CategoryRepositoryImpl categoryRepo;
  late ExcelImportService importService;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, v) => DatabaseMigrations.onCreate(d, v),
      ),
    );
    appDb = AppDatabase.withDatabase(db);
    AppDatabase.setTestInstance(appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    importService = ExcelImportService(database: appDb);
  });

  tearDown(() async {
    await db.close();
  });

  group('Kals Money Manager — Onboarding Generic Values & Currency Tests', () {
    test('1. Supported currencies format correctly with name, code, symbol and flag', () {
      for (final curr in AppCurrency.supportedCurrencies) {
        expect(curr.name.isNotEmpty, isTrue);
        expect(curr.code.isNotEmpty, isTrue);
        expect(curr.symbol.isNotEmpty, isTrue);
        expect(curr.flag.isNotEmpty, isTrue);
      }

      final inr = AppCurrency.inr;
      expect(inr.name, equals('Indian Rupee'));
      expect(inr.code, equals('INR'));
      expect(inr.symbol, equals('₹'));
      expect(inr.flag, equals('🇮🇳'));

      final usd = AppCurrency.usd;
      expect(usd.name, equals('US Dollar'));
      expect(usd.code, equals('USD'));
      expect(usd.symbol, equals('\$'));
    });
  });

  group('Kals Money Manager — Category Entity Persistence & Excel Import Tests', () {
    test('2. Excel Import creates real, persisted Category entity in SQLite categories table', () async {
      // Initially, verify 'Investment' does not exist in categories
      final existingBefore = await categoryRepo.getAllCategories(type: CategoryType.expense);
      expect(existingBefore.any((c) => c.name.toLowerCase() == 'investment'), isFalse);

      final newCatId = IdGenerator.generate();
      final newAccId = IdGenerator.generate();

      // Setup preview with an unmapped/new category 'Investment'
      final preview = ExcelImportPreview(
        sheetNames: ['Expenses'],
        sheetName: 'Expenses',
        sheetType: ExcelSheetType.expenses,
        mapping: const ExcelColumnMapping(
          sheetType: ExcelSheetType.expenses,
          headerRowIndex: 0,
          dateIndex: 0,
          amountIndex: 1,
        ),
        totalRowsScanned: 1,
        validItems: [
          ParsedImportItem(
            sheetName: 'Expenses',
            rowNumber: 2,
            date: DateTime(2026, 3, 15),
            legacyCategory: 'Investment',
            mappedCategoryId: newCatId,
            mappedCategoryName: 'Investment',
            legacyAccount: 'Main Account',
            mappedAccountId: newAccId,
            mappedAccountName: 'Main Account',
            amount: Money.fromUnits(500000), // 5000.00
            currency: 'INR',
            sheetType: ExcelSheetType.expenses,
          ),
        ],
        invalidRows: [],
        duplicateItems: [],
        finalAccountMappings: {
          'Main Account': AccountMappingEntry(
            legacyName: 'Main Account',
            targetAccountId: newAccId,
            targetAccountName: 'Main Account',
            status: MappingStatus.createNew,
            transactionCount: 1,
          ),
        },
        finalCategoryMappings: {
          'Investment': CategoryMappingEntry(
            legacyName: 'Investment',
            targetCategoryId: newCatId,
            targetCategoryName: 'Investment',
            categoryType: CategoryType.expense,
            status: MappingStatus.createNew,
            transactionCount: 1,
          ),
        },
        sheetItemCounts: {'Expenses': 1},
        expensesCount: 1,
        incomeCount: 0,
        transfersCount: 0,
        minDate: DateTime(2026, 3, 15),
        maxDate: DateTime(2026, 3, 15),
        sourceMonthlyCoverage: {'2026-03': 1},
        validMonthlyCoverage: {'2026-03': 1},
      );

      final result = await importService.executeImport(
        preview: preview,
        skipDuplicates: true,
      );

      expect(result.importedCount, equals(1));
      expect(result.expensesImported, equals(1));

      // Verify 'Investment' category now exists in SQLite database as a real entity
      final categoryInDb = await categoryRepo.getCategoryById(newCatId);
      expect(categoryInDb, isNotNull);
      expect(categoryInDb!.name, equals('Investment'));
      expect(categoryInDb.type, equals(CategoryType.expense));

      // Verify category shows up in getAllCategories query
      final allExpenseCategories = await categoryRepo.getAllCategories(type: CategoryType.expense);
      expect(allExpenseCategories.any((c) => c.id == newCatId && c.name == 'Investment'), isTrue);

      // Verify transaction in SQLite references the exact categoryId
      final txRows = await db.query(DbTables.transactions, where: '${DbColumns.categoryId} = ?', whereArgs: [newCatId]);
      expect(txRows.length, equals(1));
      expect(txRows.first[DbColumns.amount], equals(500000));
    });

    test('3. Imported Category is editable and changes name/icon/color without breaking transaction links', () async {
      final catId = IdGenerator.generate();
      final accId = IdGenerator.generate();

      // Create initial category & transaction
      final cat = Category(
        id: catId,
        name: 'Investment',
        type: CategoryType.expense,
        icon: 'category_outlined',
        color: 0xFF2563EB,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.createCategory(cat);

      await db.insert(DbTables.transactions, {
        DbColumns.id: IdGenerator.generate(),
        DbColumns.transactionType: 'EXPENSE',
        DbColumns.accountId: accId,
        DbColumns.categoryId: catId,
        DbColumns.amount: 250000,
        DbColumns.date: DateTime(2026, 5, 1).millisecondsSinceEpoch,
        DbColumns.description: 'Stock Purchase',
        DbColumns.notes: null,
        DbColumns.receiptPath: null,
        DbColumns.createdAt: DateTime.now().millisecondsSinceEpoch,
        DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });

      // User edits the category (changes name to 'Mutual Funds & Stocks', new icon and color)
      final updatedCat = cat.copyWith(
        name: 'Mutual Funds & Stocks',
        icon: 'trending_up_outlined',
        color: 0xFF059669,
      );
      await categoryRepo.updateCategory(updatedCat);

      // Verify category updated in database
      final fetched = await categoryRepo.getCategoryById(catId);
      expect(fetched!.name, equals('Mutual Funds & Stocks'));
      expect(fetched.icon, equals('trending_up_outlined'));
      expect(fetched.color, equals(0xFF059669));

      // Verify transaction is still linked via categoryId
      final txRows = await db.query(DbTables.transactions, where: '${DbColumns.categoryId} = ?', whereArgs: [catId]);
      expect(txRows.length, equals(1));
      expect(txRows.first[DbColumns.amount], equals(250000));
    });

    test('4. Duplicate categories are not created on repeated rows during import', () async {
      final catId = IdGenerator.generate();
      final accId = IdGenerator.generate();

      // 100 rows referencing the SAME category 'Groceries'
      final validItems = List.generate(
        100,
        (i) => ParsedImportItem(
          sheetName: 'Expenses',
          rowNumber: i + 2,
          date: DateTime(2026, 1, (i % 28) + 1),
          legacyCategory: 'Groceries',
          mappedCategoryId: catId,
          mappedCategoryName: 'Groceries',
          legacyAccount: 'Main Account',
          mappedAccountId: accId,
          mappedAccountName: 'Main Account',
          amount: Money.fromUnits((i + 1) * 1000),
          currency: 'INR',
          sheetType: ExcelSheetType.expenses,
        ),
      );

      final preview = ExcelImportPreview(
        sheetNames: ['Expenses'],
        sheetName: 'Expenses',
        sheetType: ExcelSheetType.expenses,
        mapping: const ExcelColumnMapping(
          sheetType: ExcelSheetType.expenses,
          headerRowIndex: 0,
          dateIndex: 0,
          amountIndex: 1,
        ),
        totalRowsScanned: 100,
        validItems: validItems,
        invalidRows: [],
        duplicateItems: [],
        finalAccountMappings: {
          'Main Account': AccountMappingEntry(
            legacyName: 'Main Account',
            targetAccountId: accId,
            targetAccountName: 'Main Account',
            status: MappingStatus.createNew,
            transactionCount: 100,
          ),
        },
        finalCategoryMappings: {
          'Groceries': CategoryMappingEntry(
            legacyName: 'Groceries',
            targetCategoryId: catId,
            targetCategoryName: 'Groceries',
            categoryType: CategoryType.expense,
            status: MappingStatus.createNew,
            transactionCount: 100,
          ),
        },
        sheetItemCounts: {'Expenses': 100},
        expensesCount: 100,
        incomeCount: 0,
        transfersCount: 0,
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 1, 28),
        sourceMonthlyCoverage: {'2026-01': 100},
        validMonthlyCoverage: {'2026-01': 100},
      );

      final result = await importService.executeImport(preview: preview, skipDuplicates: false);
      expect(result.importedCount, equals(100));

      // Verify ONLY ONE Groceries category was created with this ID
      final matchingCats = await db.query(DbTables.categories, where: '${DbColumns.id} = ?', whereArgs: [catId]);
      expect(matchingCats.length, equals(1));

      // All 100 transactions reference this one categoryId
      final txRows = await db.query(DbTables.transactions, where: '${DbColumns.categoryId} = ?', whereArgs: [catId]);
      expect(txRows.length, equals(100));
    });

    test('5. Legacy orphaned category reconciliation finds missing categories and creates entities safely', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final accId = IdGenerator.generate();

      // Insert an account
      await db.insert(DbTables.accounts, {
        DbColumns.id: accId,
        DbColumns.name: 'Main Account',
        DbColumns.accountType: 'BANK',
        DbColumns.openingBalance: 0,
        DbColumns.currency: 'INR',
        DbColumns.icon: 'account_balance_outlined',
        DbColumns.color: 0xFF1976D2,
        DbColumns.isArchived: 0,
        DbColumns.createdAt: now,
        DbColumns.updatedAt: now,
      });

      // Insert an unlinked transaction with an invalid/missing category ID
      final orphanedTxId = IdGenerator.generate();
      await db.insert(DbTables.transactions, {
        DbColumns.id: orphanedTxId,
        DbColumns.transactionType: 'EXPENSE',
        DbColumns.accountId: accId,
        DbColumns.categoryId: 'invalid_non_existent_category_id',
        DbColumns.amount: 75000,
        DbColumns.date: DateTime(2026, 2, 10).millisecondsSinceEpoch,
        DbColumns.description: 'Crypto Investment',
        DbColumns.notes: 'Bitcoins',
        DbColumns.receiptPath: null,
        DbColumns.createdAt: now,
        DbColumns.updatedAt: now,
      });

      // Run reconciliation
      await DatabaseMigrations.reconcileLegacyCategories(db);

      // Verify a category 'Crypto Investment' was safely created and transaction updated
      final updatedTx = await db.query(DbTables.transactions, where: '${DbColumns.id} = ?', whereArgs: [orphanedTxId]);
      final reconciledCatId = updatedTx.first[DbColumns.categoryId] as String;
      expect(reconciledCatId, isNotEmpty);

      final cat = await categoryRepo.getCategoryById(reconciledCatId);
      expect(cat, isNotNull);
      expect(cat!.name, equals('Crypto Investment'));
      expect(cat.type, equals(CategoryType.expense));
    });
  });
}
