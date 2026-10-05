import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/utilities/money.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../categories/domain/entities/category.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/excel_import_service.dart';

enum ImportWizardStep {
  selectFileAndSheet,
  accountMapping,
  categoryMapping,
  previewAndValidate,
  importResult,
}

class ExcelImportProvider extends ChangeNotifier {
  final ExcelImportService _importService;
  final BackupService _backupService;
  final AppDatabase _appDatabase;

  File? _selectedFile;
  ExcelWorkbookInfo? _workbookInfo;
  Set<String> _selectedSheetNames = {};
  ExcelSheetAnalysis? _analysis;
  Map<String, AccountMappingEntry> _accountMappings = {};
  Map<String, CategoryMappingEntry> _categoryMappings = {};
  ExcelImportPreview? _preview;
  bool _skipDuplicates = true;
  bool _isLoading = false;
  String? _errorMessage;
  ExcelImportResult? _lastResult;
  ImportWizardStep _currentStep = ImportWizardStep.selectFileAndSheet;

  ExcelImportProvider({
    ExcelImportService? importService,
    BackupService? backupService,
    AppDatabase? database,
  })  : _importService = importService ?? ExcelImportService(),
        _backupService = backupService ?? BackupService(),
        _appDatabase = database ?? AppDatabase.instance;

  File? get selectedFile => _selectedFile;
  ExcelWorkbookInfo? get workbookInfo => _workbookInfo;
  Set<String> get selectedSheetNames => _selectedSheetNames;
  String? get selectedSheetName => _selectedSheetNames.isNotEmpty ? _selectedSheetNames.first : null;
  ExcelSheetAnalysis? get analysis => _analysis;
  Map<String, AccountMappingEntry> get accountMappings => _accountMappings;
  Map<String, CategoryMappingEntry> get categoryMappings => _categoryMappings;
  ExcelImportPreview? get preview => _preview;
  bool get skipDuplicates => _skipDuplicates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ExcelImportResult? get lastResult => _lastResult;
  ImportWizardStep get currentStep => _currentStep;

