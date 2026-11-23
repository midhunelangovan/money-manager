import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utilities/app_logger.dart';
import '../../../accounts/data/repositories/account_repository_impl.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../recurring/data/repositories/recurring_repository_impl.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transfers/data/repositories/transfer_repository_impl.dart';
import 'automatic_export_service.dart';
import 'backup_service.dart';
import 'excel_export_service.dart';

const String kAutoExportTaskName = 'kals_auto_export_task';
const String kAutoExportUniqueWorkName = 'kals_automatic_export_work';

/// Top-level callback dispatcher for Android WorkManager.
/// Executes the automatic export in the background without launching the Flutter UI.
@pragma('vm:entry-point')
void autoExportCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.log(
      'KALS_AUTO_EXPORT',
      'Stage 3 (Background Worker): Android WorkManager worker triggered for task: $taskName',
    );

    try {
      WidgetsFlutterBinding.ensureInitialized();
      AppDatabase.initializeFfiIfRequired();
      await NotificationService().initialize();

      final db = AppDatabase.instance;
      final accountRepo = AccountRepositoryImpl(database: db);
      final categoryRepo = CategoryRepositoryImpl(database: db);
      final txRepo = TransactionRepositoryImpl(database: db);
      final transferRepo = TransferRepositoryImpl(database: db);
      final recurringRepo = RecurringRepositoryImpl(database: db);
      final backupService = BackupService(database: db);
      final excelExportService = ExcelExportService(
        accountRepository: accountRepo,
        categoryRepository: categoryRepo,
        transactionRepository: txRepo,
        transferRepository: transferRepo,
        recurringRepository: recurringRepo,
      );

      final autoExportService = AutomaticExportService(
        database: db,
        backupService: backupService,
        excelExportService: excelExportService,
      );

      // Perform export if due, explicitly marking as background worker to prevent clock jitter rejections
      final exportTriggered = await autoExportService.checkAndRunIfDue(isBackgroundWorker: true);

      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 3 (Background Worker): checkAndRunIfDue completed in ${stopwatch.elapsedMilliseconds}ms. '
        'Export executed: $exportTriggered',
      );

      // Reschedule next execution cycle
      final config = await autoExportService.loadConfig();
      if (config.isEnabled) {
        final nextRun = autoExportService.calculateNextRun(config);
        await AutoExportBackgroundScheduler.scheduleOrUpdate(
          config,
          nextRunTime: nextRun,
        );
      }

      return Future.value(true);
    } catch (e, stack) {
      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 3 (Background Worker): Task execution failed: $e\n$stack',
      );
      if (kDebugMode) {
        debugPrint('AutoExport WorkManager background task error: $e');
      }
      return Future.value(false);
    }
  });
}

/// Coordinates Android WorkManager registration for Automatic Export.
class AutoExportBackgroundScheduler {
  static bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  /// Initializes the WorkManager plugin on Android.
  static Future<void> initialize() async {
    if (!isSupportedPlatform) return;
    try {
      await Workmanager().initialize(
        autoExportCallbackDispatcher,
      );
      AppLogger.log('KALS_AUTO_EXPORT', 'Stage 2 (Scheduling): WorkManager initialized successfully');
    } catch (e) {
      AppLogger.log('KALS_AUTO_EXPORT', 'Stage 2 (Scheduling): WorkManager initialization failed: $e');
      if (kDebugMode) {
        debugPrint('AutoExportBackgroundScheduler.initialize error: $e');
      }
    }
  }

  /// Schedules or updates the scheduled WorkManager task.
  /// Cancels existing work if disabled, avoiding duplicates.
  static Future<void> scheduleOrUpdate(
    AutoExportConfig config, {
    DateTime? nextRunTime,
  }) async {
    if (!isSupportedPlatform) return;

    try {
      if (!config.isEnabled) {
        AppLogger.log(
          'KALS_AUTO_EXPORT',
          'Stage 2 (Scheduling): Export disabled, cancelling WorkManager task: $kAutoExportUniqueWorkName',
        );
        await cancel();
        return;
      }

      final now = DateTime.now();
      final target = nextRunTime ?? _calculateNextRunFallback(config, from: now);
      var delay = target.difference(now);
      if (delay.isNegative || delay.inSeconds < 10) {
        delay = const Duration(seconds: 10);
      }

      Duration frequencyDuration;
      switch (config.frequency) {
        case AutoExportFrequency.daily:
          frequencyDuration = const Duration(days: 1);
          break;
        case AutoExportFrequency.weekly:
          frequencyDuration = const Duration(days: 7);
          break;
        case AutoExportFrequency.monthly:
          // Daily check interval to safely handle month-end clamp and leap years
          frequencyDuration = const Duration(days: 1);
          break;
      }

      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 2 (Scheduling): Registering periodic WorkManager task. '
        'JobId=$kAutoExportUniqueWorkName, Delay=${delay.inMinutes}m (${delay.inSeconds}s), '
        'Frequency=${frequencyDuration.inHours}h, Target=$target',
      );

      // Persist job ID and scheduled timestamp in DB
      try {
        await AppDatabase.instance.setSetting('auto_export_last_job_id', kAutoExportUniqueWorkName);
        await AppDatabase.instance.setSetting('auto_export_next_scheduled', target.toIso8601String());
      } catch (_) {}

      // ExistingPeriodicWorkPolicy.update replaces previous schedule seamlessly
      await Workmanager().registerPeriodicTask(
        kAutoExportUniqueWorkName,
        kAutoExportTaskName,
        frequency: frequencyDuration,
        initialDelay: delay,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 2 (Scheduling): WorkManager task successfully registered with policy=update',
      );
    } catch (e, stack) {
      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 2 (Scheduling): Failed to register WorkManager task: $e\n$stack',
      );
      if (kDebugMode) {
        debugPrint('AutoExportBackgroundScheduler.scheduleOrUpdate error: $e');
      }
    }
  }

  /// Cancels the scheduled WorkManager job.
  static Future<void> cancel() async {
    if (!isSupportedPlatform) return;
    try {
      await Workmanager().cancelByUniqueName(kAutoExportUniqueWorkName);
      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 2 (Scheduling): Successfully cancelled WorkManager task: $kAutoExportUniqueWorkName',
      );
      try {
        await AppDatabase.instance.setSetting('auto_export_last_job_id', '');
        await AppDatabase.instance.setSetting('auto_export_last_status', 'Disabled');
      } catch (_) {}
    } catch (e) {
      AppLogger.log(
        'KALS_AUTO_EXPORT',
        'Stage 2 (Scheduling): Failed to cancel WorkManager task: $e',
      );
      if (kDebugMode) {
        debugPrint('AutoExportBackgroundScheduler.cancel error: $e');
      }
    }
  }

  static DateTime _calculateNextRunFallback(AutoExportConfig config, {DateTime? from}) {
    final now = from ?? DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, config.preferredTime.hour, config.preferredTime.minute);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
