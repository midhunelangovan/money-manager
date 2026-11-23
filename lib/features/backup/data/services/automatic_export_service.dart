import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utilities/app_logger.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/storage_helper.dart';
import 'auto_export_background_scheduler.dart';
import 'backup_service.dart';
import 'excel_export_service.dart';

enum AutoExportFrequency {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  final String displayName;
  const AutoExportFrequency(this.displayName);
}

enum AutoExportFormat {
  excel('Excel Workbook (.xlsx)'),
  backup('Full Backup (.mmb)');

  final String displayName;
  const AutoExportFormat(this.displayName);
}

enum AutoExportScope {
  allTransactions('All history'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  last90Days('Last 90 days'),
  lastYear('Last year'),
  currentMonth('Current Month');

  final String displayName;
  const AutoExportScope(this.displayName);
}

class AutoExportConfig {
  final bool isEnabled;
  final AutoExportFrequency frequency;
  final TimeOfDay preferredTime;
  final int dayOfWeek; // 1 = Mon, 7 = Sun
  final int dayOfMonth; // 1 - 31
  final AutoExportFormat format;
  final AutoExportScope scope;
  final int retentionCount; // 5, 10, 30
  final bool notifyOnComplete;
  final DateTime? enabledAt;

  final DateTime? lastRunTime;
  final DateTime? lastSuccessTime;
  final String? lastRunStatus; // 'Completed', 'Failed', 'Running', 'Awaiting Android background execution'
  final String? lastFilePath;
  final int? lastFileSize;
  final String? lastError;
  final String? lastJobId;
  final DateTime? nextScheduledRun;

  final DateTime? lastBackupTime;
  final String? lastBackupPath;
  final int? lastBackupSize;

  final DateTime? lastExcelTime;
  final String? lastExcelPath;
  final int? lastExcelSize;

  const AutoExportConfig({
    this.isEnabled = false,
    this.frequency = AutoExportFrequency.daily,
    this.preferredTime = const TimeOfDay(hour: 20, minute: 0),
    this.dayOfWeek = DateTime.sunday,
    this.dayOfMonth = 1,
    this.format = AutoExportFormat.excel,
    this.scope = AutoExportScope.allTransactions,
    this.retentionCount = 10,
    this.notifyOnComplete = true,
    this.enabledAt,
    this.lastRunTime,
    this.lastSuccessTime,
    this.lastRunStatus,
    this.lastFilePath,
    this.lastFileSize,
    this.lastError,
    this.lastJobId,
    this.nextScheduledRun,
    this.lastBackupTime,
    this.lastBackupPath,
    this.lastBackupSize,
    this.lastExcelTime,
    this.lastExcelPath,
    this.lastExcelSize,
  });

  /// True if the last run was verified and completed successfully
  bool get isLastRunSuccess => lastRunStatus == 'Completed' || lastRunStatus == 'success';

  /// Accurate, consistent status terminology for UI and diagnostics
  String get statusDisplay {
    if (!isEnabled) return 'Disabled';
    if (lastRunStatus == 'Running') return 'Running';
    if (lastRunStatus == 'Completed' || lastRunStatus == 'success') return 'Completed';
    if (lastRunStatus == 'Failed' || lastRunStatus == 'failed') return 'Failed';
    return 'Awaiting Android background execution';
  }

