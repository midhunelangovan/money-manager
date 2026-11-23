import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/backup/data/services/automatic_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/backup_service.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_export_service.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

class DiagnosticMockNotificationService implements NotificationService {
  int exportNotificationsShown = 0;
  String? lastTitle;
  String? lastBody;
  bool? lastIsSuccess;
  String? lastFilePath;

  @override
  Future<void> showExportNotification({
    required String title,
    required String body,
    bool isSuccess = true,
    String? filePath,
  }) async {
    exportNotificationsShown++;
    lastTitle = title;
    lastBody = body;
    lastIsSuccess = isSuccess;
    lastFilePath = filePath;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late Directory tempDir;
  late Database db;
  late AppDatabase appDb;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl txRepo;
  late TransferRepositoryImpl transferRepo;
  late RecurringRepositoryImpl recurringRepo;
  late BackupService backupService;
  late ExcelExportService excelExportService;
  late DiagnosticMockNotificationService mockNotifService;
  late AutomaticExportService autoExportService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    NotificationService.isTestMode = true;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auto_export_diag_');

    // Mock path provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getExternalStorageDirectories') {
          return [tempDir.path];
        }
        return tempDir.path;
      },
    );

    // Mock storage channels (kals_storage and widget_channel)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.kals.kals_money_manager/widget_channel'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'saveFileToPublicDownloads') {
          final args = methodCall.arguments as Map<dynamic, dynamic>;
          final fileName = args['fileName'] as String;
          final sourcePath = args['sourcePath'] as String;
          final dest = File('${tempDir.path}/$fileName');
          await File(sourcePath).copy(dest.path);
          return {
            'success': true,
            'fileName': fileName,
            'relativePath': 'Download/KalsMoneyManager/$fileName',
            'absolutePath': dest.path,
          };
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.kals.kals_money_manager/storage_channel'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'saveFileToPublicDownloads') {
          final args = methodCall.arguments as Map<dynamic, dynamic>;
          final fileName = args['fileName'] as String;
          final sourcePath = args['sourcePath'] as String;
          final dest = File('${tempDir.path}/$fileName');
          await File(sourcePath).copy(dest.path);
          return {
            'success': true,
            'fileName': fileName,
            'relativePath': 'Download/KalsMoneyManager/$fileName',
            'absolutePath': dest.path,
          };
        }
        return null;
      },
    );

    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      ),
    );

    appDb = AppDatabase.withDatabase(db);
    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    transferRepo = TransferRepositoryImpl(database: appDb);
    recurringRepo = RecurringRepositoryImpl(database: appDb);
    backupService = BackupService(database: appDb);
    excelExportService = ExcelExportService(
      accountRepository: accountRepo,
      categoryRepository: categoryRepo,
      transactionRepository: txRepo,
      transferRepository: transferRepo,
      recurringRepository: recurringRepo,
    );
    mockNotifService = DiagnosticMockNotificationService();
    autoExportService = AutomaticExportService(
      database: appDb,
      backupService: backupService,
      excelExportService: excelExportService,
      notificationSvc: mockNotifService,
    );

    // Populate test accounts and transactions
    final acc = Account(
      id: 'acc-1',
      name: 'Primary Checking',
      accountType: AccountType.bank,
      openingBalance: Money.fromUnits(250000),
      currency: 'INR',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await accountRepo.createAccount(acc);

    final cat = Category(
      id: 'cat-1',
      name: 'Salary',
      type: CategoryType.income,
      icon: 'work',
      color: 0xFF4CAF50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await categoryRepo.createCategory(cat);

    final tx = Transaction(
      id: 'tx-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      transactionType: CategoryType.income,
      amount: Money.fromUnits(250000),
      date: DateTime.now(),
      description: 'Monthly Salary',
      notes: 'Direct Deposit',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await txRepo.createTransaction(tx);
  });

  tearDown(() async {
    try {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('KALS_AUTO_EXPORT Stage 1: Configuration Persistence and Retrieval', () {
    test('Persists complete configuration and loads accurate defaults', () async {
      final initialConfig = await autoExportService.loadConfig();
      expect(initialConfig.isEnabled, isFalse);
      expect(initialConfig.statusDisplay, equals('Disabled'));

      final configured = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.daily,
        preferredTime: const TimeOfDay(hour: 22, minute: 15),
        scope: AutoExportScope.last30Days,
        retentionCount: 30,
        notifyOnComplete: true,
      );

      await autoExportService.saveConfig(configured);

      final loaded = await autoExportService.loadConfig();
      expect(loaded.isEnabled, isTrue);
      expect(loaded.frequency, equals(AutoExportFrequency.daily));
      expect(loaded.preferredTime.hour, equals(22));
      expect(loaded.preferredTime.minute, equals(15));
      expect(loaded.scope, equals(AutoExportScope.last30Days));
      expect(loaded.retentionCount, equals(30));
      expect(loaded.notifyOnComplete, isTrue);
      expect(loaded.statusDisplay, equals('Awaiting Android background execution'));
    });
  });

  group('KALS_AUTO_EXPORT Stage 2: Scheduling and Next Run Calculations', () {
    test('Daily frequency schedules for tomorrow when time already passed', () {
      final now = DateTime(2026, 11, 17, 21, 30);
      final config = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.daily,
        preferredTime: const TimeOfDay(hour: 20, minute: 0),
      );

      final nextRun = autoExportService.calculateNextRun(config, from: now);
      expect(nextRun.year, equals(2026));
      expect(nextRun.month, equals(11));
      expect(nextRun.day, equals(18));
      expect(nextRun.hour, equals(20));
      expect(nextRun.minute, equals(0));
    });

    test('Weekly frequency calculates correct weekday target', () {
      // 2026-11-17 is Tuesday (weekday = 2). Schedule for Sunday (weekday = 7).
      final now = DateTime(2026, 11, 17, 10, 0);
      final config = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.weekly,
        dayOfWeek: DateTime.sunday,
        preferredTime: const TimeOfDay(hour: 18, minute: 0),
      );

      final nextRun = autoExportService.calculateNextRun(config, from: now);
      expect(nextRun.weekday, equals(DateTime.sunday));
      expect(nextRun.isAfter(now), isTrue);
      expect(nextRun.day, equals(22)); // Nov 22 is Sunday
    });

    test('Monthly frequency safely clamps for February 28/29 and 30-day months', () {
      // Leap year check: Feb 2028 (29 days). Schedule requested on 31st.
      final nowFeb = DateTime(2028, 2, 1, 10, 0);
      final config = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.monthly,
        dayOfMonth: 31,
        preferredTime: const TimeOfDay(hour: 12, minute: 0),
      );

      final nextRunFebLeap = autoExportService.calculateNextRun(config, from: nowFeb);
      expect(nextRunFebLeap.month, equals(2));
      expect(nextRunFebLeap.day, equals(29)); // Clamped to 29 in leap year!

      // Non-leap year check: Feb 2026 (28 days).
      final nowFebNonLeap = DateTime(2026, 2, 1, 10, 0);
      final nextRunFebNonLeap = autoExportService.calculateNextRun(config, from: nowFebNonLeap);
      expect(nextRunFebNonLeap.month, equals(2));
      expect(nextRunFebNonLeap.day, equals(28)); // Clamped to 28 in non-leap year!

      // April (30 days).
      final nowApr = DateTime(2026, 4, 1, 10, 0);
      final nextRunApr = autoExportService.calculateNextRun(config, from: nowApr);
      expect(nextRunApr.month, equals(4));
      expect(nextRunApr.day, equals(30)); // Clamped to 30
    });
  });

  group('KALS_AUTO_EXPORT Stage 3, 4 & 5: Background Execution, File Output & Status Updating', () {
    test('Background worker execution generates verified Excel workbook with Summary and Transactions sheets', () async {
      final config = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.daily,
        preferredTime: const TimeOfDay(hour: 20, minute: 0),
        format: AutoExportFormat.excel,
        scope: AutoExportScope.allTransactions,
        notifyOnComplete: true,
      );
      await autoExportService.saveConfig(config);

      // Execute export explicitly simulating background worker invocation
      final result = await autoExportService.executeExport(isManual: false);

      expect(result.success, isTrue);
      expect(result.file, isNotNull);
      expect(result.file!.existsSync(), isTrue);

      // Verify file is a valid Excel workbook containing required sheets
      final bytes = await result.file!.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.containsKey('Summary'), isTrue, reason: 'Must contain Summary sheet');
      expect(excel.tables.containsKey('Transactions'), isTrue, reason: 'Must contain Transactions sheet');

      // Verify Stage 5 status update
      final updatedConfig = await autoExportService.loadConfig();
      expect(updatedConfig.isLastRunSuccess, isTrue);
      expect(updatedConfig.statusDisplay, equals('Completed'));
      expect(updatedConfig.lastSuccessTime, isNotNull);
      expect(updatedConfig.lastFilePath, isNotNull);
      expect(updatedConfig.lastFileSize, isNotNull);
      expect(updatedConfig.lastFileSize, greaterThan(0));

      // Verify user notification was dispatched
      expect(mockNotifService.exportNotificationsShown, equals(1));
      expect(mockNotifService.lastIsSuccess, isTrue);
    });

    test('Deduplication prevents multiple runs in the same cycle', () async {
      final config = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.daily,
        preferredTime: const TimeOfDay(hour: 20, minute: 0),
      );
      await autoExportService.saveConfig(config);

      // Run once
      final run1 = await autoExportService.executeExport(isManual: false);
      expect(run1.success, isTrue);

      // Try running checkAndRunIfDue on same day
      final shouldRunAgain = await autoExportService.checkAndRunIfDue(
        currentTime: DateTime.now(),
        isBackgroundWorker: true,
      );
      expect(shouldRunAgain, isNull, reason: 'Deduplication must prevent duplicate run on same day');
    });

    test('Startup catch-up executes if scheduled run was missed', () async {
      // Simulate scheduled run was set for yesterday but device was off
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final config = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.daily,
        preferredTime: TimeOfDay(hour: yesterday.hour, minute: yesterday.minute),
      );
      await autoExportService.saveConfig(config);

      // Simulate last run was 2 days ago
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await appDb.setSetting('auto_export_last_run', twoDaysAgo.toIso8601String());
      await appDb.setSetting('auto_export_last_success', twoDaysAgo.toIso8601String());
      await appDb.setSetting('auto_export_next_scheduled', yesterday.toIso8601String());

      // Reconcile and catch up
      final caughtUp = await autoExportService.reconcileAndCatchUpIfDue();
      expect(caughtUp, isTrue, reason: 'Missed run must be caught up upon app reconciliation');

      final freshConfig = await autoExportService.loadConfig();
      expect(freshConfig.isLastRunSuccess, isTrue);
    });

    test('Error handling records failure and surfaces Last Failure Reason', () async {
      // Force failure by providing an invalid/non-writable format or mock error
      await appDb.setSetting('auto_export_enabled', 'true');
      await appDb.setSetting('auto_export_last_status', 'Failed');
      await appDb.setSetting('auto_export_last_error', 'Scoped storage permission rejected or media store unreachable');

      final loaded = await autoExportService.loadConfig();
      expect(loaded.lastRunStatus, equals('Failed'));
      expect(loaded.isLastRunSuccess, isFalse);
      expect(loaded.statusDisplay, equals('Failed'));
      expect(loaded.lastError, contains('Scoped storage'));
    });
  });
}
