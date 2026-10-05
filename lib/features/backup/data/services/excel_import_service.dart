import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/utilities/money.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../categories/domain/entities/category.dart';

enum ExcelSheetType {
  expenses,
  income,
  transfers,
  unknown;

  String get displayName {
    switch (this) {
      case ExcelSheetType.expenses:
        return 'Expenses';
      case ExcelSheetType.income:
        return 'Income';
      case ExcelSheetType.transfers:
        return 'Transfers';
      case ExcelSheetType.unknown:
        return 'Unknown';
    }
  }

  static ExcelSheetType fromName(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.contains('expense')) return ExcelSheetType.expenses;
    if (lower.contains('income')) return ExcelSheetType.income;
    if (lower.contains('transfer')) return ExcelSheetType.transfers;
    return ExcelSheetType.unknown;
  }
}

enum MappingStatus {
  exactMatch,
  suggested,
  createNew,
  unmapped,
  ignored;

  String get badgeText {
    switch (this) {
      case MappingStatus.exactMatch:
        return 'Matched';
      case MappingStatus.suggested:
        return 'Suggested';
      case MappingStatus.createNew:
        return '+ Create';
      case MappingStatus.unmapped:
        return 'Unmapped';
      case MappingStatus.ignored:
        return 'Ignored';
    }
  }
}

class AccountMappingEntry {
  final String legacyName;
  final String? targetAccountId;
  final String? targetAccountName;
  final MappingStatus status;
  final int transactionCount;
  final bool isTargetArchived;

  const AccountMappingEntry({
    required this.legacyName,
    this.targetAccountId,
    this.targetAccountName,
    required this.status,
    this.transactionCount = 0,
    this.isTargetArchived = false,
  });

  bool get isMapped =>
      status == MappingStatus.ignored ||
      status == MappingStatus.createNew ||
      ((status == MappingStatus.exactMatch || status == MappingStatus.suggested) &&
          targetAccountId != null &&
          targetAccountId!.isNotEmpty);

  AccountMappingEntry copyWith({
    String? legacyName,
    String? targetAccountId,
    String? targetAccountName,
    MappingStatus? status,
    int? transactionCount,
    bool? isTargetArchived,
  }) {
    return AccountMappingEntry(
      legacyName: legacyName ?? this.legacyName,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      targetAccountName: targetAccountName ?? this.targetAccountName,
      status: status ?? this.status,
      transactionCount: transactionCount ?? this.transactionCount,
      isTargetArchived: isTargetArchived ?? this.isTargetArchived,
    );
  }
}

class CategoryMappingEntry {
  final String legacyName;
  final String? targetCategoryId;
  final String? targetCategoryName;
  final CategoryType categoryType;
  final MappingStatus status;
  final int transactionCount;

  const CategoryMappingEntry({
    required this.legacyName,
    this.targetCategoryId,
    this.targetCategoryName,
    required this.categoryType,
    required this.status,
    this.transactionCount = 0,
  });

  bool get isMapped =>
      status == MappingStatus.ignored ||
      status == MappingStatus.createNew ||
      ((status == MappingStatus.exactMatch || status == MappingStatus.suggested) &&
          targetCategoryId != null &&
          targetCategoryId!.isNotEmpty);

  CategoryMappingEntry copyWith({
    String? legacyName,
    String? targetCategoryId,
    String? targetCategoryName,
    CategoryType? categoryType,
    MappingStatus? status,
    int? transactionCount,
  }) {
    return CategoryMappingEntry(
      legacyName: legacyName ?? this.legacyName,
      targetCategoryId: targetCategoryId ?? this.targetCategoryId,
      targetCategoryName: targetCategoryName ?? this.targetCategoryName,
      categoryType: categoryType ?? this.categoryType,
      status: status ?? this.status,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }
}

class ExcelWorkbookInfo {
  final String filePath;
  final String fileName;
  final List<String> sheetNames;

  const ExcelWorkbookInfo({
    required this.filePath,
    required this.fileName,
    required this.sheetNames,
  });
}

class ExcelColumnMapping {
  final ExcelSheetType sheetType;
  final int headerRowIndex;
  final int dateIndex;
  final int? categoryIndex;
  final int? accountIndex;
  final int? outgoingAccountIndex;
  final int? incomingAccountIndex;
  final int amountIndex;
  final int? currencyIndex;
  final int? commentIndex;
  final int? tagsIndex;

  const ExcelColumnMapping({
    required this.sheetType,
    required this.headerRowIndex,
    required this.dateIndex,
    this.categoryIndex,
    this.accountIndex,
    this.outgoingAccountIndex,
    this.incomingAccountIndex,
    required this.amountIndex,
    this.currencyIndex,
    this.commentIndex,
    this.tagsIndex,
  });

  bool get isValid {
    if (dateIndex < 0 || amountIndex < 0) return false;
    if (sheetType == ExcelSheetType.transfers) {
      return (outgoingAccountIndex != null && outgoingAccountIndex! >= 0) &&
          (incomingAccountIndex != null && incomingAccountIndex! >= 0);
    } else {
      return (accountIndex != null && accountIndex! >= 0) &&
          (categoryIndex != null && categoryIndex! >= 0);
    }
  }
}

class RawSheetRow {
  final String sheetName;
  final ExcelSheetType sheetType;
  final int rowNumber;
  final List<String> rawStrings;
  final DateTime? parsedDate;
  final Money? parsedAmount;
  final String? legacyCategory;
  final String? legacyAccount;
  final String? legacyOutgoingAccount;
  final String? legacyIncomingAccount;
  final String currency;
  final String? comment;

  const RawSheetRow({
    required this.sheetName,
    required this.sheetType,
    required this.rowNumber,
    required this.rawStrings,
    this.parsedDate,
    this.parsedAmount,
    this.legacyCategory,
    this.legacyAccount,
    this.legacyOutgoingAccount,
    this.legacyIncomingAccount,
    this.currency = 'INR',
    this.comment,
  });
}

class ExcelSheetAnalysis {
  final List<String> sheetNames;
  final String sheetName;
  final ExcelSheetType sheetType;
  final ExcelColumnMapping columnMapping;
  final int totalRows;
  final List<RawSheetRow> rawRows;
  final Map<String, AccountMappingEntry> accountMappings;
  final Map<String, CategoryMappingEntry> categoryMappings;
  final List<Account> existingAccounts;
  final List<Category> existingCategories;
  final DateTime? earliestDate;
  final DateTime? latestDate;
  final Map<String, int> sourceMonthlyCoverage;

  const ExcelSheetAnalysis({
    required this.sheetNames,
    required this.sheetName,
    required this.sheetType,
    required this.columnMapping,
    required this.totalRows,
    required this.rawRows,
    required this.accountMappings,
    required this.categoryMappings,
    required this.existingAccounts,
    required this.existingCategories,
    this.earliestDate,
    this.latestDate,
    this.sourceMonthlyCoverage = const {},
  });

  int get unmappedAccountsCount =>
      accountMappings.values.where((a) => a.status == MappingStatus.unmapped).length;

  int get unmappedCategoriesCount =>
      categoryMappings.values.where((c) => c.status == MappingStatus.unmapped).length;

