import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/navigation/navigation_service.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/utilities/storage_helper.dart';
import 'package:kals_money_manager/core/widgets/app_drawer.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/backup/data/services/automatic_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/backup_service.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/integrity_service.dart';
import 'package:kals_money_manager/features/backup/presentation/providers/backup_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/recurring/domain/services/recurring_processor.dart';
import 'package:kals_money_manager/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:kals_money_manager/features/reminders/data/repositories/reminder_repository.dart';
import 'package:kals_money_manager/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/presentation/providers/transfer_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

class MockNotificationService implements NotificationService {
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

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    NotificationService.isTestMode = true;
  });

  tearDownAll(() {
    AppDatabase.setTestInstance(null);
  });

  late Database db;
  late AppDatabase appDb;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl txRepo;
  late TransferRepositoryImpl transferRepo;
  late RecurringRepositoryImpl recurringRepo;
  late ReminderRepository reminderRepo;
  late BackupService backupService;
  late ExcelExportService excelExportService;
  late MockNotificationService mockNotifService;
  late AutomaticExportService autoExportService;
  late BackupProvider backupProvider;
  late AccountProvider accountProvider;
  late CategoryProvider categoryProvider;
  late TransactionProvider txProvider;
  late TransferProvider transferProvider;
  late RecurringProvider recurringProvider;
  late ReminderProvider reminderProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase3_test_');
    StorageHelper.customExportDirectory = tempDir.path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getExternalStorageDirectories') {
          return [tempDir.path];
        }
        return tempDir.path;
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
    AppDatabase.setTestInstance(appDb);

    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    transferRepo = TransferRepositoryImpl(database: appDb);
    recurringRepo = RecurringRepositoryImpl(database: appDb);
    reminderRepo = ReminderRepository(db: appDb);

    backupService = BackupService(database: appDb);
    final integrityService = IntegrityService(database: appDb);
    excelExportService = ExcelExportService(
      accountRepository: accountRepo,
      categoryRepository: categoryRepo,
      transactionRepository: txRepo,
      transferRepository: transferRepo,
      recurringRepository: recurringRepo,
    );
    mockNotifService = MockNotificationService();

    autoExportService = AutomaticExportService(
      database: appDb,
      backupService: backupService,
      excelExportService: excelExportService,
      notificationSvc: mockNotifService,
    );

    settingsProvider = SettingsProvider(database: appDb);
    await settingsProvider.loadSettings();

    accountProvider = AccountProvider(repository: accountRepo);
    categoryProvider = CategoryProvider(repository: categoryRepo);
    txProvider = TransactionProvider(repository: txRepo);
    transferProvider = TransferProvider(repository: transferRepo);
    final recurringProcessor = RecurringProcessor(
      database: appDb,
      recurringRepository: recurringRepo,
    );
    recurringProvider = RecurringProvider(
      repository: recurringRepo,
      processor: recurringProcessor,
    );
    reminderProvider = ReminderProvider(repository: reminderRepo);

    backupProvider = BackupProvider(
      backupService: backupService,
      excelExportService: excelExportService,
      integrityService: integrityService,
      automaticExportService: autoExportService,
      notificationService: mockNotifService,
    );

    // Seed account
    await accountRepo.createAccount(Account(
      id: 'acc_main',
      name: 'Main Checking',
      accountType: AccountType.bank,
      currency: 'INR',
      openingBalance: Money.fromUnits(50000),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    await accountProvider.loadAccounts();
  });

  tearDown(() async {
    StorageHelper.customExportDirectory = null;
    if (db.isOpen) {
      await db.close();
    }
  });

  Widget buildTestShell({int initialTab = 0}) {
    MainNavigationService.currentTabNotifier.value = initialTab;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AccountProvider>.value(value: accountProvider),
        ChangeNotifierProvider<CategoryProvider>.value(value: categoryProvider),
        ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
        ChangeNotifierProvider<TransferProvider>.value(value: transferProvider),
        ChangeNotifierProvider<RecurringProvider>.value(value: recurringProvider),
        ChangeNotifierProvider<ReminderProvider>.value(value: reminderProvider),
        ChangeNotifierProvider<BackupProvider>.value(value: backupProvider),
      ],
      child: MaterialApp(
        navigatorKey: MainNavigationService.navigatorKey,
        home: Scaffold(
          key: MainNavigationService.mainScaffoldKey,
          drawer: const AppDrawer(),
          body: ValueListenableBuilder<int>(
            valueListenable: MainNavigationService.currentTabNotifier,
            builder: (context, currentTab, _) {
              return IndexedStack(
                index: currentTab,
                children: const [
                  Center(child: Text('Dashboard Screen')),
                  Center(child: Text('Transactions Screen')),
                  Center(child: Text('Accounts Screen')),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  group('Phase 3 - Automatic Export Service Logic', () {
    test('calculateMostRecentDueTime handles Daily schedule correctly', () {
      const config = AutoExportConfig(
        frequency: AutoExportFrequency.daily,
        preferredTime: TimeOfDay(hour: 20, minute: 0),
      );

      // 1. Same day, AFTER preferred time (22:30 > 20:00) -> due time is today at 20:00
      final nowAfter = DateTime(2026, 11, 16, 22, 30);
      final dueAfter = autoExportService.calculateMostRecentDueTime(config, from: nowAfter);
      expect(dueAfter, equals(DateTime(2026, 11, 16, 20, 0)));

      // 2. Same day, EXACTLY at preferred time (20:00) -> due time is today at 20:00
      final nowExact = DateTime(2026, 11, 16, 20, 0);
      final dueExact = autoExportService.calculateMostRecentDueTime(config, from: nowExact);
      expect(dueExact, equals(DateTime(2026, 11, 16, 20, 0)));

      // 3. Same day, BEFORE preferred time (07:15 < 20:00) -> due time was yesterday at 20:00
      final nowBefore = DateTime(2026, 11, 17, 7, 15);
      final dueBefore = autoExportService.calculateMostRecentDueTime(config, from: nowBefore);
      expect(dueBefore, equals(DateTime(2026, 11, 16, 20, 0)));
    });

    test('calculateMostRecentDueTime handles Weekly schedule correctly', () {
      const config = AutoExportConfig(
        frequency: AutoExportFrequency.weekly,
        dayOfWeek: DateTime.sunday, // Sunday = 7
        preferredTime: TimeOfDay(hour: 18, minute: 0),
      );

      // Sunday 2026-11-15 at 19:00 (after 18:00) -> most recent due is today (2026-11-15 18:00)
      final sundayAfter = DateTime(2026, 11, 15, 19, 0);
      expect(
        autoExportService.calculateMostRecentDueTime(config, from: sundayAfter),
        equals(DateTime(2026, 11, 15, 18, 0)),
      );

      // Sunday 2026-11-15 at 10:00 (before 18:00) -> most recent due was previous Sunday (2026-11-08 18:00)
      final sundayBefore = DateTime(2026, 11, 15, 10, 0);
      expect(
        autoExportService.calculateMostRecentDueTime(config, from: sundayBefore),
        equals(DateTime(2026, 11, 8, 18, 0)),
      );

      // Monday 2026-11-16 at 09:00 -> most recent due was yesterday (2026-11-15 18:00)
      final monday = DateTime(2026, 11, 16, 9, 0);
      expect(
        autoExportService.calculateMostRecentDueTime(config, from: monday),
        equals(DateTime(2026, 11, 15, 18, 0)),
      );
    });

    test('calculateMostRecentDueTime handles Monthly schedule with safe month-end clamp', () {
      const config31 = AutoExportConfig(
        frequency: AutoExportFrequency.monthly,
        dayOfMonth: 31,
        preferredTime: TimeOfDay(hour: 21, minute: 0),
      );

      // March 1st at 08:00 (after Feb): Feb 2026 has 28 days -> clamped to Feb 28 21:00
      final march1 = DateTime(2026, 3, 1, 8, 0);
      expect(
        autoExportService.calculateMostRecentDueTime(config31, from: march1),
        equals(DateTime(2026, 2, 28, 21, 0)),
      );

      // Feb 28 2026 at 22:00 (after 21:00): clamps to Feb 28 21:00
      final feb28After = DateTime(2026, 2, 28, 22, 0);
      expect(
        autoExportService.calculateMostRecentDueTime(config31, from: feb28After),
        equals(DateTime(2026, 2, 28, 21, 0)),
      );

      // May 1st 2026 (after April with 30 days): clamps to Apr 30 21:00
      final may1 = DateTime(2026, 5, 1, 10, 0);
      expect(
        autoExportService.calculateMostRecentDueTime(config31, from: may1),
        equals(DateTime(2026, 4, 30, 21, 0)),
      );
    });

    test('checkAndRunIfDue catches missed executions upon awakening', () async {
      // Configure Daily at 20:00, enabled yesterday at 14:00
      final enabledTime = DateTime(2026, 11, 15, 14, 0);
      final lastSuccessfulRun = DateTime(2026, 11, 15, 20, 1);

      await autoExportService.saveConfig(
        AutoExportConfig(
          isEnabled: true,
          frequency: AutoExportFrequency.daily,
          preferredTime: const TimeOfDay(hour: 20, minute: 0),
          lastRunTime: lastSuccessfulRun,
          enabledAt: enabledTime,
        ),
      );

      // Suppose phone was off at 20:00 on 2026-11-16, and user opens app at 07:30 on 2026-11-17
      final nextMorning = DateTime(2026, 11, 17, 7, 30);
      final result = await autoExportService.checkAndRunIfDue(currentTime: nextMorning);

      // It must recognize that 2026-11-16 20:00 was missed and execute successfully!
      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.file, isNotNull);
      expect(await result.file!.exists(), isTrue);

      // Verify that the database was updated with the latest run time
      final updatedConfig = await autoExportService.loadConfig();
      expect(updatedConfig.lastRunStatus, equals('success'));
      expect(updatedConfig.lastRunTime, isNotNull);
    });

    test('checkAndRunIfDue prevents duplicate exports on the same day', () async {
      final todayRun = DateTime(2026, 11, 16, 20, 2);
      await autoExportService.saveConfig(
        AutoExportConfig(
          isEnabled: true,
          frequency: AutoExportFrequency.daily,
          preferredTime: const TimeOfDay(hour: 20, minute: 0),
          lastRunTime: todayRun,
        ),
      );

      // App reopens at 21:00 on the same day
      final sameDayLater = DateTime(2026, 11, 16, 21, 0);
      final result = await autoExportService.checkAndRunIfDue(currentTime: sameDayLater);

      // Must NOT run again
      expect(result, isNull);
    });

    test('checkAndRunIfDue newly enabled does not falsely trigger for yesterday', () async {
      // User enables schedule at 15:00 today for 20:00 today
      final nowTime = DateTime(2026, 11, 16, 15, 0);
      await autoExportService.saveConfig(
        AutoExportConfig(
          isEnabled: true,
          frequency: AutoExportFrequency.daily,
          preferredTime: const TimeOfDay(hour: 20, minute: 0),
          enabledAt: nowTime,
          lastRunTime: null,
        ),
      );

      // App runs check at 16:00
      final checkTime = DateTime(2026, 11, 16, 16, 0);
      final result = await autoExportService.checkAndRunIfDue(currentTime: checkTime);

      // Must wait for 20:00 today, NOT run for yesterday!
      expect(result, isNull);
    });
  });

  group('Phase 3 - Sidebar Navigation (Always Return to Home / Tab 0)', () {
    testWidgets('Exiting Reports from Accounts tab returns to Home (Tab 0)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Start on Accounts tab (index 2)
      await tester.pumpWidget(buildTestShell(initialTab: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(MainNavigationService.currentTab, equals(2));

      // Open drawer
      MainNavigationService.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Reports
      await tester.tap(find.text('Reports'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Allow async load to complete
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify we are on Reports Screen
      expect(find.text('Reports'), findsWidgets);

      // Tap Back button in header
      await tester.tap(find.byTooltip('Back').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Must land on Home (Dashboard, Tab 0)
      expect(MainNavigationService.currentTab, equals(0));
    });

    testWidgets('Exiting Settings from Transactions tab returns to Home (Tab 0)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Start on Transactions tab (index 1)
      await tester.pumpWidget(buildTestShell(initialTab: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(MainNavigationService.currentTab, equals(1));

      // Open drawer
      MainNavigationService.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Settings'), findsWidgets);

      // Tap Back button in header
      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must land on Home (Dashboard, Tab 0)
      expect(MainNavigationService.currentTab, equals(0));
    });

    testWidgets('Nested back navigation inside Settings unwinds correctly before returning to Home', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Start on Accounts tab (index 2)
      await tester.pumpWidget(buildTestShell(initialTab: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open drawer -> Settings
      MainNavigationService.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Inside Settings -> tap Appearance
      await tester.tap(find.text('Appearance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Warm off-white matte background with navy headers'), findsOneWidget);

      // Back 1: Returns from Appearance to Settings
      await tester.tap(find.byTooltip('Back').last);
      await tester.pumpAndSettle();

      expect(find.text('Warm off-white matte background with navy headers'), findsNothing);
      expect(find.text('Settings'), findsWidgets);

      // Back 2: Returns from Settings to Home (Tab 0)
      await tester.tap(find.byTooltip('Back').last);
      await tester.pumpAndSettle();

      expect(MainNavigationService.currentTab, equals(0));
    });

    testWidgets('Closing drawer without selecting leaves active tab unchanged', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Start on Accounts tab (index 2)
      await tester.pumpWidget(buildTestShell(initialTab: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(MainNavigationService.currentTab, equals(2));

      // Open drawer
      MainNavigationService.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Close drawer programmatically
      MainNavigationService.closeDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Active tab must STILL be Accounts (index 2)
      expect(MainNavigationService.currentTab, equals(2));
    });
  });
}
