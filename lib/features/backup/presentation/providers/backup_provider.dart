import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/integrity_service.dart';

class BackupProvider extends ChangeNotifier {
  final BackupService backupService;
  final ExcelExportService excelExportService;
  final IntegrityService integrityService;

  BackupProvider({
    required this.backupService,
    required this.excelExportService,
    required this.integrityService,
  });

  bool _isProcessing = false;
  String? _statusMessage;
  String? _errorMessage;
  IntegrityReport? _latestIntegrityReport;
  File? _lastExportFile;
  File? _lastBackupFile;

  bool get isProcessing => _isProcessing;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  IntegrityReport? get latestIntegrityReport => _latestIntegrityReport;
  File? get lastExportFile => _lastExportFile;
  File? get lastBackupFile => _lastBackupFile;

  Future<File?> createBackupFile() async {
    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Creating secure local backup...';
    notifyListeners();

    try {
      final file = await backupService.exportBackupToFile();
      _lastBackupFile = file;
      _statusMessage = 'Backup created at: ${file.path}';
      return file;
    } catch (e) {
      _errorMessage = 'Failed to create backup: $e';
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> restoreFromFile(File file) async {
    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Validating and restoring backup...';
    notifyListeners();

    try {
      await backupService.restoreFromFile(file);
      _statusMessage = 'Data restored successfully!';
      return true;
    } catch (e) {
      _errorMessage = 'Restore failed: $e. Existing data was preserved.';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<File?> exportToExcel({ExcelExportFilter? filter}) async {
    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Generating Excel report...';
    notifyListeners();

    try {
      final file = await excelExportService.generateExcelWorkbook(filter: filter);
      _lastExportFile = file;
      _statusMessage = 'Excel report exported: ${file.path}';
      return file;
    } catch (e) {
      _errorMessage = 'Failed to export Excel report: $e';
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<IntegrityReport> runIntegrityCheck() async {
    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Verifying database integrity...';
    notifyListeners();

    try {
      final report = await integrityService.runComprehensiveCheck();
      _latestIntegrityReport = report;
      return report;
    } catch (e) {
      _errorMessage = 'Integrity verification encountered an error: $e';
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