  bool get canProceedToPreview =>
      unmappedAccountsCount == 0 && unmappedCategoriesCount == 0;
}

class ParsedImportItem {
  final String sheetName;
  final int rowNumber;
  final DateTime date;
  final String? legacyCategory;
  final String? mappedCategoryId;
  final String? mappedCategoryName;
  final String? legacyAccount;
  final String? mappedAccountId;
  final String? mappedAccountName;
  final String? legacyOutgoingAccount;
  final String? mappedOutgoingAccountId;
  final String? mappedOutgoingAccountName;
  final String? legacyIncomingAccount;
  final String? mappedIncomingAccountId;
  final String? mappedIncomingAccountName;
  final Money amount;
  final String currency;
  final String? comment;
  final ExcelSheetType sheetType;
  final bool isDuplicate;

  const ParsedImportItem({
    required this.sheetName,
    required this.rowNumber,
    required this.date,
    this.legacyCategory,
    this.mappedCategoryId,
    this.mappedCategoryName,
    this.legacyAccount,
    this.mappedAccountId,
    this.mappedAccountName,
    this.legacyOutgoingAccount,
    this.mappedOutgoingAccountId,
    this.mappedOutgoingAccountName,
    this.legacyIncomingAccount,
    this.mappedIncomingAccountId,
    this.mappedIncomingAccountName,
    required this.amount,
    required this.currency,
    this.comment,
    required this.sheetType,
    this.isDuplicate = false,
  });

  // Getters for legacy compatibility
  String? get categoryName => mappedCategoryName ?? legacyCategory;
  String? get accountName => mappedAccountName ?? legacyAccount;
  String? get outgoingAccountName => mappedOutgoingAccountName ?? legacyOutgoingAccount;
  String? get incomingAccountName => mappedIncomingAccountName ?? legacyIncomingAccount;
}

class InvalidRowInfo {
  final String sheetName;
  final int rowNumber;
  final String errorReason;
  final List<String> rawValues;

  const InvalidRowInfo({
    required this.sheetName,
    required this.rowNumber,
    required this.errorReason,
    required this.rawValues,
  });
}

class ExcelImportPreview {
  final List<String> sheetNames;
  final String sheetName;
  final ExcelSheetType sheetType;
  final ExcelColumnMapping mapping;
  final int totalRowsScanned;
  final List<ParsedImportItem> validItems;
  final List<InvalidRowInfo> invalidRows;
  final List<ParsedImportItem> duplicateItems;
  final Map<String, AccountMappingEntry> finalAccountMappings;
  final Map<String, CategoryMappingEntry> finalCategoryMappings;
  final Map<String, int> sheetItemCounts;
  final int expensesCount;
  final int incomeCount;
  final int transfersCount;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Map<String, int> sourceMonthlyCoverage;
  final Map<String, int> validMonthlyCoverage;

  const ExcelImportPreview({
    required this.sheetNames,
    required this.sheetName,
    required this.sheetType,
    required this.mapping,
    required this.totalRowsScanned,
    required this.validItems,
    required this.invalidRows,
    required this.duplicateItems,
    required this.finalAccountMappings,
    required this.finalCategoryMappings,
    this.sheetItemCounts = const {},
    this.expensesCount = 0,
    this.incomeCount = 0,
    this.transfersCount = 0,
    this.minDate,
    this.maxDate,
    this.sourceMonthlyCoverage = const {},
    this.validMonthlyCoverage = const {},
  });

  int get totalRows => totalRowsScanned;
  int get validCount => validItems.length;
  int get invalidCount => invalidRows.length;
  int get duplicateCount => duplicateItems.length;

  List<ParsedImportItem> get previewItems => validItems.take(10).toList();
  Set<int> get duplicateIndices => validItems
      .asMap()
      .entries
      .where((e) => e.value.isDuplicate)
      .map((e) => e.key)
      .toSet();

  // Legacy compatibility getters
  Set<String> get missingAccountNames => {};
  Set<String> get missingCategoryNames => {};
}

class ExcelImportResult {
  final List<String> sheetNames;
  final String sheetName;
  final int totalSourceRows;
  final int importedTransactionsCount;
  final int skippedDuplicatesCount;
  final int invalidRowsCount;
  final int failedCount;
  final int accountsMappedCount;
  final int categoriesMappedCount;
  final int createdAccountsCount;
  final int createdCategoriesCount;
  final int expensesImported;
  final int incomeImported;
  final int transfersImported;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Map<String, int> sourceMonthlyCoverage;
  final Map<String, int> importedMonthlyCoverage;
  final String? errorMessage;

  const ExcelImportResult({
    required this.sheetNames,
    required this.sheetName,
    this.totalSourceRows = 0,
    required this.importedTransactionsCount,
    required this.skippedDuplicatesCount,
    this.invalidRowsCount = 0,
    required this.failedCount,
    this.accountsMappedCount = 0,
    this.categoriesMappedCount = 0,
    this.createdAccountsCount = 0,
    this.createdCategoriesCount = 0,
    this.expensesImported = 0,
    this.incomeImported = 0,
    this.transfersImported = 0,
    this.minDate,
    this.maxDate,
    this.sourceMonthlyCoverage = const {},
    this.importedMonthlyCoverage = const {},
    this.errorMessage,
  });

  int get importedCount => importedTransactionsCount;
  int get skippedDuplicates => skippedDuplicatesCount;
  int get newAccountsCreated => createdAccountsCount;
  int get newCategoriesCreated => createdCategoriesCount;
  bool get isSuccess => errorMessage == null && failedCount == 0;
  bool get isReconciled =>
      totalSourceRows == 0 ||
      (importedTransactionsCount + skippedDuplicatesCount + invalidRowsCount + failedCount) == totalSourceRows;
}

class ExcelImportService {
  final AppDatabase appDatabase;