  AutoExportConfig copyWith({
    bool? isEnabled,
    AutoExportFrequency? frequency,
    TimeOfDay? preferredTime,
    int? dayOfWeek,
    int? dayOfMonth,
    AutoExportFormat? format,
    AutoExportScope? scope,
    int? retentionCount,
    bool? notifyOnComplete,
    DateTime? enabledAt,
    DateTime? lastRunTime,
    DateTime? lastSuccessTime,
    String? lastRunStatus,
    String? lastFilePath,
    int? lastFileSize,
    String? lastError,
    String? lastJobId,
    DateTime? nextScheduledRun,
    DateTime? lastBackupTime,
    String? lastBackupPath,
    int? lastBackupSize,
    DateTime? lastExcelTime,
    String? lastExcelPath,
    int? lastExcelSize,
  }) {
    return AutoExportConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      frequency: frequency ?? this.frequency,
      preferredTime: preferredTime ?? this.preferredTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      format: format ?? this.format,
      scope: scope ?? this.scope,
      retentionCount: retentionCount ?? this.retentionCount,
      notifyOnComplete: notifyOnComplete ?? this.notifyOnComplete,
      enabledAt: enabledAt ?? this.enabledAt,
      lastRunTime: lastRunTime ?? this.lastRunTime,
      lastSuccessTime: lastSuccessTime ?? this.lastSuccessTime,
      lastRunStatus: lastRunStatus ?? this.lastRunStatus,
      lastFilePath: lastFilePath ?? this.lastFilePath,
      lastFileSize: lastFileSize ?? this.lastFileSize,
      lastError: lastError ?? this.lastError,
      lastJobId: lastJobId ?? this.lastJobId,
      nextScheduledRun: nextScheduledRun ?? this.nextScheduledRun,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupPath: lastBackupPath ?? this.lastBackupPath,
      lastBackupSize: lastBackupSize ?? this.lastBackupSize,
      lastExcelTime: lastExcelTime ?? this.lastExcelTime,
      lastExcelPath: lastExcelPath ?? this.lastExcelPath,
      lastExcelSize: lastExcelSize ?? this.lastExcelSize,
    );
  }
}

class AutoExportResult {
  final bool success;
  final File? file;
  final String? errorMessage;
  final DateTime timestamp;
  final int? fileSize;
  final bool isSkipped;

  const AutoExportResult({
    required this.success,
    this.file,
    this.errorMessage,
    required this.timestamp,
    this.fileSize,
    this.isSkipped = false,
  });
}

class AutomaticExportService {
  final AppDatabase appDatabase;
  final BackupService backupService;
  final ExcelExportService excelExportService;
  final NotificationService notificationService;

  static bool _isExecuting = false;

  AutomaticExportService({
    AppDatabase? database,
    required this.backupService,
    required this.excelExportService,
    NotificationService? notificationSvc,
  })  : appDatabase = database ?? AppDatabase.instance,
        notificationService = notificationSvc ?? NotificationService();

  Future<AutoExportConfig> loadConfig() async {
    final db = appDatabase;
    final isEnabled = (await db.getSetting('auto_export_enabled')) == 'true';
    final freqStr = await db.getSetting('auto_export_frequency');
    final frequency = AutoExportFrequency.values.firstWhere(
      (f) => f.name == freqStr,
      orElse: () => AutoExportFrequency.daily,
    );

    final timeStr = await db.getSetting('auto_export_time') ?? '20:00';
    final timeParts = timeStr.split(':');
    final preferredTime = TimeOfDay(
      hour: int.tryParse(timeParts.first) ?? 20,
      minute: timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0,
    );

    final dayOfWeek = int.tryParse(await db.getSetting('auto_export_day_of_week') ?? '') ?? DateTime.sunday;
    final dayOfMonth = int.tryParse(await db.getSetting('auto_export_day_of_month') ?? '') ?? 1;

    final formatStr = await db.getSetting('auto_export_format');
    final format = AutoExportFormat.values.firstWhere(
      (f) => f.name == formatStr,
      orElse: () => AutoExportFormat.excel,
    );

    final scopeStr = await db.getSetting('auto_export_scope');
    final scope = AutoExportScope.values.firstWhere(
      (s) => s.name == scopeStr,
      orElse: () => AutoExportScope.allTransactions,
    );

    final retention = int.tryParse(await db.getSetting('auto_export_retention') ?? '') ?? 10;
    final notify = (await db.getSetting('auto_export_notifications')) != 'false';

    final enabledAtStr = await db.getSetting('auto_export_enabled_at');
    final enabledAt = enabledAtStr != null ? DateTime.tryParse(enabledAtStr) : null;

    final lastRunStr = await db.getSetting('auto_export_last_run');
    final lastRunTime = lastRunStr != null ? DateTime.tryParse(lastRunStr) : null;
    final lastSuccessStr = await db.getSetting('auto_export_last_success');
    final lastSuccessTime = lastSuccessStr != null ? DateTime.tryParse(lastSuccessStr) : null;
    final lastStatus = await db.getSetting('auto_export_last_status');
    final lastPath = await db.getSetting('auto_export_last_file_path');
    final lastSize = int.tryParse(await db.getSetting('auto_export_last_file_size') ?? '');
    final lastErr = await db.getSetting('auto_export_last_error');
    final lastJobId = await db.getSetting('auto_export_last_job_id');
    final nextScheduledStr = await db.getSetting('auto_export_next_scheduled');
    final nextScheduledRun = nextScheduledStr != null ? DateTime.tryParse(nextScheduledStr) : null;

    final lastBackupStr = await db.getSetting('health_last_backup_time');
    final lastBackupTime = lastBackupStr != null ? DateTime.tryParse(lastBackupStr) : null;
    final lastBackupPath = await db.getSetting('health_last_backup_path');
    final lastBackupSize = int.tryParse(await db.getSetting('health_last_backup_size') ?? '');

    final lastExcelStr = await db.getSetting('health_last_excel_time');
    final lastExcelTime = lastExcelStr != null ? DateTime.tryParse(lastExcelStr) : null;
    final lastExcelPath = await db.getSetting('health_last_excel_path');
    final lastExcelSize = int.tryParse(await db.getSetting('health_last_excel_size') ?? '');

    return AutoExportConfig(
      isEnabled: isEnabled,
      frequency: frequency,
      preferredTime: preferredTime,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      format: format,
      scope: scope,
      retentionCount: retention,
      notifyOnComplete: notify,
      enabledAt: enabledAt,
      lastRunTime: lastRunTime,
      lastSuccessTime: lastSuccessTime,
      lastRunStatus: lastStatus,
      lastFilePath: lastPath,
      lastFileSize: lastSize,
      lastError: lastErr,
      lastJobId: lastJobId,
      nextScheduledRun: nextScheduledRun,
      lastBackupTime: lastBackupTime,
      lastBackupPath: lastBackupPath,
      lastBackupSize: lastBackupSize,
      lastExcelTime: lastExcelTime,
      lastExcelPath: lastExcelPath,
      lastExcelSize: lastExcelSize,
    );
  }