  void setStep(ImportWizardStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void setSkipDuplicates(bool value) {
    _skipDuplicates = value;
    notifyListeners();
  }

  void toggleSheetSelection(String sheetName) {
    if (_selectedSheetNames.contains(sheetName)) {
      _selectedSheetNames.remove(sheetName);
    } else {
      _selectedSheetNames.add(sheetName);
    }
    notifyListeners();
  }

  void selectAllSheets() {
    if (_workbookInfo != null) {
      _selectedSheetNames = Set.from(_workbookInfo!.sheetNames);
      notifyListeners();
    }
  }

  Future<void> pickExcelFile() async {
    _errorMessage = null;
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result.isEmpty || result.first.path == null) {
        return;
      }

      final file = File(result.first.path!);
      await loadFile(file);
    } catch (e) {
      _errorMessage = 'Failed to open Excel file: $e';
      notifyListeners();
    }
  }

  Future<void> loadFile(File file) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedFile = file;
    _workbookInfo = null;
    _selectedSheetNames = {};
    _analysis = null;
    _accountMappings = {};
    _categoryMappings = {};
    _preview = null;
    _lastResult = null;
    _currentStep = ImportWizardStep.selectFileAndSheet;
    notifyListeners();

    try {
      _workbookInfo = await _importService.readWorkbook(file);
      if (_workbookInfo!.sheetNames.isEmpty) {
        _errorMessage = 'The selected Excel file contains no worksheets.';
      } else {
        // Pre-select known finance sheets or all sheets
        final detected = _workbookInfo!.sheetNames.where((name) {
          final lower = name.toLowerCase();
          return lower.contains('expense') || lower.contains('income') || lower.contains('transfer');
        }).toSet();
        _selectedSheetNames = detected.isNotEmpty ? detected : Set.from(_workbookInfo!.sheetNames);
      }
    } catch (e) {
      _errorMessage = 'Unable to read Excel workbook: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Single sheet analysis helper
  Future<void> selectSheet(String sheetName) async {
    _selectedSheetNames = {sheetName};
    await analyzeSelectedSheets();
  }

  /// Analyzes all selected sheets together
  Future<void> analyzeSelectedSheets() async {
    if (_selectedFile == null || _selectedSheetNames.isEmpty) {
      _errorMessage = 'Please select at least one sheet to import.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _analysis = await _importService.analyzeSheets(
        file: _selectedFile!,
        sheetNames: _selectedSheetNames.toList(),
      );
      _accountMappings = Map.from(_analysis!.accountMappings);
      _categoryMappings = Map.from(_analysis!.categoryMappings);

      // Move to Account Mapping step
      _currentStep = ImportWizardStep.accountMapping;
    } catch (e) {
      _errorMessage = 'Failed to analyze selected sheets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateAccountMapping({
    required String legacyName,
    String? targetAccountId,
    String? targetAccountName,
    required MappingStatus status,
  }) {
    final current = _accountMappings[legacyName];
    if (current == null) return;

    _accountMappings[legacyName] = current.copyWith(
      targetAccountId: targetAccountId,
      targetAccountName: targetAccountName,
      status: status,
    );
    notifyListeners();
  }

  void updateCategoryMapping({
    required String legacyName,
    String? targetCategoryId,
    String? targetCategoryName,
    required MappingStatus status,
  }) {
    final current = _categoryMappings[legacyName];
    if (current == null) return;

    _categoryMappings[legacyName] = current.copyWith(
      targetCategoryId: targetCategoryId,
      targetCategoryName: targetCategoryName,
      status: status,
    );
    notifyListeners();
  }

  /// Restores a previously deleted/archived account and maps to it
  Future<void> restoreAndMapAccount({
    required String legacyName,
    required String accountId,
    required String accountName,
  }) async {
    final db = await _appDatabase.database;
    await db.update(
      DbTables.accounts,
      {
        DbColumns.isArchived: 0,
        DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbColumns.id} = ?',
      whereArgs: [accountId],
    );

    updateAccountMapping(
      legacyName: legacyName,
      targetAccountId: accountId,
      targetAccountName: accountName,
      status: MappingStatus.exactMatch,
    );
  }

  /// Creates a genuinely new Account in Kals and maps the legacy account to it
  Future<Account> createAndMapNewAccount({
    required String legacyName,
    required String accountName,
    required AccountType accountType,
    int? color,
    String? icon,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now();
    final newId = IdGenerator.generate();

    await db.insert(DbTables.accounts, {
      DbColumns.id: newId,
      DbColumns.name: accountName.trim(),
      DbColumns.accountType: accountType.name.toUpperCase(),
      DbColumns.openingBalance: 0,
      DbColumns.currency: 'INR',
      DbColumns.icon: icon ?? 'account_balance',
      DbColumns.color: color ?? 0xFF1976D2,
      DbColumns.isArchived: 0,
      DbColumns.createdAt: now.millisecondsSinceEpoch,
      DbColumns.updatedAt: now.millisecondsSinceEpoch,
    });

    final newAccount = Account(
      id: newId,
      name: accountName.trim(),
      accountType: accountType,
      openingBalance: const Money.zero(),
      icon: icon ?? 'account_balance',
      color: color ?? 0xFF1976D2,
      createdAt: now,
      updatedAt: now,
    );

    // Refresh existing accounts in analysis
    if (_analysis != null) {
      _analysis = ExcelSheetAnalysis(
        sheetNames: _analysis!.sheetNames,
        sheetName: _analysis!.sheetName,
        sheetType: _analysis!.sheetType,
        columnMapping: _analysis!.columnMapping,
        totalRows: _analysis!.totalRows,
        rawRows: _analysis!.rawRows,
        accountMappings: _analysis!.accountMappings,
        categoryMappings: _analysis!.categoryMappings,
        existingAccounts: [..._analysis!.existingAccounts, newAccount],
        existingCategories: _analysis!.existingCategories,
      );
    }

    updateAccountMapping(
      legacyName: legacyName,
      targetAccountId: newId,
      targetAccountName: accountName.trim(),
      status: MappingStatus.exactMatch,
    );

    return newAccount;
  }

  /// Creates a genuinely new Category in Kals and maps the legacy category to it
  Future<Category> createAndMapNewCategory({
    required String legacyName,
    required String categoryName,
    required CategoryType categoryType,
    int? color,
    String? icon,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now();
    final newId = IdGenerator.generate();
    final typeStr = categoryType.name.toUpperCase();

    await db.insert(DbTables.categories, {
      DbColumns.id: newId,
      DbColumns.name: categoryName.trim(),
      DbColumns.type: typeStr,
      DbColumns.icon: icon ?? 'category',
      DbColumns.color: color ?? 0xFF43A047,
      DbColumns.sortOrder: 0,
      DbColumns.isArchived: 0,
      DbColumns.createdAt: now.millisecondsSinceEpoch,
      DbColumns.updatedAt: now.millisecondsSinceEpoch,
    });

    final newCategory = Category(
      id: newId,
      name: categoryName.trim(),
      type: categoryType,
      icon: icon ?? 'category',
      color: color ?? 0xFF43A047,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    // Refresh existing categories in analysis
    if (_analysis != null) {
      _analysis = ExcelSheetAnalysis(
        sheetNames: _analysis!.sheetNames,
        sheetName: _analysis!.sheetName,
        sheetType: _analysis!.sheetType,
        columnMapping: _analysis!.columnMapping,
        totalRows: _analysis!.totalRows,
        rawRows: _analysis!.rawRows,
        accountMappings: _analysis!.accountMappings,
        categoryMappings: _analysis!.categoryMappings,
        existingAccounts: _analysis!.existingAccounts,
        existingCategories: [..._analysis!.existingCategories, newCategory],
      );
    }

    updateCategoryMapping(
      legacyName: legacyName,
      targetCategoryId: newId,
      targetCategoryName: categoryName.trim(),
      status: MappingStatus.exactMatch,
    );

    return newCategory;
  }

  /// Creates backup file before importing large financial dataset
  Future<String?> createBackupBeforeImport() async {
    try {
      final file = await _backupService.exportBackupToFile();
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Generates the preview with final mapped Kals values and duplicate detection
  Future<void> generatePreview() async {
    if (_analysis == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _preview = await _importService.buildPreview(
        analysis: _analysis!,
        accountMappings: _accountMappings,
        categoryMappings: _categoryMappings,
      );
      _currentStep = ImportWizardStep.previewAndValidate;
    } catch (e) {
      _errorMessage = 'Failed to generate preview: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Executes the confirmed import into SQLite
  Future<void> executeImport({bool createBackupFirst = false}) async {
    if (_preview == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (createBackupFirst) {
        await _backupService.exportBackupToFile();
      }

      _lastResult = await _importService.executeImport(
        preview: _preview!,
        skipDuplicates: _skipDuplicates,
      );
      _currentStep = ImportWizardStep.importResult;
    } catch (e) {
      _errorMessage = 'Import execution error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedFile = null;
    _workbookInfo = null;
    _selectedSheetNames = {};
    _analysis = null;
    _accountMappings = {};
    _categoryMappings = {};
    _preview = null;
    _lastResult = null;
    _errorMessage = null;
    _currentStep = ImportWizardStep.selectFileAndSheet;
    notifyListeners();
  }
}
