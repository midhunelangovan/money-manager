import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';
import 'package:kals_money_manager/core/widgets/transaction_type_tabs.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_import_service.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/dashboard/presentation/models/dashboard_filter_state.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  late Database db;
  late AppDatabase appDb;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl txRepo;
  late ExcelImportService importService;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stabilization_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
      onCreate: DatabaseMigrations.onCreate,
    );
    appDb = AppDatabase.withDatabase(db);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    importService = ExcelImportService(database: appDb);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('P0 Stabilization: Excel Import Missing Category and Empty Row Handling', () {
    test('Empty spreadsheet rows and trailing blanks are skipped cleanly without false invalid rows', () async {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Expenses');
      final sheet = excel['Expenses'];

      // Header row
      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Account'),
        TextCellValue('Category'),
        TextCellValue('Amount'),
        TextCellValue('Comment'),
      ]);

      // Row 1: Valid
      sheet.appendRow([
        TextCellValue('2026-02-10'),
        TextCellValue('SBI Bank'),
        TextCellValue('Groceries'),
        DoubleCellValue(450.0),
        TextCellValue('Valid row 1'),
      ]);

      // Row 2: Completely empty row (blanks)
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue('   '),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);

      // Row 3: Valid row with missing category cell
      sheet.appendRow([
        TextCellValue('2026-02-11'),
        TextCellValue('SBI Bank'),
        TextCellValue(''), // Missing/blank category
        DoubleCellValue(200.0),
        TextCellValue('Row without category'),
      ]);

      // Row 4: Valid row with whitespace-only category cell
      sheet.appendRow([
        TextCellValue('2026-02-12'),
        TextCellValue('SBI Bank'),
        TextCellValue('   \t  '), // Whitespace category
        DoubleCellValue(150.0),
        TextCellValue('Row with whitespace category'),
      ]);

      // Rows 5-7: Trailing empty rows
      sheet.appendRow([TextCellValue(''), TextCellValue('')]);
      sheet.appendRow([TextCellValue(''), TextCellValue('')]);

      final bytes = excel.encode()!;
      final testFile = File('${tempDir.path}/test_expenses.xlsx');
      await testFile.writeAsBytes(bytes);

      // Analyze sheets
      final analysis = await importService.analyzeSheets(
        file: testFile,
        sheetNames: ['Expenses'],
      );

      // Verify that genuinely empty rows were ignored and not counted as records
      expect(analysis.totalRows, 3);

      // Verify that missing category cells are grouped into a readable 'No category' entry
      expect(analysis.categoryMappings.containsKey('No category'), isTrue);
      final noCategoryMapping = analysis.categoryMappings['No category']!;
      expect(noCategoryMapping.legacyName, 'No category');
      expect(noCategoryMapping.transactionCount, 2); // rows 3 and 4

      // Build preview
      final preview = await importService.buildPreview(
        analysis: analysis,
        accountMappings: analysis.accountMappings,
        categoryMappings: analysis.categoryMappings,
      );

      expect(preview.validCount, 3);
      expect(preview.invalidCount, 0);

      // Verify preview items have non-empty readable categories and accounts
      for (final item in preview.previewItems) {
        expect(item.mappedCategoryName, isNotNull);
        expect(item.mappedCategoryName!.trim().isNotEmpty, isTrue);
        expect(item.mappedAccountName, isNotNull);
        expect(item.mappedAccountName!.trim().isNotEmpty, isTrue);
      }

      // Execute import
      final result = await importService.executeImport(
        preview: preview,
        skipDuplicates: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.importedCount, 3);
      expect(result.invalidRowsCount, 0);

      // Verify saved transactions in database
      final txList = await txRepo.getTransactions(TransactionFilter(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ));
      expect(txList.length, 3);
      for (final tx in txList) {
        expect(tx.categoryId.trim().isNotEmpty, isTrue);
        expect(tx.accountId.trim().isNotEmpty, isTrue);
      }
    });

    test('Category matching strictly scopes by category type (Expense vs Income)', () async {
      final now = DateTime.now();
      // Create existing categories in database
      await categoryRepo.createCategory(Category(
        id: 'cat_exp_other',
        name: 'Other',
        type: CategoryType.expense,
        createdAt: now,
        updatedAt: now,
      ));
      await categoryRepo.createCategory(Category(
        id: 'cat_inc_other',
        name: 'Other',
        type: CategoryType.income,
        createdAt: now,
        updatedAt: now,
      ));

      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Expenses');
      final sheet = excel['Expenses'];
      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Account'),
        TextCellValue('Category'),
        TextCellValue('Amount'),
        TextCellValue('Comment'),
      ]);
      sheet.appendRow([
        TextCellValue('2026-03-01'),
        TextCellValue('HDFC'),
        TextCellValue('Other'),
        DoubleCellValue(50.0),
        TextCellValue('Expense Other'),
      ]);

      final bytes = excel.encode()!;
      final testFile = File('${tempDir.path}/test_type_match.xlsx');
      await testFile.writeAsBytes(bytes);

      final analysis = await importService.analyzeSheets(
        file: testFile,
        sheetNames: ['Expenses'],
      );

      final otherMapping = analysis.categoryMappings['Other'];
      expect(otherMapping, isNotNull);
      expect(otherMapping!.categoryType, CategoryType.expense);
      expect(otherMapping.targetCategoryId, 'cat_exp_other'); // Must map to expense Other, not income Other
    });
  });

  group('P0 Stabilization: Dashboard Authoritative Filter State & Navigation', () {
    test('DashboardFilterState calculates local midnight exclusive boundaries accurately', () {
      final anchor = DateTime(2026, 3, 15);
      final state = DashboardFilterState(
        accountId: 'acc_1',
        periodMode: TimePeriod.month,
        anchorDate: anchor,
        tabType: LedgerTabType.expenses,
      );

      // March 2026 boundaries: 2026-03-01 to 2026-04-01 (exclusive)
      expect(state.startDate, DateTime(2026, 3, 1));
      expect(state.endDate, DateTime(2026, 4, 1));

      // Previous period -> February 2026: 2026-02-01 to 2026-03-01
      final prevMonth = state.previousPeriod();
      expect(prevMonth.startDate, DateTime(2026, 2, 1));
      expect(prevMonth.endDate, DateTime(2026, 3, 1));

      // Next period from February -> March 2026
      final nextMonth = prevMonth.nextPeriod();
      expect(nextMonth.startDate, DateTime(2026, 3, 1));
      expect(nextMonth.endDate, DateTime(2026, 4, 1));

      // Year mode boundaries: 2026-01-01 to 2027-01-01
      final yearState = state.copyWith(periodMode: TimePeriod.year);
      expect(yearState.startDate, DateTime(2026, 1, 1));
      expect(yearState.endDate, DateTime(2027, 1, 1));
    });
  });
}