  ExcelImportService({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String formatMonthKey(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '$month ${date.year}';
  }

  static Map<String, int> sortMonthlyMap(Map<String, int> map) {
    const monthMap = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final sortedKeys = map.keys.toList()..sort((a, b) {
      final partsA = a.trim().split(' ');
      final partsB = b.trim().split(' ');
      final yearA = partsA.length >= 2 ? (int.tryParse(partsA[1]) ?? 2000) : 2000;
      final yearB = partsB.length >= 2 ? (int.tryParse(partsB[1]) ?? 2000) : 2000;
      if (yearA != yearB) return yearA.compareTo(yearB);
      final mA = partsA.isNotEmpty ? (monthMap[partsA[0].toLowerCase()] ?? 1) : 1;
      final mB = partsB.isNotEmpty ? (monthMap[partsB[0].toLowerCase()] ?? 1) : 1;
      return mA.compareTo(mB);
    });
    return {for (final k in sortedKeys) k: map[k]!};
  }

  /// 1. Reads workbook and returns list of sheet names
  Future<ExcelWorkbookInfo> readWorkbook(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheetNames = excel.tables.keys.toList();

    return ExcelWorkbookInfo(
      filePath: file.path,
      fileName: file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'workbook.xlsx',
      sheetNames: sheetNames,
    );
  }

  /// Helper to get text string from any CellValue type in excel package
  String _getCellValueString(CellValue? cell) {
    if (cell == null) return '';
    if (cell is TextCellValue) return cell.value.text ?? '';
    if (cell is IntCellValue) return cell.value.toString();
    if (cell is DoubleCellValue) return cell.value.toString();
    if (cell is DateCellValue) {
      return '${cell.year.toString().padLeft(4, '0')}-${cell.month.toString().padLeft(2, '0')}-${cell.day.toString().padLeft(2, '0')}';
    }
    if (cell is DateTimeCellValue) {
      return '${cell.year.toString().padLeft(4, '0')}-${cell.month.toString().padLeft(2, '0')}-${cell.day.toString().padLeft(2, '0')} ${cell.hour.toString().padLeft(2, '0')}:${cell.minute.toString().padLeft(2, '0')}:${cell.second.toString().padLeft(2, '0')}';
    }
    if (cell is TimeCellValue) {
      return '${cell.hour.toString().padLeft(2, '0')}:${cell.minute.toString().padLeft(2, '0')}:${cell.second.toString().padLeft(2, '0')}';
    }
    if (cell is BoolCellValue) return cell.value.toString();
    return cell.toString();
  }

  String _getDataValueString(Data? data) => _getCellValueString(data?.value);

  /// 2. Detects the header row and column indices for a selected sheet
  ExcelColumnMapping detectColumnMapping(Sheet sheet, String sheetName) {
    var detectedType = ExcelSheetType.fromName(sheetName);

    int headerRowIndex = -1;
    int dateIndex = -1;
    int? categoryIndex;
    int? accountIndex;
    int? outgoingAccountIndex;
    int? incomingAccountIndex;
    int amountIndex = -1;
    int? currencyIndex;
    int? commentIndex;
    int? tagsIndex;

    // Scan the first 10 rows to locate the header row
    final maxScanRows = sheet.rows.length < 10 ? sheet.rows.length : 10;
    for (int r = 0; r < maxScanRows; r++) {
      final row = sheet.rows[r];
      final stringValues = row.map((c) => _getDataValueString(c).trim().toLowerCase()).toList();

      // Check if this row looks like a header row
      final hasDate = stringValues.any((s) => s.contains('date'));
      final hasAmount = stringValues.any((s) => s.contains('amount'));
      final hasCategory = stringValues.any((s) => s.contains('category'));
      final hasAccount = stringValues.any((s) => s == 'account' || s.contains('account name') || s.contains('account'));
      final hasOutgoing = stringValues.any((s) => s.contains('outgoing') || s.contains('from account'));
      final hasIncoming = stringValues.any((s) => s.contains('incoming') || s.contains('to account'));

      if (hasDate && (hasAmount || hasCategory || hasAccount || hasOutgoing || hasIncoming)) {
        headerRowIndex = r;

        // Auto-detect sheet type if not already known
        if (hasOutgoing && hasIncoming) {
          detectedType = ExcelSheetType.transfers;
        } else if (detectedType == ExcelSheetType.unknown) {
          detectedType = ExcelSheetType.expenses;
        }

        // Map column indices
        for (int c = 0; c < stringValues.length; c++) {
          final col = stringValues[c];
          if (col.contains('date') && dateIndex == -1) {
            dateIndex = c;
          } else if (col == 'category' || col == 'category name') {
            categoryIndex = c;
          } else if (col == 'outgoing' || col == 'outgoing account' || col == 'from account' || col == 'from' ||
              (col.contains('outgoing') && !col.contains('amount') && !col.contains('currency') && outgoingAccountIndex == null)) {
            outgoingAccountIndex = c;
          } else if (col == 'incoming' || col == 'incoming account' || col == 'to account' || col == 'to' ||
              (col.contains('incoming') && !col.contains('amount') && !col.contains('currency') && incomingAccountIndex == null)) {
            incomingAccountIndex = c;
          } else if (col == 'account' || col == 'account name' || (col.contains('account') && !col.contains('currency') && !col.contains('amount') && accountIndex == null)) {
            accountIndex = c;
          } else if (col == 'amount in default currency' || col == 'amount in outgoing currency' || col == 'amount' || (amountIndex == -1 && col.contains('amount'))) {
            amountIndex = c;
          } else if (col == 'default currency' || col == 'outgoing currency' || col == 'currency' || (currencyIndex == null && col.contains('currency') && !col.contains('amount'))) {
            currencyIndex = c;
          } else if (col == 'comment' || col == 'notes' || col == 'description' || col.contains('comment') || col.contains('note')) {
            commentIndex = c;
          } else if (col.contains('tag')) {
            tagsIndex = c;
          }
        }
        break;
      }
    }

    // Default fallback if no header found
    if (headerRowIndex == -1) {
      headerRowIndex = 0;
      dateIndex = 0;
      categoryIndex = 1;
      accountIndex = 2;
      amountIndex = 3;
      currencyIndex = 4;
      commentIndex = 5;
    }

    return ExcelColumnMapping(
      sheetType: detectedType,
      headerRowIndex: headerRowIndex,
      dateIndex: dateIndex >= 0 ? dateIndex : 0,
      categoryIndex: categoryIndex,
      accountIndex: accountIndex,
      outgoingAccountIndex: outgoingAccountIndex,
      incomingAccountIndex: incomingAccountIndex,
      amountIndex: amountIndex >= 0 ? amountIndex : (sheet.rows.isNotEmpty && sheet.rows[0].length > 3 ? 3 : 1),
      currencyIndex: currencyIndex,
      commentIndex: commentIndex,
      tagsIndex: tagsIndex,
    );
  }

  /// Single sheet analysis helper
  Future<ExcelSheetAnalysis> analyzeSheet({
    required File file,
    required String sheetName,
    ExcelColumnMapping? customMapping,
  }) async {
    return analyzeSheets(
      file: file,
      sheetNames: [sheetName],
    );
  }

  /// 3. Analyzes multiple sheets from the legacy Excel file simultaneously,
  /// combines legacy accounts and categories into a single unified mapping set,
  /// and compares against existing Kals data.
  Future<ExcelSheetAnalysis> analyzeSheets({
    required File file,
    required List<String> sheetNames,
  }) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final db = await appDatabase.database;

    // 1. Fetch ALL existing accounts from DB (including archived for restore detection)
    final existingAccountsRows = await db.query(DbTables.accounts);
    final existingAccounts = existingAccountsRows.map((r) {
      return Account(
        id: r[DbColumns.id] as String,
        name: r[DbColumns.name] as String,
        accountType: AccountType.fromString(r[DbColumns.accountType] as String),
        openingBalance: Money(units: r[DbColumns.openingBalance] as int),
        currency: r[DbColumns.currency] as String? ?? 'INR',
        icon: r[DbColumns.icon] as String?,
        color: r[DbColumns.color] as int?,
        isArchived: (r[DbColumns.isArchived] as int? ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r[DbColumns.createdAt] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r[DbColumns.updatedAt] as int),
      );
    }).toList();

    // 2. Fetch existing categories from DB
    final existingCategoriesRows = await db.query(
      DbTables.categories,
      where: '${DbColumns.isArchived} = 0',
    );
    final existingCategories = existingCategoriesRows.map((r) {
      return Category(
        id: r[DbColumns.id] as String,
        name: r[DbColumns.name] as String,
        type: CategoryType.fromString(r[DbColumns.type] as String),
        icon: r[DbColumns.icon] as String?,
        color: r[DbColumns.color] as int?,
        sortOrder: r[DbColumns.sortOrder] as int? ?? 0,
        isArchived: (r[DbColumns.isArchived] as int? ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r[DbColumns.createdAt] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r[DbColumns.updatedAt] as int),
      );
    }).toList();

    final legacyAccountCounts = <String, int>{};
    final legacyCategoryCounts = <String, _CategoryWithCount>{};
    final rawRows = <RawSheetRow>[];
    final monthlyCoverage = <String, int>{};
    DateTime? minDate;
    DateTime? maxDate;
    ExcelColumnMapping? firstMapping;

    for (final sheetName in sheetNames) {
      final sheet = excel.tables[sheetName];
      if (sheet == null) continue;

      final mapping = detectColumnMapping(sheet, sheetName);
      firstMapping ??= mapping;
      final sheetType = mapping.sheetType;

      final rows = sheet.rows;
      final startIndex = mapping.headerRowIndex + 1;

      for (int r = startIndex; r < rows.length; r++) {
        final row = rows[r];
        final rawStrings = row.map((c) => _getDataValueString(c)).toList();
        if (rawStrings.every((s) => s.trim().isEmpty)) continue;

        final rowNum = r + 1;

        CellValue? dateCell;
        if (mapping.dateIndex < row.length) {
          dateCell = row[mapping.dateIndex]?.value;
        }
        final parsedDate = _parseDateTime(dateCell);

        if (parsedDate != null) {
          if (minDate == null || parsedDate.isBefore(minDate)) {
            minDate = parsedDate;
          }
          if (maxDate == null || parsedDate.isAfter(maxDate)) {
            maxDate = parsedDate;
          }
          final monthKey = formatMonthKey(parsedDate);
          monthlyCoverage[monthKey] = (monthlyCoverage[monthKey] ?? 0) + 1;
        }

        String amountStr = '';
        if (mapping.amountIndex < rawStrings.length) {
          amountStr = rawStrings[mapping.amountIndex].trim();
        }
        final parsedMoney = Money.tryParse(amountStr);

        String currency = 'INR';
        if (mapping.currencyIndex != null && mapping.currencyIndex! < rawStrings.length) {
          final cur = rawStrings[mapping.currencyIndex!].trim();
          if (cur.isNotEmpty) currency = cur.toUpperCase();
        }

        String? comment;
        if (mapping.commentIndex != null && mapping.commentIndex! < rawStrings.length) {
          final c = rawStrings[mapping.commentIndex!].trim();
          if (c.isNotEmpty) comment = c;
        }

        String? legacyAccount;
        String? legacyCategory;
        String? legacyOutgoing;
        String? legacyIncoming;

        if (sheetType == ExcelSheetType.transfers) {
          if (mapping.outgoingAccountIndex != null && mapping.outgoingAccountIndex! < rawStrings.length) {
            legacyOutgoing = rawStrings[mapping.outgoingAccountIndex!].trim();
            if (legacyOutgoing.isNotEmpty) {
              legacyAccountCounts[legacyOutgoing] = (legacyAccountCounts[legacyOutgoing] ?? 0) + 1;
            }
          }
          if (mapping.incomingAccountIndex != null && mapping.incomingAccountIndex! < rawStrings.length) {
            legacyIncoming = rawStrings[mapping.incomingAccountIndex!].trim();
            if (legacyIncoming.isNotEmpty) {
              legacyAccountCounts[legacyIncoming] = (legacyAccountCounts[legacyIncoming] ?? 0) + 1;
            }
          }
        } else {
          if (mapping.accountIndex != null && mapping.accountIndex! < rawStrings.length) {
            legacyAccount = rawStrings[mapping.accountIndex!].trim();
            if (legacyAccount.isNotEmpty) {
              legacyAccountCounts[legacyAccount] = (legacyAccountCounts[legacyAccount] ?? 0) + 1;
            }
          }
          if (mapping.categoryIndex != null && mapping.categoryIndex! < rawStrings.length) {
            legacyCategory = rawStrings[mapping.categoryIndex!].trim();
            if (legacyCategory.isNotEmpty) {
              final catType = sheetType == ExcelSheetType.income ? CategoryType.income : CategoryType.expense;
              final key = '$legacyCategory|${catType.name}';
              final existing = legacyCategoryCounts[key];
              if (existing != null) {
                legacyCategoryCounts[key] = _CategoryWithCount(name: legacyCategory, type: catType, count: existing.count + 1);
              } else {
                legacyCategoryCounts[key] = _CategoryWithCount(name: legacyCategory, type: catType, count: 1);
              }
            }
          }
        }

        rawRows.add(RawSheetRow(
          sheetName: sheetName,
          sheetType: sheetType,
          rowNumber: rowNum,
          rawStrings: rawStrings,
          parsedDate: parsedDate,
          parsedAmount: parsedMoney,
          legacyCategory: legacyCategory,
          legacyAccount: legacyAccount,
          legacyOutgoingAccount: legacyOutgoing,
          legacyIncomingAccount: legacyIncoming,
          currency: currency,
          comment: comment,
        ));
      }
    }

    // 4. Classify Account Mappings (Exact Match, Suggested Match, Default Create New for brand new)
    final accountMappings = <String, AccountMappingEntry>{};
    for (final entry in legacyAccountCounts.entries) {
      final legacyName = entry.key;
      final count = entry.value;

      final matched = _matchAccount(legacyName, existingAccounts);
      if (matched != null) {
        accountMappings[legacyName] = AccountMappingEntry(
          legacyName: legacyName,
          targetAccountId: matched.target.id,
          targetAccountName: matched.target.isArchived ? '${matched.target.name} (Deleted)' : matched.target.name,
          status: matched.status,
          transactionCount: count,
          isTargetArchived: matched.target.isArchived,
        );
      } else {
        // Genuinely new account: Default to "Create New" (pending creation until final import confirmation)
        accountMappings[legacyName] = AccountMappingEntry(
          legacyName: legacyName,
          targetAccountId: IdGenerator.generate(),
          targetAccountName: legacyName,
          status: MappingStatus.createNew,
          transactionCount: count,
          isTargetArchived: false,
        );
      }
    }

    // 5. Classify Category Mappings (Exact Match, Suggested Match, Default Create New for brand new)
    final categoryMappings = <String, CategoryMappingEntry>{};
    for (final entry in legacyCategoryCounts.values) {
      final legacyName = entry.name;
      final expectedType = entry.type;
      final count = entry.count;

      final matched = _matchCategory(legacyName, expectedType, existingCategories);
      if (matched != null) {
        categoryMappings[legacyName] = CategoryMappingEntry(
          legacyName: legacyName,
          targetCategoryId: matched.target.id,
          targetCategoryName: matched.target.name,
          categoryType: expectedType,
          status: matched.status,
          transactionCount: count,
        );
      } else {
        // Genuinely new category: Default to "Create New" (pending creation until final import confirmation)
        categoryMappings[legacyName] = CategoryMappingEntry(
          legacyName: legacyName,
          targetCategoryId: IdGenerator.generate(),
          targetCategoryName: legacyName,
          categoryType: expectedType,
          status: MappingStatus.createNew,
          transactionCount: count,
        );
      }
    }

    final primarySheetName = sheetNames.isNotEmpty ? sheetNames.first : 'Workbook';
    final primaryType = sheetNames.length == 1 ? ExcelSheetType.fromName(primarySheetName) : ExcelSheetType.unknown;

    return ExcelSheetAnalysis(
      sheetNames: sheetNames,
      sheetName: primarySheetName,
      sheetType: primaryType,
      columnMapping: firstMapping ?? ExcelColumnMapping(sheetType: primaryType, headerRowIndex: 0, dateIndex: 0, amountIndex: 1),
      totalRows: rawRows.length,
      rawRows: rawRows,
      accountMappings: accountMappings,
      categoryMappings: categoryMappings,
      existingAccounts: existingAccounts,
      existingCategories: existingCategories,
      earliestDate: minDate,
      latestDate: maxDate,
      sourceMonthlyCoverage: sortMonthlyMap(monthlyCoverage),
    );
  }

  /// Matches a legacy account name against existing Kals accounts
  _MatchResult<Account>? _matchAccount(String legacyName, List<Account> existing) {
    if (legacyName.trim().isEmpty || existing.isEmpty) return null;

    final normLegacy = _normalize(legacyName);

    // 1. Exact Match among active accounts
    for (final acc in existing) {
      if (!acc.isArchived && _normalize(acc.name) == normLegacy) {
        return _MatchResult(target: acc, status: MappingStatus.exactMatch);
      }
    }

    // 2. Exact Match among archived/deleted accounts (suggested match)
    for (final acc in existing) {
      if (acc.isArchived && _normalize(acc.name) == normLegacy) {
        return _MatchResult(target: acc, status: MappingStatus.suggested);
      }
    }

    // 3. Suggested Match (substring / word inclusion)
    for (final acc in existing) {
      final normExisting = _normalize(acc.name);
      if (normExisting.contains(normLegacy) || normLegacy.contains(normExisting)) {
        return _MatchResult(target: acc, status: MappingStatus.suggested);
      }
    }

    // 4. Known bank aliases (e.g. "sbi" vs "state bank of india", "hdfc bank" vs "hdfc")
    for (final acc in existing) {
      final normExisting = _normalize(acc.name);
      if (_isBankAlias(normLegacy, normExisting)) {
        return _MatchResult(target: acc, status: MappingStatus.suggested);
      }
    }

    return null;
  }

  /// Matches a legacy category name against existing Kals categories
  _MatchResult<Category>? _matchCategory(
    String legacyName,
    CategoryType type,
    List<Category> existing,
  ) {
    if (legacyName.trim().isEmpty || existing.isEmpty) return null;

    final normLegacy = _normalize(legacyName);
    final sameTypeCategories = existing.where((c) => c.type == type).toList();

    // 1. Exact Match (case-insensitive)
    for (final cat in sameTypeCategories) {
      if (_normalize(cat.name) == normLegacy) {
        return _MatchResult(target: cat, status: MappingStatus.exactMatch);
      }
    }

    // 2. Suggested Match (substring or token overlap)
    for (final cat in sameTypeCategories) {
      final normExisting = _normalize(cat.name);
      if (normExisting.contains(normLegacy) || normLegacy.contains(normExisting)) {
        return _MatchResult(target: cat, status: MappingStatus.suggested);
      }
    }

    // 3. Known category semantic aliases
    for (final cat in sameTypeCategories) {
      final normExisting = _normalize(cat.name);
      if (_isCategoryAlias(normLegacy, normExisting)) {
        return _MatchResult(target: cat, status: MappingStatus.suggested);
      }
    }

    return null;
  }

  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  bool _isBankAlias(String a, String b) {
    const bankAliases = [
      {'sbi', 'statebankofindia', 'sbisavings'},
      {'hdfc', 'hdfcbank', 'hdfcsavings'},
      {'icici', 'icicibank', 'icicisavings'},
      {'canara', 'canarabank'},
      {'axis', 'axisbank'},
      {'pnb', 'punjabnationalbank'},
      {'bob', 'bankofbaroda'},
      {'cash', 'cashinhand', 'pettycash'},
    ];
    for (final set in bankAliases) {
      if (set.contains(a) && set.contains(b)) return true;
    }
    return false;
  }

  bool _isCategoryAlias(String a, String b) {
    const categoryAliases = [
      {'medical', 'health', 'medicine', 'doctor', 'hospital', 'pharmacy', 'healthcare'},
      {'food', 'fooddining', 'dining', 'restaurant', 'groceries', 'supermarket', 'snacks'},
      {'travel', 'transport', 'transportation', 'fuel', 'petrol', 'diesel', 'cab', 'uber', 'ola'},
      {'bills', 'utilities', 'electricity', 'water', 'wifi', 'recharge', 'broadband', 'rent'},
      {'salary', 'wages', 'paycheck', 'payroll', 'income'},
      {'interest', 'dividend', 'investments', 'interestincome', 'otherincome'},
      {'shopping', 'clothing', 'apparel', 'electronics', 'ecommerce'},
      {'entertainment', 'movies', 'subscriptions', 'ott', 'games'},
    ];
    for (final set in categoryAliases) {
      if (set.contains(a) && set.contains(b)) return true;
    }
    return false;
  }

  /// 4. Builds final Preview and performs duplicate detection across all selected sheets
  Future<ExcelImportPreview> buildPreview({
    required ExcelSheetAnalysis analysis,
    required Map<String, AccountMappingEntry> accountMappings,
    required Map<String, CategoryMappingEntry> categoryMappings,
  }) async {
    final db = await appDatabase.database;

    // Fetch existing accounts & categories for signature matching
    final existingAccountsRows = await db.query(DbTables.accounts);
    final accountIdToName = <String, String>{};
    for (final r in existingAccountsRows) {
      accountIdToName[r[DbColumns.id] as String] = (r[DbColumns.name] as String).trim().toLowerCase();
    }

    final existingCategoriesRows = await db.query(DbTables.categories);
    final categoryIdToName = <String, String>{};
    for (final r in existingCategoriesRows) {
      categoryIdToName[r[DbColumns.id] as String] = (r[DbColumns.name] as String).trim().toLowerCase();
    }

    // Existing Transactions signatures for duplicate detection (multiset count tracking)
    final existingTxRows = await db.query(DbTables.transactions);
    final availableTxSignatures = <String, int>{};
    for (final r in existingTxRows) {
      final date = DateTime.fromMillisecondsSinceEpoch(r[DbColumns.date] as int);
      final amount = r[DbColumns.amount] as int;
      final accId = r[DbColumns.accountId] as String;
      final catId = r[DbColumns.categoryId] as String;
      final type = (r[DbColumns.transactionType] as String).toUpperCase();
      final notes = (r[DbColumns.notes] as String? ?? '').trim().toLowerCase();
      final accName = accountIdToName[accId] ?? accId;
      final catName = categoryIdToName[catId] ?? catId;
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}';
      final sig = '$dateKey|$type|$amount|$accName|$catName|$notes';
      availableTxSignatures[sig] = (availableTxSignatures[sig] ?? 0) + 1;
    }

    // Existing Transfers signatures for duplicate detection (multiset count tracking)
    final existingTrRows = await db.query(DbTables.transfers);
    final availableTrSignatures = <String, int>{};
    for (final r in existingTrRows) {
      final date = DateTime.fromMillisecondsSinceEpoch(r[DbColumns.date] as int);
      final amount = r[DbColumns.amount] as int;
      final fromAccId = r[DbColumns.fromAccountId] as String;
      final toAccId = r[DbColumns.toAccountId] as String;
      final desc = (r[DbColumns.description] as String? ?? '').trim().toLowerCase();
      final fromName = accountIdToName[fromAccId] ?? fromAccId;
      final toName = accountIdToName[toAccId] ?? toAccId;
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}';
      final sig = '$dateKey|$amount|$fromName|$toName|$desc';
      availableTrSignatures[sig] = (availableTrSignatures[sig] ?? 0) + 1;
    }

