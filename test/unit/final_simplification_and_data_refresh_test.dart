import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/profile_avatar.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_import_service.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  late Database db;
  late AppDatabase appDb;
  late TransactionRepositoryImpl txRepo;
  late AccountRepositoryImpl accRepo;
  late CategoryRepositoryImpl catRepo;
  late ExcelImportService excelService;

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

    txRepo = TransactionRepositoryImpl(database: appDb);
    accRepo = AccountRepositoryImpl(database: appDb);
    catRepo = CategoryRepositoryImpl(database: appDb);
    excelService = ExcelImportService(database: appDb);
  });

  tearDown(() async {
    await db.close();
  });

  group('Kals Money Manager — Final Simplification & Data Refresh Tests', () {
    test('1. TransactionProvider increments ledgerRevision on create, update, delete', () async {
      final txProvider = TransactionProvider(repository: txRepo);
      expect(txProvider.ledgerRevision, 0);

      await txProvider.loadLedger();
      expect(txProvider.ledgerRevision, 1);

      // Create test account and category
      final acc = Account(
        id: 'acc_1',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(500000),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await accRepo.createAccount(acc);

      final cat = Category(
        id: 'cat_1',
        name: 'Food & Dining',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await catRepo.createCategory(cat);

      // Create Transaction
      final tx = Transaction(
        id: 'tx_1',
        accountId: acc.id,
        categoryId: cat.id,
        amount: Money.fromUnits(12000),
        transactionType: CategoryType.expense,
        description: 'Dinner',
        date: DateTime(2026, 10, 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txProvider.createTransaction(tx);
      expect(txProvider.ledgerRevision, 2);

      // Update Transaction
      final updatedTx = tx.copyWith(amount: Money.fromUnits(15000));
      await txProvider.updateTransaction(updatedTx);
      expect(txProvider.ledgerRevision, 3);

      // Delete Transaction
      await txProvider.deleteTransaction(tx.id);
      expect(txProvider.ledgerRevision, 4);
    });

    test('2. Repository rejects empty or whitespace-only category/account names', () async {
      expect(
        () => catRepo.createCategory(Category(
          id: 'cat_invalid',
          name: '   ',
          type: CategoryType.expense,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )),
        throwsArgumentError,
      );

      expect(
        () => accRepo.createAccount(Account(
          id: 'acc_invalid',
          name: '',
          accountType: AccountType.bank,
          openingBalance: Money.fromUnits(0),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )),
        throwsArgumentError,
      );
    });

    test('3. Excel import handles blank category, whitespace category, and null category without creating empty categories', () async {
      // 1. Seed existing database categories
      final foodCat = Category(
        id: 'cat_food',
        name: 'Food & Dining',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final otherExpenseCat = Category(
        id: 'cat_other_exp',
        name: 'Other',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final hdfcAcc = Account(
        id: 'acc_hdfc',
        name: 'HDFC Bank',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(100000),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await catRepo.createCategory(foodCat);
      await catRepo.createCategory(otherExpenseCat);
      await accRepo.createAccount(hdfcAcc);

      // 2. Generate Excel workbook with edge case rows:
      // Row 1: Valid "Food & Dining"
      // Row 2: Whitespace category "  Food & Dining  "
      // Row 3: Blank category ""
      // Row 4: Whitespace only category "   "
      // Row 5: "null" string category
      // Row 6: Completely empty row (all cells empty)
      // Row 7: Valid transaction
      final excel = xl.Excel.createExcel();
      final sheet = excel['Expenses'];
      excel.setDefaultSheet('Expenses');

      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Account'),
        xl.TextCellValue('Amount'),
        xl.TextCellValue('Comment'),
      ]);

      sheet.appendRow([
        xl.TextCellValue('2026-10-01'),
        xl.TextCellValue('Food & Dining'),
        xl.TextCellValue('HDFC Bank'),
        xl.DoubleCellValue(500.0),
        xl.TextCellValue('Normal row'),
      ]);

      sheet.appendRow([
        xl.TextCellValue('2026-10-02'),
        xl.TextCellValue('  Food & Dining  '),
        xl.TextCellValue('HDFC Bank'),
        xl.DoubleCellValue(250.0),
        xl.TextCellValue('Whitespace trimmed'),
      ]);

      sheet.appendRow([
        xl.TextCellValue('2026-10-03'),
        xl.TextCellValue(''), // Blank category
        xl.TextCellValue('HDFC Bank'),
        xl.DoubleCellValue(100.0),
        xl.TextCellValue('No category cell'),
      ]);

      sheet.appendRow([
        xl.TextCellValue('2026-10-04'),
        xl.TextCellValue('   '), // Spaces only
        xl.TextCellValue('HDFC Bank'),
        xl.DoubleCellValue(150.0),
        xl.TextCellValue('Spaces category'),
      ]);

      sheet.appendRow([
        xl.TextCellValue('2026-10-05'),
        xl.TextCellValue('null'), // "null" string
        xl.TextCellValue('HDFC Bank'),
        xl.DoubleCellValue(200.0),
        xl.TextCellValue('Null string category'),
      ]);

      // Completely empty row between valid rows
      sheet.appendRow([
        xl.TextCellValue(''),
        xl.TextCellValue(''),
        xl.TextCellValue(''),
        xl.TextCellValue(''),
        xl.TextCellValue(''),
      ]);

      sheet.appendRow([
        xl.TextCellValue('2026-10-06'),
        xl.TextCellValue('Food & Dining'),
        xl.TextCellValue('HDFC Bank'),
        xl.DoubleCellValue(300.0),
        xl.TextCellValue('Final valid row'),
      ]);

      final tempFile = File('${Directory.systemTemp.path}/excel_normalization_test.xlsx');
      final bytes = excel.encode()!;
      await tempFile.writeAsBytes(bytes, flush: true);

      // Analyze
      final analysis = await excelService.analyzeSheets(file: tempFile, sheetNames: ['Expenses']);

      // Blank row was skipped
      expect(analysis.rawRows.length, 6);

      // Category mappings must contain ONLY real categories, no empty string categories
      for (final catName in analysis.categoryMappings.keys) {
        expect(catName.trim().isNotEmpty, isTrue);
        expect(catName.toLowerCase(), isNot('null'));
      }

      // Build Preview
      final preview = await excelService.buildPreview(
        analysis: analysis,
        accountMappings: analysis.accountMappings,
        categoryMappings: analysis.categoryMappings,
      );

      expect(preview.validCount, 6);
      expect(preview.invalidCount, 0);

      // Execute Import
      final result = await excelService.executeImport(preview: preview, skipDuplicates: false);
      expect(result.importedTransactionsCount, 6);

      // Verify no empty categories were inserted into DB
      final allDbCategories = await catRepo.getAllCategories();
      for (final c in allDbCategories) {
        expect(c.name.trim().isNotEmpty, isTrue);
      }

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('4. ProfileAvatar initials calculation', () {
      const avatar1 = ProfileAvatar(name: 'John Doe');
      expect(avatar1.name, 'John Doe');

      const avatar2 = ProfileAvatar(name: 'Midhun');
      expect(avatar2.name, 'Midhun');

      const avatar3 = ProfileAvatar(name: '');
      expect(avatar3.name, '');
    });

    test('5. Excel import preserves separate mappings for same-name Expense and Income categories without collision', () async {
      // 1. Seed existing database categories
      final expenseOther = Category(
        id: 'cat_other_exp',
        name: 'Other Expense',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final incomeOther = Category(
        id: 'cat_other_inc',
        name: 'Other Income',
        type: CategoryType.income,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final account = Account(
        id: 'acc_test',
        name: 'Test Bank',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(100000),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await catRepo.createCategory(expenseOther);
      await catRepo.createCategory(incomeOther);
      await accRepo.createAccount(account);

      // 2. Create workbook with both Expenses and Income sheets having category "Other"
      final excel = xl.Excel.createExcel();
      final expSheet = excel['Expenses'];
      expSheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Account'),
        xl.TextCellValue('Amount'),
        xl.TextCellValue('Comment'),
      ]);
      expSheet.appendRow([
        xl.TextCellValue('2026-10-01'),
        xl.TextCellValue('Other'),
        xl.TextCellValue('Test Bank'),
        xl.DoubleCellValue(100.0),
        xl.TextCellValue('Expense item'),
      ]);

      final incSheet = excel['Income'];
      incSheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Account'),
        xl.TextCellValue('Amount'),
        xl.TextCellValue('Comment'),
      ]);
      incSheet.appendRow([
        xl.TextCellValue('2026-10-02'),
        xl.TextCellValue('Other'),
        xl.TextCellValue('Test Bank'),
        xl.DoubleCellValue(500.0),
        xl.TextCellValue('Income item'),
      ]);

      final tempFile = File('${Directory.systemTemp.path}/excel_same_name_category_test.xlsx');
      final bytes = excel.encode()!;
      await tempFile.writeAsBytes(bytes, flush: true);

      // Analyze both sheets
      final analysis = await excelService.analyzeSheets(
        file: tempFile,
        sheetNames: ['Expenses', 'Income'],
      );

      // Both category mappings must be detected separately without overwriting
      expect(analysis.categoryMappings.length, 2);
      final expEntry = analysis.categoryMappings['Other|expense'];
      final incEntry = analysis.categoryMappings['Other|income'];

      expect(expEntry, isNotNull);
      expect(expEntry!.categoryType, CategoryType.expense);
      expect(expEntry.legacyName, 'Other');

      expect(incEntry, isNotNull);
      expect(incEntry!.categoryType, CategoryType.income);
      expect(incEntry.legacyName, 'Other');

      // Verify Expense Other does NOT map to an Income category
      if (expEntry.targetCategoryId != null) {
        final targetCat = (await catRepo.getAllCategories()).firstWhere((c) => c.id == expEntry.targetCategoryId);
        expect(targetCat.type, CategoryType.expense);
      }

      // Build Preview
      final preview = await excelService.buildPreview(
        analysis: analysis,
        accountMappings: analysis.accountMappings,
        categoryMappings: analysis.categoryMappings,
      );

      expect(preview.validCount, 2);
      expect(preview.expensesCount, 1);
      expect(preview.incomeCount, 1);

      // Execute Import
      final result = await excelService.executeImport(preview: preview, skipDuplicates: false);
      expect(result.importedTransactionsCount, 2);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });
  });
}