  Future<void> saveConfig(AutoExportConfig config) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.log(
      'KALS_AUTO_EXPORT',
      'Stage 1 (Configuration): Saving configuration. Enabled=${config.isEnabled}, '
      'Frequency=${config.frequency.displayName}, Time=${config.preferredTime.hour.toString().padLeft(2, '0')}:${config.preferredTime.minute.toString().padLeft(2, '0')}, '
      'Scope=${config.scope.displayName}, Retention=${config.retentionCount}',
    );

    final db = appDatabase;
    await db.setSetting('auto_export_enabled', config.isEnabled.toString());
    await db.setSetting('auto_export_frequency', config.frequency.name);
    final timeStr = '${config.preferredTime.hour.toString().padLeft(2, '0')}:${config.preferredTime.minute.toString().padLeft(2, '0')}';
    await db.setSetting('auto_export_time', timeStr);
    await db.setSetting('auto_export_day_of_week', config.dayOfWeek.toString());
    await db.setSetting('auto_export_day_of_month', config.dayOfMonth.toString());
    await db.setSetting('auto_export_format', config.format.name);
    await db.setSetting('auto_export_scope', config.scope.name);
    await db.setSetting('auto_export_retention', config.retentionCount.toString());
    await db.setSetting('auto_export_notifications', config.notifyOnComplete.toString());

    if (config.lastRunTime != null) {
      await db.setSetting('auto_export_last_run', config.lastRunTime!.toIso8601String());
    }

    if (config.enabledAt != null) {
      await db.setSetting('auto_export_enabled_at', config.enabledAt!.toIso8601String());
    } else if (config.isEnabled) {
      final existingEnabledAt = await db.getSetting('auto_export_enabled_at');
      if (existingEnabledAt == null || existingEnabledAt.isEmpty) {
        await db.setSetting('auto_export_enabled_at', DateTime.now().toIso8601String());
      }
    } else {
      await db.setSetting('auto_export_enabled_at', '');
      await db.setSetting('auto_export_last_status', 'Disabled');
    }

    final nextRun = calculateNextRun(config);
    if (config.isEnabled) {
      await db.setSetting('auto_export_next_scheduled', nextRun.toIso8601String());
      final currentStatus = await db.getSetting('auto_export_last_status');
      if (currentStatus == null || currentStatus.isEmpty || currentStatus == 'Disabled') {
        await db.setSetting('auto_export_last_status', 'Awaiting Android background execution');
      }
    }