    final validItems = <ParsedImportItem>[];
    final invalidRows = <InvalidRowInfo>[];
    final duplicateItems = <ParsedImportItem>[];
    final sheetCounts = <String, int>{};
    final validMonthlyCoverage = <String, int>{};
    DateTime? minDate;
    DateTime? maxDate;
    int expensesCount = 0;
    int incomeCount = 0;
    int transfersCount = 0;

    for (final row in analysis.rawRows) {
      final rowNum = row.rowNumber;
      final currentSheetType = row.sheetType;
      final currentSheetName = row.sheetName;

      if (row.parsedDate == null) {
        invalidRows.add(InvalidRowInfo(
          sheetName: currentSheetName,
          rowNumber: rowNum,
          errorReason: 'Invalid or unparseable Date',
          rawValues: row.rawStrings,
        ));
        continue;
      }

      if (row.parsedAmount == null || row.parsedAmount!.units <= 0) {
        invalidRows.add(InvalidRowInfo(
          sheetName: currentSheetName,
          rowNumber: rowNum,
          errorReason: 'Invalid or non-positive Amount',
          rawValues: row.rawStrings,
        ));
        continue;
      }

      if (currentSheetType == ExcelSheetType.transfers) {
        final outName = row.legacyOutgoingAccount ?? '';
        final inName = row.legacyIncomingAccount ?? '';

        final outMapping = accountMappings[outName];
        final inMapping = accountMappings[inName];

        if (outMapping == null || inMapping == null) {
          invalidRows.add(InvalidRowInfo(
            sheetName: currentSheetName,
            rowNumber: rowNum,
            errorReason: 'Missing Account mapping ("$outName" or "$inName")',
            rawValues: row.rawStrings,
          ));
          continue;
        }

        if (outMapping.status == MappingStatus.ignored || inMapping.status == MappingStatus.ignored) {
          invalidRows.add(InvalidRowInfo(
            sheetName: currentSheetName,
            rowNumber: rowNum,
            errorReason: 'Skipped: Account mapped to Ignore',
            rawValues: row.rawStrings,
          ));
          continue;
        }

        if (outMapping.targetAccountId == null || inMapping.targetAccountId == null) {
          invalidRows.add(InvalidRowInfo(
            sheetName: currentSheetName,
            rowNumber: rowNum,
            errorReason: 'Unmapped Account ("$outName" or "$inName")',
            rawValues: row.rawStrings,
          ));
          continue;
        }

        if (outMapping.targetAccountId == inMapping.targetAccountId) {
          invalidRows.add(InvalidRowInfo(
            sheetName: currentSheetName,
            rowNumber: rowNum,
            errorReason: 'Transfer cannot have identical source and destination account',
            rawValues: row.rawStrings,
          ));
          continue;
        }

        final dateKey = '${row.parsedDate!.year}-${row.parsedDate!.month.toString().padLeft(2, "0")}-${row.parsedDate!.day.toString().padLeft(2, "0")}';
        final sig = '$dateKey|${row.parsedAmount!.units}|${outMapping.targetAccountName!.toLowerCase()}|${inMapping.targetAccountName!.toLowerCase()}|${(row.comment ?? "").trim().toLowerCase()}';
        bool isDup = false;
        final availableCount = availableTrSignatures[sig] ?? 0;
        if (availableCount > 0) {
          isDup = true;
          availableTrSignatures[sig] = availableCount - 1; // 1-to-1 multiset duplicate consumption
        }

        final item = ParsedImportItem(
          sheetName: currentSheetName,
          rowNumber: rowNum,
          date: row.parsedDate!,
          legacyOutgoingAccount: outName,
          mappedOutgoingAccountId: outMapping.targetAccountId,
          mappedOutgoingAccountName: outMapping.targetAccountName,
          legacyIncomingAccount: inName,
          mappedIncomingAccountId: inMapping.targetAccountId,
          mappedIncomingAccountName: inMapping.targetAccountName,
          amount: row.parsedAmount!,
          currency: row.currency,
          comment: row.comment,
          sheetType: currentSheetType,
          isDuplicate: isDup,
        );

        validItems.add(item);
        transfersCount++;
        sheetCounts[currentSheetName] = (sheetCounts[currentSheetName] ?? 0) + 1;
        if (isDup) duplicateItems.add(item);

        if (minDate == null || row.parsedDate!.isBefore(minDate)) {
          minDate = row.parsedDate;
        }
        if (maxDate == null || row.parsedDate!.isAfter(maxDate)) {
          maxDate = row.parsedDate;
        }
        final monthKey = formatMonthKey(row.parsedDate!);
        validMonthlyCoverage[monthKey] = (validMonthlyCoverage[monthKey] ?? 0) + 1;
      } else {
        // Expenses or Income
        final accName = row.legacyAccount ?? '';
        final catName = row.legacyCategory ?? 'Other';

        final accMapping = accountMappings[accName];
        final catMapping = categoryMappings[catName] ??
            (categoryMappings.isNotEmpty ? categoryMappings.values.first : null);

        if (accMapping == null || catMapping == null) {
          invalidRows.add(InvalidRowInfo(
            sheetName: currentSheetName,
            rowNumber: rowNum,
            errorReason: 'Missing Mapping (Account: "$accName", Category: "$catName")',
            rawValues: row.rawStrings,
          ));
          continue;
        }

        if (accMapping.status == MappingStatus.ignored || catMapping.status == MappingStatus.ignored) {
          invalidRows.add(InvalidRowInfo(
            sheetName: currentSheetName,
            rowNumber: rowNum,
            errorReason: 'Skipped: Mapped to Ignore',
            rawValues: row.rawStrings,
          ));
          continue;
        }

        if (accMapping.targetAccountId == null || catMapping.targetCategoryId == null) {
          invalidRows.add(InvalidRowInfo(
            sheetName: currentSheetName,
            rowNumber: rowNum,
            errorReason: 'Unmapped Account ("$accName") or Category ("$catName")',
            rawValues: row.rawStrings,
          ));
          continue;
        }

        final typeKey = currentSheetType == ExcelSheetType.income ? 'INCOME' : 'EXPENSE';
        final dateKey = '${row.parsedDate!.year}-${row.parsedDate!.month.toString().padLeft(2, "0")}-${row.parsedDate!.day.toString().padLeft(2, "0")}';
        final sig = '$dateKey|$typeKey|${row.parsedAmount!.units}|${accMapping.targetAccountName!.toLowerCase()}|${catMapping.targetCategoryName!.toLowerCase()}|${(row.comment ?? "").trim().toLowerCase()}';
        bool isDup = false;
        final availableCount = availableTxSignatures[sig] ?? 0;
        if (availableCount > 0) {
          isDup = true;
          availableTxSignatures[sig] = availableCount - 1; // 1-to-1 multiset duplicate consumption
        }

        final item = ParsedImportItem(
          sheetName: currentSheetName,
          rowNumber: rowNum,
          date: row.parsedDate!,
          legacyCategory: catName,
          mappedCategoryId: catMapping.targetCategoryId,
          mappedCategoryName: catMapping.targetCategoryName,
          legacyAccount: accName,
          mappedAccountId: accMapping.targetAccountId,
          mappedAccountName: accMapping.targetAccountName,
          amount: row.parsedAmount!,
          currency: row.currency,
          comment: row.comment,
          sheetType: currentSheetType,
          isDuplicate: isDup,
        );

        validItems.add(item);
        if (currentSheetType == ExcelSheetType.income) {
          incomeCount++;
        } else {
          expensesCount++;
        }
        sheetCounts[currentSheetName] = (sheetCounts[currentSheetName] ?? 0) + 1;
        if (isDup) duplicateItems.add(item);

        if (minDate == null || row.parsedDate!.isBefore(minDate)) {
          minDate = row.parsedDate;
        }
        if (maxDate == null || row.parsedDate!.isAfter(maxDate)) {
          maxDate = row.parsedDate;
        }
        final monthKey = formatMonthKey(row.parsedDate!);
        validMonthlyCoverage[monthKey] = (validMonthlyCoverage[monthKey] ?? 0) + 1;
      }
    }

