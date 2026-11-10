import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/services/automatic_export_service.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/integrity_service.dart';

class BackupProvider extends ChangeNotifier {
  final BackupService backupService;
  final ExcelExportService excelExportService;
  final IntegrityService integrityService;
  final AutomaticExportService? automaticExportService;
  final NotificationService? notificationService;

  BackupProvider({
    required this.backupService,
    required this.excelExportService,
    required this.integrityService,
    this.automaticExportService,
    this.notificationService,
  }) {
    loadAutoExportConfig();
  }

  bool _isProcessing = false;
  String? _statusMessage;
  String? _errorMessage;
  IntegrityReport? _latestIntegrityReport;
  File? _lastExportFile;
  File? _lastBackupFile;
  AutoExportConfig _autoExportConfig = const AutoExportConfig();

  bool get isProcessing => _isProcessing;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  IntegrityReport? get latestIntegrityReport => _latestIntegrityReport;
  File? get lastExportFile => _lastExportFile;
  File? get lastBackupFile => _lastBackupFile;
  AutoExportConfig get autoExportConfig => _autoExportConfig;

  Future<void> loadAutoExportConfig() async {
    if (automaticExportService != null) {
      try {
        _autoExportConfig = await automaticExportService!.loadConfig();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('BackupProvider: Error loading auto export config: $e');
        }
      }
    }
  }

  Future<void> updateAutoExportConfig(AutoExportConfig config) async {
    _autoExportConfig = config;
    notifyListeners();
    if (automaticExportService != null) {
      try {
        await automaticExportService!.saveConfig(config);
        _autoExportConfig = await automaticExportService!.loadConfig();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('BackupProvider: Error saving auto export config: $e');
        }
      }
    }
  }

  Future<AutoExportResult?> runAutoExportNow() async {
    if (automaticExportService == null) return null;
    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Running export with integrity validation...';
    notifyListeners();

    try {
      final result = await automaticExportService!.executeExport(isManual: true);
      if (result.success && result.file != null) {
        if (_autoExportConfig.format == AutoExportFormat.backup) {
          _lastBackupFile = result.file;
        } else {
          _lastExportFile = result.file;
        }
        _statusMessage = 'Export completed: ${result.file!.path}';
      } else {
        _errorMessage = result.errorMessage ?? 'Export failed';
      }
      await loadAutoExportConfig();
      return result;
    } catch (e) {
      _errorMessage = 'Export failed: $e';
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<File?> createBackupFile({bool notify = false}) async {
    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Creating secure local backup...';
    notifyListeners();

    try {
      final file = await backupService.exportBackupToFile();
      _lastBackupFile = file;
      _statusMessage = 'Backup created at: ${file.path}';
      if (automaticExportService != null) {
        await automaticExportService!.recordManualExport(isBackup: true, file: file);
        await loadAutoExportConfig();
      }
      if (notify) {
        final notif = notificationService ?? NotificationService();
        await notif.showExportNotification(
          title: "Kal's Money Manager",
          body: 'Your local backup has been created successfully (${file.path.split(Platform.pathSeparator).last}).',
          isSuccess: true,
          filePath: file.path,
        );
      }
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

  Future<File?> exportToExcel({ExcelExportFilter? filter, bool notify = false}) async {
    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Generating Excel report...';
    notifyListeners();

    try {
      final file = await excelExportService.generateExcelWorkbook(filter: filter);
      _lastExportFile = file;
      _statusMessage = 'Excel report exported: ${file.path}';
      if (automaticExportService != null) {
        await automaticExportService!.recordManualExport(isBackup: false, file: file);
        await loadAutoExportConfig();
      }
      if (notify) {
        final notif = notificationService ?? NotificationService();
        await notif.showExportNotification(
          title: "Kal's Money Manager",
          body: 'Excel export completed: ${file.path.split(Platform.pathSeparator).last} is saved.',
          isSuccess: true,
          filePath: file.path,
        );
      }
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