    // Sync Android WorkManager scheduling
    await AutoExportBackgroundScheduler.scheduleOrUpdate(
      config,
      nextRunTime: nextRun,
    );

    AppLogger.log(
      'KALS_AUTO_EXPORT',
      'Stage 1 (Configuration): Completed in ${stopwatch.elapsedMilliseconds}ms. Next expected run: $nextRun',
    );
  }

  Future<void> recordManualExport({
    required bool isBackup,
    required File file,
  }) async {
    final db = appDatabase;
    final now = DateTime.now().toIso8601String();
    final size = await file.length();
    if (isBackup) {
      await db.setSetting('health_last_backup_time', now);
      await db.setSetting('health_last_backup_path', file.path);
      await db.setSetting('health_last_backup_size', size.toString());
    } else {
      await db.setSetting('health_last_excel_time', now);
      await db.setSetting('health_last_excel_path', file.path);
      await db.setSetting('health_last_excel_size', size.toString());
    }
  }

  /// Calculates the next scheduled execution time safely.
  /// Handles months with fewer days safely: e.g. schedule for 31st safely clamps to 28/29 in Feb, 30 in Apr/Jun/Sep/Nov.
  DateTime calculateNextRun(AutoExportConfig config, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final targetHour = config.preferredTime.hour;
    final targetMinute = config.preferredTime.minute;

    switch (config.frequency) {
      case AutoExportFrequency.daily:
        var candidate = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;

      case AutoExportFrequency.weekly:
        var candidate = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
        int daysUntilTarget = (config.dayOfWeek - candidate.weekday) % 7;
        if (daysUntilTarget < 0) daysUntilTarget += 7;
        candidate = candidate.add(Duration(days: daysUntilTarget));
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;

      case AutoExportFrequency.monthly:
        int year = now.year;
        int month = now.month;

        DateTime getClampedDate(int y, int m, int preferredDay) {
          final daysInMonth = DateUtils.getDaysInMonth(y, m);
          final clampedDay = preferredDay > daysInMonth ? daysInMonth : preferredDay;
          return DateTime(y, m, clampedDay, targetHour, targetMinute);
        }

        var candidate = getClampedDate(year, month, config.dayOfMonth);
        if (!candidate.isAfter(now)) {
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
          candidate = getClampedDate(year, month, config.dayOfMonth);
        }
        return candidate;
    }
  }

  /// Calculates the most recent scheduled execution time that was due on or before [from].
  DateTime calculateMostRecentDueTime(AutoExportConfig config, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final targetHour = config.preferredTime.hour;
    final targetMinute = config.preferredTime.minute;

    switch (config.frequency) {
      case AutoExportFrequency.daily:
        final scheduledToday = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
        if (!now.isBefore(scheduledToday)) {
          return scheduledToday;
        } else {
          return scheduledToday.subtract(const Duration(days: 1));
        }

      case AutoExportFrequency.weekly:
        final scheduledToday = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
        int daysBack = (now.weekday - config.dayOfWeek) % 7;
        if (daysBack < 0) daysBack += 7;
        var candidate = scheduledToday.subtract(Duration(days: daysBack));
        if (candidate.isAfter(now)) {
          candidate = candidate.subtract(const Duration(days: 7));
        }
        return candidate;

      case AutoExportFrequency.monthly:
        final daysThisMonth = DateUtils.getDaysInMonth(now.year, now.month);
        final clampedDayThisMonth = config.dayOfMonth > daysThisMonth ? daysThisMonth : config.dayOfMonth;
        final candidateThisMonth = DateTime(now.year, now.month, clampedDayThisMonth, targetHour, targetMinute);

        if (!candidateThisMonth.isAfter(now)) {
          return candidateThisMonth;
        } else {
          int prevYear = now.year;
          int prevMonth = now.month - 1;
          if (prevMonth < 1) {
            prevMonth = 12;
            prevYear--;
          }
          final daysPrevMonth = DateUtils.getDaysInMonth(prevYear, prevMonth);
          final clampedDayPrevMonth = config.dayOfMonth > daysPrevMonth ? daysPrevMonth : config.dayOfMonth;
          return DateTime(prevYear, prevMonth, clampedDayPrevMonth, targetHour, targetMinute);
        }
    }
  }

  /// Checks if scheduled export is due or was missed, and executes it idempotently without duplicates.
  /// [isBackgroundWorker]: set to true when called directly by the WorkManager worker callback.
  Future<AutoExportResult?> checkAndRunIfDue({
    DateTime? currentTime,
    bool isBackgroundWorker = false,
  }) async {
    final config = await loadConfig();
    if (!config.isEnabled) {
      AppLogger.log('KALS_AUTO_EXPORT', 'checkAndRunIfDue: Auto export is disabled. Skipping.');
      return null;
    }

    final now = currentTime ?? DateTime.now();

    // 1. Deduplication Guard: Check if export has already completed for this period
    if (config.lastRunTime != null && (config.lastRunStatus == 'Completed' || config.lastRunStatus == 'success')) {
      final lastRun = config.lastRunTime!;
      switch (config.frequency) {
        case AutoExportFrequency.daily:
          if (lastRun.year == now.year && lastRun.month == now.month && lastRun.day == now.day) {
            AppLogger.log('KALS_AUTO_EXPORT', 'checkAndRunIfDue: Already completed today at $lastRun. Skipping duplicate.');
            return null;
          }
          break;
        case AutoExportFrequency.weekly:
          final diffDays = now.difference(lastRun).inDays;
          if (diffDays < 6) {
            AppLogger.log('KALS_AUTO_EXPORT', 'checkAndRunIfDue: Already completed this week at $lastRun. Skipping duplicate.');
            return null;
          }
          break;
        case AutoExportFrequency.monthly:
          if (lastRun.year == now.year && lastRun.month == now.month) {
            AppLogger.log('KALS_AUTO_EXPORT', 'checkAndRunIfDue: Already completed this month at $lastRun. Skipping duplicate.');
            return null;
          }
          break;
      }
    }

    // 2. Schedule Due Verification
    if (isBackgroundWorker) {
      // The background worker was triggered specifically for this scheduled cycle.
      AppLogger.log('KALS_AUTO_EXPORT', 'Stage 3 (Background Execution): Worker triggered for ${config.frequency.displayName} export. Executing...');
      return executeExport(customConfig: config, isManual: false);
    }

    // Foreground / App Startup Catch-Up Check:
    final mostRecentDue = calculateMostRecentDueTime(config, from: now);

    if (config.lastRunTime == null) {
      if (config.enabledAt != null && config.enabledAt!.isAfter(mostRecentDue)) {
        AppLogger.log('KALS_AUTO_EXPORT', 'checkAndRunIfDue: Schedule enabled at ${config.enabledAt} after mostRecentDue $mostRecentDue. Waiting for next cycle.');
        return null;
      }
    } else {
      final lastRun = config.lastRunTime!;
      if (!lastRun.isBefore(mostRecentDue)) {
        AppLogger.log('KALS_AUTO_EXPORT', 'checkAndRunIfDue: Last run ($lastRun) was at or after mostRecentDue ($mostRecentDue). Up to date.');
        return null;
      }
    }

    AppLogger.log('KALS_AUTO_EXPORT', 'checkAndRunIfDue: Catch-up export triggered for missed schedule at $mostRecentDue (current: $now).');
    return executeExport(customConfig: config, isManual: false);
  }

  /// Reconciles scheduler state on application startup and executes catch-up if a scheduled run was missed.
  Future<bool> reconcileAndCatchUpIfDue() async {
    try {
      final config = await loadConfig();
      if (!config.isEnabled) return false;

      AppLogger.log('KALS_AUTO_EXPORT', 'Startup: Reconciling auto export scheduler state...');
      final runResult = await checkAndRunIfDue();

      final nextRun = calculateNextRun(config);
      await AutoExportBackgroundScheduler.scheduleOrUpdate(
        config,
        nextRunTime: nextRun,
      );
      return runResult != null && runResult.success;
    } catch (e, stack) {
      AppLogger.error('KALS_AUTO_EXPORT', 'Startup reconciliation error: $e', e, stack);
      return false;
    }
  }

  /// Executes export with complete validation, atomic finalization, and notifications.
  Future<AutoExportResult> executeExport({
    AutoExportConfig? customConfig,
    bool isManual = false,
  }) async {
    if (_isExecuting) {
      AppLogger.log('KALS_AUTO_EXPORT', 'executeExport: Export already in progress. Skipping concurrent request.');
      return AutoExportResult(
        success: false,
        errorMessage: 'Export job already in progress.',
        timestamp: DateTime.now(),
        isSkipped: true,
      );
    }

    _isExecuting = true;
    final stopwatch = Stopwatch()..start();
    final config = customConfig ?? await loadConfig();
    final now = DateTime.now();
    final db = appDatabase;

    try {
      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 4 (Export): Starting ${isManual ? "manual" : "automatic"} export. '
        'Format: ${config.format.displayName}, Scope: ${config.scope.displayName}, '
        'Retention: ${config.retentionCount}',
      );

      await db.setSetting('auto_export_last_status', 'Running');

      final exportDir = await StorageHelper.getDownloadsDirectory();
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final dateStr = DateFormatter.formatIso(now);
      File finalFile;

      if (config.format == AutoExportFormat.excel) {
        // Scope determination
        DateTime? startDate;
        DateTime? endDate = now;
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        switch (config.scope) {
          case AutoExportScope.last7Days:
            startDate = todayStart.subtract(const Duration(days: 7));
            endDate = todayEnd;
            break;
          case AutoExportScope.last30Days:
            startDate = todayStart.subtract(const Duration(days: 30));
            endDate = todayEnd;
            break;
          case AutoExportScope.last90Days:
            startDate = todayStart.subtract(const Duration(days: 90));
            endDate = todayEnd;
            break;
          case AutoExportScope.lastYear:
            startDate = DateTime(now.year - 1, now.month, now.day);
            endDate = todayEnd;
            break;
          case AutoExportScope.currentMonth:
            startDate = DateTime(now.year, now.month, 1);
            endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
            break;
          case AutoExportScope.allTransactions:
            startDate = null;
            endDate = null;
            break;
        }

        // Generate workbook directly via ExcelExportService (saves to public Downloads)
        final baseName = 'Kals_MoneyManager_Export_$dateStr.xlsx';
        AppLogger.log('KALS_AUTO_EXPORT', 'Stage 4 (Export): Generating Excel workbook "$baseName"...');
        final excelFile = await excelExportService.generateExcelWorkbook(
          filter: ExcelExportFilter(
            startDate: startDate,
            endDate: endDate,
            customFileName: baseName,
          ),
        );

        // Validation 1: Exists and non-empty
        if (!await StorageHelper.verifyFileExistsAndNonEmpty(excelFile)) {
          throw Exception('Excel export generated an empty file');
        }

        // Validation 2: Parse and verify Excel bytes
        final bytes = await excelFile.readAsBytes();
        final decoded = Excel.decodeBytes(bytes);
        if (decoded.sheets.isEmpty || !decoded.sheets.containsKey('Summary')) {
          throw Exception('Excel workbook validation failed: corrupt sheets');
        }

        finalFile = excelFile;
      } else {
        // Complete Application Backup
        AppLogger.log('KALS_AUTO_EXPORT', 'Stage 4 (Export): Generating full JSON backup payload...');
        final payload = await backupService.createBackupPayload();
        final jsonStr = const JsonEncoder.withIndent('  ').convert(payload.toMap());

        // Validate payload content in memory
        backupService.validateBackupData(jsonStr);

        final baseName = 'Kals_MoneyManager_Backup_$dateStr${AppConstants.backupFileExtension}';
        final backupFile = await StorageHelper.saveToPublicDownloads(
          bytes: utf8.encode(jsonStr),
          fileName: baseName,
          mimeType: 'application/octet-stream',
        );

        // Validation: Verify on disk
        if (!await StorageHelper.verifyFileExistsAndNonEmpty(backupFile)) {
          throw Exception('Backup archive verification failed on storage');
        }

        finalFile = backupFile;
      }

      final fileSize = await finalFile.length();
      final finalFileName = p.basename(finalFile.path);

      AppLogger.log('KALS_AUTO_EXPORT', 'Stage 4 (Export): File generated and verified successfully: ${finalFile.path} ($fileSize bytes)');

      // Prune old exports according to retention policy
      await _pruneOldExports(
        directory: exportDir,
        prefix: config.format == AutoExportFormat.excel ? 'Kals_MoneyManager_Export_' : 'Kals_MoneyManager_Backup_',
        extension: config.format == AutoExportFormat.excel ? '.xlsx' : AppConstants.backupFileExtension,
        maxRetained: config.retentionCount,
      );

      // Update metadata in database
      final nowIso = now.toIso8601String();
      await db.setSetting('auto_export_last_run', nowIso);
      await db.setSetting('auto_export_last_success', nowIso);
      await db.setSetting('auto_export_last_status', 'success');
      await db.setSetting('auto_export_last_file_path', finalFile.path);
      await db.setSetting('auto_export_last_file_size', fileSize.toString());
      await db.setSetting('auto_export_last_error', '');

      if (config.format == AutoExportFormat.backup) {
        await db.setSetting('health_last_backup_time', nowIso);
        await db.setSetting('health_last_backup_path', finalFile.path);
        await db.setSetting('health_last_backup_size', fileSize.toString());
      } else {
        await db.setSetting('health_last_excel_time', nowIso);
        await db.setSetting('health_last_excel_path', finalFile.path);
        await db.setSetting('health_last_excel_size', fileSize.toString());
      }

      // Local completion notification
      if (config.notifyOnComplete) {
        const title = 'Kals Money Manager';
        final body = config.format == AutoExportFormat.excel
            ? 'Automatic export completed. Your Excel file is ready.'
            : 'Your local backup has been created successfully ($finalFileName).';

        try {
          await notificationService.showExportNotification(
            title: title,
            body: body,
            isSuccess: true,
            filePath: finalFile.path,
          );
        } catch (ne) {
          AppLogger.warn('KALS_AUTO_EXPORT', 'Notification display warning: $ne');
        }
      }

      // Schedule next execution cycle
      if (config.isEnabled && !isManual) {
        final nextRun = calculateNextRun(config);
        await AutoExportBackgroundScheduler.scheduleOrUpdate(
          config,
          nextRunTime: nextRun,
        );
      }

      final durationMs = stopwatch.elapsedMilliseconds;
      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 5 (Completion): Export finished successfully in ${durationMs}ms. File: ${finalFile.path}',
      );

      return AutoExportResult(
        success: true,
        file: finalFile,
        timestamp: now,
        fileSize: fileSize,
      );
    } catch (e, stack) {
      final durationMs = stopwatch.elapsedMilliseconds;
      final errorMsg = e.toString();
      AppLogger.error('KALS_AUTO_EXPORT', 'Stage 4/5 (Export): Failed after ${durationMs}ms: $errorMsg', e, stack);

      await db.setSetting('auto_export_last_run', now.toIso8601String());
      await db.setSetting('auto_export_last_status', 'Failed');
      await db.setSetting('auto_export_last_error', errorMsg);

      if (config.notifyOnComplete) {
        try {
          await notificationService.showExportNotification(
            title: 'Kals Money Manager',
            body: 'Automatic export failed: $errorMsg',
            isSuccess: false,
          );
        } catch (_) {}
      }

      return AutoExportResult(
        success: false,
        errorMessage: errorMsg,
        timestamp: now,
      );
    } finally {
      _isExecuting = false;
    }
  }

  /// Prunes older automatic exports while safeguarding against data loss.
  /// Rule: Never delete if only one backup file exists!
  Future<void> _pruneOldExports({
    required Directory directory,
    required String prefix,
    required String extension,
    required int maxRetained,
  }) async {
    try {
      final list = await directory.list().toList();
      final matchingFiles = <File>[];

      final legacyPrefix = prefix.replaceFirst('Kals_', 'Kals_V2_');
      for (final entity in list) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if ((name.startsWith(prefix) || name.startsWith(legacyPrefix)) && name.endsWith(extension)) {
            matchingFiles.add(entity);
          }
        }
      }

      if (matchingFiles.length <= maxRetained || matchingFiles.length <= 1) {
        return;
      }

      // Sort oldest first
      matchingFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      final filesToDeleteCount = matchingFiles.length - maxRetained;
      for (int i = 0; i < filesToDeleteCount; i++) {
        // Never delete if this would delete the only file
        if (matchingFiles.length - i <= 1) break;
        try {
          await matchingFiles[i].delete();
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AutomaticExportService: Prune error: $e');
      }
    }
  }
}