    return ExcelImportPreview(
      sheetNames: analysis.sheetNames,
      sheetName: analysis.sheetName,
      sheetType: analysis.sheetType,
      mapping: analysis.columnMapping,
      totalRowsScanned: analysis.totalRows,
      validItems: validItems,
      invalidRows: invalidRows,
      duplicateItems: duplicateItems,
      finalAccountMappings: accountMappings,
      finalCategoryMappings: categoryMappings,
      sheetItemCounts: sheetCounts,
      expensesCount: expensesCount,
      incomeCount: incomeCount,
      transfersCount: transfersCount,
      minDate: minDate,
      maxDate: maxDate,
      sourceMonthlyCoverage: analysis.sourceMonthlyCoverage,
      validMonthlyCoverage: sortMonthlyMap(validMonthlyCoverage),
    );
  }

  /// 5. Executes the import transactionally into SQLite using the user's mapped IDs
  Future<ExcelImportResult> executeImport({
    required ExcelImportPreview preview,
    required bool skipDuplicates,
  }) async {
    final db = await appDatabase.database;

    int importedCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    int expensesCount = 0;
    int incomeCount = 0;
    int transfersCount = 0;
    final importedMonthlyCounts = <String, int>{};

    try {
      await db.transaction((txn) async {
        final now = DateTime.now();

        // 1. Persist pending newly created accounts (if chosen by user/defaulted)
        for (final accEntry in preview.finalAccountMappings.values) {
          if (accEntry.targetAccountId != null && accEntry.status != MappingStatus.ignored) {
            final exists = await txn.query(
              DbTables.accounts,
              where: '${DbColumns.id} = ?',
              whereArgs: [accEntry.targetAccountId],
            );
            if (exists.isEmpty) {
              await txn.insert(DbTables.accounts, {
                DbColumns.id: accEntry.targetAccountId,
                DbColumns.name: accEntry.targetAccountName ?? accEntry.legacyName,
                DbColumns.accountType: 'BANK',
                DbColumns.openingBalance: 0,
                DbColumns.currency: 'INR',
                DbColumns.icon: 'account_balance_outlined',
                DbColumns.color: 0xFF1976D2,
                DbColumns.isArchived: 0,
                DbColumns.createdAt: now.millisecondsSinceEpoch,
                DbColumns.updatedAt: now.millisecondsSinceEpoch,
              });
            }
          }
        }

        // 2. Persist pending newly created categories (if chosen by user/defaulted)
        for (final catEntry in preview.finalCategoryMappings.values) {
          if (catEntry.targetCategoryId != null && catEntry.status != MappingStatus.ignored) {
            final exists = await txn.query(
              DbTables.categories,
              where: '${DbColumns.id} = ?',
              whereArgs: [catEntry.targetCategoryId],
            );
            if (exists.isEmpty) {
              await txn.insert(DbTables.categories, {
                DbColumns.id: catEntry.targetCategoryId,
                DbColumns.name: catEntry.targetCategoryName ?? catEntry.legacyName,
                DbColumns.type: catEntry.categoryType.toDbString(),
                DbColumns.icon: catEntry.categoryType == CategoryType.income ? 'payments_outlined' : 'category_outlined',
                DbColumns.color: catEntry.categoryType == CategoryType.income ? 0xFF059669 : 0xFF2563EB,
                DbColumns.sortOrder: 0,
                DbColumns.isArchived: 0,
                DbColumns.createdAt: now.millisecondsSinceEpoch,
                DbColumns.updatedAt: now.millisecondsSinceEpoch,
              });
            }
          }
        }

        for (final item in preview.validItems) {
          if (item.isDuplicate && skipDuplicates) {
            skippedCount++;
            continue;
          }

          if (item.sheetType == ExcelSheetType.transfers) {
            final fromAccId = item.mappedOutgoingAccountId;
            final toAccId = item.mappedIncomingAccountId;

            if (fromAccId == null || toAccId == null) {
              failedCount++;
              continue;
            }

            final comment = (item.comment != null && item.comment!.trim().isNotEmpty) ? item.comment!.trim() : null;
            final transferId = IdGenerator.generate();
            await txn.insert(DbTables.transfers, {
              DbColumns.id: transferId,
              DbColumns.fromAccountId: fromAccId,
              DbColumns.toAccountId: toAccId,
              DbColumns.amount: item.amount.units,
              DbColumns.date: item.date.millisecondsSinceEpoch,
              DbColumns.description: comment ?? 'Transfer',
              DbColumns.receiptPath: null,
              DbColumns.createdAt: now.millisecondsSinceEpoch,
              DbColumns.updatedAt: now.millisecondsSinceEpoch,
            });

            importedCount++;
            transfersCount++;
            final monthKey = formatMonthKey(item.date);
            importedMonthlyCounts[monthKey] = (importedMonthlyCounts[monthKey] ?? 0) + 1;
          } else {
            final accId = item.mappedAccountId;
            final catId = item.mappedCategoryId;
            final catTypeStr = item.sheetType == ExcelSheetType.income ? 'INCOME' : 'EXPENSE';

            if (accId == null || catId == null) {
              failedCount++;
              continue;
            }

            final comment = (item.comment != null && item.comment!.trim().isNotEmpty) ? item.comment!.trim() : null;
            final txId = IdGenerator.generate();
            await txn.insert(DbTables.transactions, {
              DbColumns.id: txId,
              DbColumns.transactionType: catTypeStr,
              DbColumns.accountId: accId,
              DbColumns.categoryId: catId,
              DbColumns.amount: item.amount.units,
              DbColumns.date: item.date.millisecondsSinceEpoch,
              DbColumns.description: comment ?? (item.categoryName ?? 'Imported'),
              DbColumns.notes: comment,
              DbColumns.receiptPath: null,
              DbColumns.createdAt: now.millisecondsSinceEpoch,
              DbColumns.updatedAt: now.millisecondsSinceEpoch,
            });

            importedCount++;
            if (item.sheetType == ExcelSheetType.income) {
              incomeCount++;
            } else {
              expensesCount++;
            }
            final monthKey = formatMonthKey(item.date);
            importedMonthlyCounts[monthKey] = (importedMonthlyCounts[monthKey] ?? 0) + 1;
          }
        }
      });

      return ExcelImportResult(
        sheetNames: preview.sheetNames,
        sheetName: preview.sheetName,
        totalSourceRows: preview.totalRowsScanned,
        importedTransactionsCount: importedCount,
        skippedDuplicatesCount: skippedCount,
        invalidRowsCount: preview.invalidCount,
        failedCount: failedCount,
        accountsMappedCount: preview.finalAccountMappings.values.where((a) => a.isMapped).length,
        categoriesMappedCount: preview.finalCategoryMappings.values.where((c) => c.isMapped).length,
        expensesImported: expensesCount,
        incomeImported: incomeCount,
        transfersImported: transfersCount,
        minDate: preview.minDate,
        maxDate: preview.maxDate,
        sourceMonthlyCoverage: preview.sourceMonthlyCoverage,
        importedMonthlyCoverage: sortMonthlyMap(importedMonthlyCounts),
      );
    } catch (e) {
      return ExcelImportResult(
        sheetNames: preview.sheetNames,
        sheetName: preview.sheetName,
        totalSourceRows: preview.totalRowsScanned,
        importedTransactionsCount: 0,
        skippedDuplicatesCount: 0,
        invalidRowsCount: preview.invalidCount,
        failedCount: preview.validItems.length,
        errorMessage: 'Import failed and was completely rolled back: $e',
      );
    }
  }

