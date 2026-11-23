import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/constants/app_constants.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/backup/data/services/automatic_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/backup_service.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_export_service.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late AppDatabase appDb;
  late AutomaticExportService exportService;
  late BackupService backupService;
  late ExcelExportService excelService;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auto_export_test_');
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

    final accountRepo = AccountRepositoryImpl(database: appDb);
    final categoryRepo = CategoryRepositoryImpl(database: appDb);
    final txRepo = TransactionRepositoryImpl(database: appDb);
    final transferRepo = TransferRepositoryImpl(database: appDb);
    final recurringRepo = RecurringRepositoryImpl(database: appDb);

    backupService = BackupService(database: appDb);
    excelService = ExcelExportService(
      accountRepository: accountRepo,
      categoryRepository: categoryRepo,
      transactionRepository: txRepo,
      transferRepository: transferRepo,
      recurringRepository: recurringRepo,
    );

    exportService = AutomaticExportService(
      database: appDb,
      backupService: backupService,
      excelExportService: excelService,
    );
  });

  tearDown(() async {
    await db.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Automatic Export Scheduling & Calendar Edge Cases Tests', () {
    test('Daily schedule: returns today if before preferred time, tomorrow if after', () {
      final config = const AutoExportConfig(
        frequency: AutoExportFrequency.daily,
        preferredTime: TimeOfDay(hour: 20, minute: 0),
      );

      final beforeTime = DateTime(2026, 11, 1, 14, 0);
      final nextRunBefore = exportService.calculateNextRun(config, from: beforeTime);
      expect(nextRunBefore, equals(DateTime(2026, 11, 1, 20, 0)));

      final afterTime = DateTime(2026, 11, 1, 21, 30);
      final nextRunAfter = exportService.calculateNextRun(config, from: afterTime);
      expect(nextRunAfter, equals(DateTime(2026, 11, 2, 20, 0)));
    });

    test('Weekly schedule: accurately calculates target day of the week', () {
      // 2026-11-01 is Sunday (weekday 7)
      final sunday = DateTime(2026, 11, 1, 10, 0);
      expect(sunday.weekday, equals(DateTime.sunday));

      // Schedule for Wednesday (weekday 3)
      final configWed = const AutoExportConfig(
        frequency: AutoExportFrequency.weekly,
        dayOfWeek: DateTime.wednesday,
        preferredTime: TimeOfDay(hour: 18, minute: 0),
      );

      final nextWed = exportService.calculateNextRun(configWed, from: sunday);
      expect(nextWed.weekday, equals(DateTime.wednesday));
      expect(nextWed, equals(DateTime(2026, 11, 4, 18, 0)));
    });

    test('Monthly schedule: safely clamps 31st to 28th/29th in February and 30th in April', () {
      final configDay31 = const AutoExportConfig(
        frequency: AutoExportFrequency.monthly,
        dayOfMonth: 31,
        preferredTime: TimeOfDay(hour: 22, minute: 0),
      );

      // In February 2026 (non-leap year, 28 days)
      final feb1 = DateTime(2026, 2, 1, 9, 0);
      final nextFeb = exportService.calculateNextRun(configDay31, from: feb1);
      expect(nextFeb.year, equals(2026));
      expect(nextFeb.month, equals(2));
      expect(nextFeb.day, equals(28)); // Safely clamped!

      // In April 2026 (30 days)
      final apr1 = DateTime(2026, 4, 1, 9, 0);
      final nextApr = exportService.calculateNextRun(configDay31, from: apr1);
      expect(nextApr.year, equals(2026));
      expect(nextApr.month, equals(4));
      expect(nextApr.day, equals(30)); // Safely clamped!

      // In December 2026 (31 days)
      final dec1 = DateTime(2026, 12, 1, 9, 0);
      final nextDec = exportService.calculateNextRun(configDay31, from: dec1);
      expect(nextDec.year, equals(2026));
      expect(nextDec.month, equals(12));
      expect(nextDec.day, equals(31));
    });
  });

  group('Configuration Persistence & Health Recording Tests', () {
    test('saveConfig and loadConfig persist and restore settings cleanly', () async {
      final initial = await exportService.loadConfig();
      expect(initial.isEnabled, isFalse);

      final updated = const AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.weekly,
        preferredTime: TimeOfDay(hour: 19, minute: 45),
        dayOfWeek: DateTime.saturday,
        dayOfMonth: 15,
        format: AutoExportFormat.backup,
        scope: AutoExportScope.currentMonth,
        retentionCount: 30,
        notifyOnComplete: false,
      );

      await exportService.saveConfig(updated);
      final reloaded = await exportService.loadConfig();

      expect(reloaded.isEnabled, isTrue);
      expect(reloaded.frequency, equals(AutoExportFrequency.weekly));
      expect(reloaded.preferredTime.hour, equals(19));
      expect(reloaded.preferredTime.minute, equals(45));
      expect(reloaded.dayOfWeek, equals(DateTime.saturday));
      expect(reloaded.format, equals(AutoExportFormat.backup));
      expect(reloaded.scope, equals(AutoExportScope.currentMonth));
      expect(reloaded.retentionCount, equals(30));
      expect(reloaded.notifyOnComplete, isFalse);
    });

    test('Manual export recording saves health metadata correctly', () async {
      final tempDir = await Directory.systemTemp.createTemp('manual_export_test');
      final testFile = File('${tempDir.path}/test_backup.mmb');
      await testFile.writeAsString('{"test": true}');

      await exportService.recordManualExport(isBackup: true, file: testFile);
      final config = await exportService.loadConfig();

      expect(config.lastBackupTime, isNotNull);
      expect(config.lastBackupPath, equals(testFile.path));
      expect(config.lastBackupSize, greaterThan(0));

      await tempDir.delete(recursive: true);
    });
  });

  group('Export Execution & Validation Tests', () {
    test('executeExport generates valid, non-empty Excel workbook', () async {
      final result = await exportService.executeExport(
        customConfig: const AutoExportConfig(
          isEnabled: true,
          format: AutoExportFormat.excel,
          scope: AutoExportScope.allTransactions,
          notifyOnComplete: false,
        ),
        isManual: true,
      );

      expect(result.success, isTrue);
      expect(result.file, isNotNull);
      expect(await result.file!.exists(), isTrue);
      expect(await result.file!.length(), greaterThan(0));
      expect(result.file!.path.endsWith('.xlsx'), isTrue);

      // Verify health was updated in DB
      final config = await exportService.loadConfig();
      expect(config.lastExcelTime, isNotNull);
      expect(config.lastExcelPath, equals(result.file!.path));
      expect(config.lastRunStatus, equals('success'));
    });

    test('executeExport generates valid, parseable application backup (.mmb)', () async {
      final result = await exportService.executeExport(
        customConfig: const AutoExportConfig(
          isEnabled: true,
          format: AutoExportFormat.backup,
          notifyOnComplete: false,
        ),
        isManual: true,
      );

      expect(result.success, isTrue);
      expect(result.file, isNotNull);
      expect(await result.file!.exists(), isTrue);
      expect(await result.file!.length(), greaterThan(0));
      expect(result.file!.path.endsWith('.mmb'), isTrue);

      // Read and validate content
      final content = await result.file!.readAsString();
      final payload = backupService.validateBackupData(content);
      expect(payload.metadata.appVersion, equals(AppConstants.appVersion));
      expect(payload.metadata.checksum, isNotNull);
    });
  });
}