  /// Parses date from cell value supporting standard Excel date formats & serial dates
  DateTime? _parseDateTime(CellValue? cell) {
    if (cell == null) return null;
    if (cell is DateCellValue) {
      return DateTime(cell.year, cell.month, cell.day);
    }
    if (cell is DateTimeCellValue) {
      return DateTime(cell.year, cell.month, cell.day, cell.hour, cell.minute, cell.second);
    }

    if (cell is IntCellValue) {
      final val = cell.value;
      if (val >= 1 && val <= 2958465) {
        return _parseExcelSerial(val);
      }
    }
    if (cell is DoubleCellValue) {
      final val = cell.value;
      if (val >= 1.0 && val <= 2958465.0) {
        return _parseExcelSerial(val);
      }
    }

    final raw = _getCellValueString(cell).trim();
    if (raw.isEmpty) return null;

    // Check if raw string is numeric serial number (e.g. "45658" or "45658.5")
    final numVal = num.tryParse(raw);
    if (numVal != null && numVal >= 30000 && numVal <= 100000) {
      return _parseExcelSerial(numVal);
    }

    // Standard ISO-8601 string try
    final iso = DateTime.tryParse(raw);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day, iso.hour, iso.minute, iso.second);
    }

    final formats = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-dd',
      'yyyy/MM/dd HH:mm:ss',
      'yyyy/MM/dd HH:mm',
      'yyyy/MM/dd',
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm',
      'dd-MM-yyyy',
      'dd.MM.yyyy HH:mm:ss',
      'dd.MM.yyyy',
      'dd-MMM-yyyy HH:mm:ss',
      'dd-MMM-yyyy HH:mm',
      'dd-MMM-yyyy',
      'dd MMM yyyy HH:mm:ss',
      'dd MMM yyyy HH:mm',
      'dd MMM yyyy',
      'MMM dd, yyyy',
      'MMMM dd, yyyy',
      'dd-MMM-yy',
      'dd MMM yy',
      'dd/MM/yy',
      'dd-MM-yy',
      'MM/dd/yyyy HH:mm:ss',
      'MM/dd/yyyy HH:mm',
      'MM/dd/yyyy',
      'M/d/yyyy HH:mm:ss',
      'M/d/yyyy HH:mm',
      'M/d/yyyy',
      'd/M/yyyy HH:mm:ss',
      'd/M/yyyy HH:mm',
      'd/M/yyyy',
      'd-M-yyyy HH:mm:ss',
      'd-M-yyyy HH:mm',
      'd-M-yyyy',
      // 12-hour AM/PM formats
      'dd/MM/yyyy hh:mm:ss a',
      'dd/MM/yyyy hh:mm a',
      'dd/MM/yyyy h:mm a',
      'dd-MM-yyyy hh:mm:ss a',
      'dd-MM-yyyy hh:mm a',
      'dd-MM-yyyy h:mm a',
      'dd-MMM-yyyy hh:mm:ss a',
      'dd-MMM-yyyy hh:mm a',
      'dd-MMM-yyyy h:mm a',
      'dd MMM yyyy hh:mm:ss a',
      'dd MMM yyyy hh:mm a',
      'dd MMM yyyy h:mm a',
      'yyyy-MM-dd hh:mm:ss a',
      'yyyy-MM-dd hh:mm a',
      'yyyy-MM-dd h:mm a',
      'MM/dd/yyyy hh:mm:ss a',
      'MM/dd/yyyy hh:mm a',
      'MM/dd/yyyy h:mm a',
      'M/d/yyyy h:mm:ss a',
      'M/d/yyyy h:mm a',
      'd/M/yyyy h:mm:ss a',
      'd/M/yyyy h:mm a',
    ];

    for (final fmt in formats) {
      try {
        final parsed = DateFormat(fmt, 'en_US').parseLoose(raw);
        return DateTime(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute, parsed.second);
      } catch (_) {}
    }

    return null;
  }

  /// Parses Excel serial day number to DateTime
  DateTime _parseExcelSerial(num serial) {
    final wholeDays = serial.floor();
    final dayFraction = serial - wholeDays;
    final epoch = wholeDays >= 60 ? DateTime(1899, 12, 30) : DateTime(1899, 12, 31);
    final date = epoch.add(Duration(days: wholeDays));
    final millisecondsInDay = (dayFraction * 86400000).round();
    final finalDate = date.add(Duration(milliseconds: millisecondsInDay));
    return DateTime(finalDate.year, finalDate.month, finalDate.day, finalDate.hour, finalDate.minute, finalDate.second);
  }

  /// Legacy compatibility wrapper
  Future<ExcelImportPreview> parseAndValidateSheet({
    required File file,
    required String sheetName,
    ExcelColumnMapping? customMapping,
  }) async {
    final analysis = await analyzeSheet(
      file: file,
      sheetName: sheetName,
      customMapping: customMapping,
    );

    return buildPreview(
      analysis: analysis,
      accountMappings: analysis.accountMappings,
      categoryMappings: analysis.categoryMappings,
    );
  }
}

class _CategoryWithCount {
  final String name;
  final CategoryType type;
  final int count;

  const _CategoryWithCount({
    required this.name,
    required this.type,
    required this.count,
  });
}

class _MatchResult<T> {
  final T target;
  final MappingStatus status;

  const _MatchResult({required this.target, required this.status});
}
