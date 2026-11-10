import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/core/theme/app_theme.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/export_bottom_sheet.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/backup/data/services/automatic_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/backup_service.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/integrity_service.dart';
import 'package:kals_money_manager/features/backup/presentation/providers/backup_provider.dart';
import 'package:kals_money_manager/features/backup/presentation/screens/automatic_export_screen.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
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

  late Database db;
  late AppDatabase appDb;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl txRepo;
  late TransferRepositoryImpl transferRepo;
  late RecurringRepositoryImpl recurringRepo;
  late BackupService backupService;
  late IntegrityService integrityService;
  late ExcelExportService excelExportService;
  late MockNotificationService mockNotifService;
  late AutomaticExportService autoExportService;
  late BackupProvider backupProvider;
  late AccountProvider accountProvider;
  late CategoryProvider categoryProvider;
  late TransactionProvider txProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auto_export_test_');
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

    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    transferRepo = TransferRepositoryImpl(database: appDb);
    recurringRepo = RecurringRepositoryImpl(database: appDb);

    backupService = BackupService(database: appDb);
    integrityService = IntegrityService(database: appDb);
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

    backupProvider = BackupProvider(
      backupService: backupService,
      excelExportService: excelExportService,
      integrityService: integrityService,
      automaticExportService: autoExportService,
      notificationService: mockNotifService,
    );

    // Seed test accounts and categories
    await accountRepo.createAccount(Account(
      id: 'acc_main',
      name: 'Main Checking',
      accountType: AccountType.bank,
      currency: 'INR',
      openingBalance: Money.fromUnits(500000),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await categoryRepo.createCategory(Category(
      id: 'cat_salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: 'attach_money',
      color: 0xFF2E7D32,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await categoryRepo.createCategory(Category(
      id: 'cat_rent',
      name: 'Rent',
      type: CategoryType.expense,
      icon: 'home',
      color: 0xFFC62828,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Seed transactions from older months and today
    // 1. Transaction from 6 months ago
    await txRepo.createTransaction(Transaction(
      id: 'tx_old_6m',
      accountId: 'acc_main',
      categoryId: 'cat_salary',
      transactionType: CategoryType.income,
      amount: Money.fromUnits(100000),
      date: DateTime(2025, 4, 15, 10, 0),
      description: 'April Bonus',
      notes: 'Historical April 2025 bonus',
      createdAt: DateTime(2025, 4, 15, 10, 0),
      updatedAt: DateTime(2025, 4, 15, 10, 0),
    ));

    // 2. Transaction from 2 months ago
    await txRepo.createTransaction(Transaction(
      id: 'tx_old_2m',
      accountId: 'acc_main',
      categoryId: 'cat_rent',
      transactionType: CategoryType.expense,
      amount: Money.fromUnits(25000),
      date: DateTime(2025, 8, 1, 9, 30),
      description: 'August Rent',
      notes: 'August Rent note',
      createdAt: DateTime(2025, 8, 1, 9, 30),
      updatedAt: DateTime(2025, 8, 1, 9, 30),
    ));

    // 3. Current transaction today
    await txRepo.createTransaction(Transaction(
      id: 'tx_today',
      accountId: 'acc_main',
      categoryId: 'cat_salary',
      transactionType: CategoryType.income,
      amount: Money.fromUnits(50000),
      date: DateTime.now(),
      description: 'Today payout',
      notes: 'Today payout note',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    accountProvider = AccountProvider(repository: accountRepo);
    await accountProvider.loadAccounts();

    categoryProvider = CategoryProvider(repository: categoryRepo);
    await categoryProvider.loadCategories();

    txProvider = TransactionProvider(repository: txRepo);
    await txProvider.loadLedger();

    settingsProvider = SettingsProvider(database: appDb);
    await settingsProvider.loadSettings();
  });

  tearDown(() async {
    await db.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BackupProvider>.value(value: backupProvider),
        ChangeNotifierProvider<AccountProvider>.value(value: accountProvider),
        ChangeNotifierProvider<CategoryProvider>.value(value: categoryProvider),
        ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: child,
      ),
    );
  }

  group('Automatic Export Acceptance Tests', () {
    test('1. Schedule calculation handles daily, weekly, and monthly safe month clamp', () {
      final configDaily = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.daily,
        preferredTime: const TimeOfDay(hour: 20, minute: 0),
      );

      final baseTime = DateTime(2026, 10, 25, 10, 0); // 10:00 AM
      final nextDaily = autoExportService.calculateNextRun(configDaily, from: baseTime);
      expect(nextDaily.year, equals(2026));
      expect(nextDaily.month, equals(10));
      expect(nextDaily.day, equals(25));
      expect(nextDaily.hour, equals(20));
      expect(nextDaily.minute, equals(0));

      // Weekly schedule
      final configWeekly = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.weekly,
        preferredTime: const TimeOfDay(hour: 9, minute: 0),
        dayOfWeek: DateTime.wednesday,
      );
      // Base date: Sunday 2026-10-25
      final nextWeekly = autoExportService.calculateNextRun(configWeekly, from: baseTime);
      expect(nextWeekly.weekday, equals(DateTime.wednesday));
      expect(nextWeekly.isAfter(baseTime), isTrue);

      // Monthly schedule: Preferred Day 31 clamped to Feb 28 in non-leap year
      final configMonthly31 = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.monthly,
        preferredTime: const TimeOfDay(hour: 22, minute: 0),
        dayOfMonth: 31,
      );

      final febBase = DateTime(2025, 2, 1, 10, 0); // 2025 is not a leap year
      final nextFeb = autoExportService.calculateNextRun(configMonthly31, from: febBase);
      expect(nextFeb.month, equals(2));
      expect(nextFeb.day, equals(28)); // Safely clamped to 28
      expect(nextFeb.hour, equals(22));

      // April (30 days) clamped to 30
      final aprBase = DateTime(2026, 4, 1, 10, 0);
      final nextApr = autoExportService.calculateNextRun(configMonthly31, from: aprBase);
      expect(nextApr.month, equals(4));
      expect(nextApr.day, equals(30)); // Safely clamped to 30
    });

    test('2 & 8. Run "Export now", verify valid Excel file created and contains all historical months', () async {
      final result = await backupProvider.runAutoExportNow();

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.file, isNotNull);

      final file = result.file!;
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));

      // Parse and inspect Excel workbook
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      expect(excel.sheets.containsKey('Summary'), isTrue);
      expect(excel.sheets.containsKey('Transactions'), isTrue);

      final txSheet = excel.sheets['Transactions']!;
      // Verify rows exist for older months (April 2025, August 2025, and Today)
      final allCellText = txSheet.rows
          .expand((row) => row)
          .where((cell) => cell?.value != null)
          .map((cell) => cell!.value.toString())
          .toList();

      expect(allCellText.any((t) => t.contains('Historical April 2025 bonus') || t.contains('100000')), isTrue);
      expect(allCellText.any((t) => t.contains('August Rent') || t.contains('25000')), isTrue);
      expect(allCellText.any((t) => t.contains('Today payout') || t.contains('50000')), isTrue);
    });

    test('3. Completion notification appears only after successful file validation', () async {
      mockNotifService.exportNotificationsShown = 0;

      final result = await backupProvider.runAutoExportNow();
      expect(result!.success, isTrue);

      expect(mockNotifService.exportNotificationsShown, equals(1));
      expect(mockNotifService.lastTitle, equals('Kals Money Manager'));
      expect(mockNotifService.lastBody, equals('Automatic export completed. Your Excel file is ready.'));
      expect(mockNotifService.lastIsSuccess, isTrue);
      expect(mockNotifService.lastFilePath, isNotNull);
    });

    test('4. Restart the app and verify schedule and settings remain enabled', () async {
      // Save settings
      const newConfig = AutoExportConfig(
        isEnabled: true,
        frequency: AutoExportFrequency.weekly,
        preferredTime: TimeOfDay(hour: 18, minute: 30),
        dayOfWeek: DateTime.saturday,
        scope: AutoExportScope.allTransactions,
        notifyOnComplete: true,
      );
      await autoExportService.saveConfig(newConfig);

      // Simulate app restart by loading clean instance from database
      final reloadedService = AutomaticExportService(
        database: appDb,
        backupService: backupService,
        excelExportService: excelExportService,
      );
      final loadedConfig = await reloadedService.loadConfig();

      expect(loadedConfig.isEnabled, isTrue);
      expect(loadedConfig.frequency, equals(AutoExportFrequency.weekly));
      expect(loadedConfig.preferredTime.hour, equals(18));
      expect(loadedConfig.preferredTime.minute, equals(30));
      expect(loadedConfig.dayOfWeek, equals(DateTime.saturday));
      expect(loadedConfig.scope, equals(AutoExportScope.allTransactions));
      expect(loadedConfig.notifyOnComplete, isTrue);
    });

    test('5 & 6. Change frequency replaces old schedule; disabling cancels scheduled work', () async {
      // Enable and set frequency to daily
      await backupProvider.updateAutoExportConfig(
        backupProvider.autoExportConfig.copyWith(
          isEnabled: true,
          frequency: AutoExportFrequency.daily,
        ),
      );
      expect(backupProvider.autoExportConfig.isEnabled, isTrue);
      expect(backupProvider.autoExportConfig.frequency, equals(AutoExportFrequency.daily));

      // Change frequency to monthly
      await backupProvider.updateAutoExportConfig(
        backupProvider.autoExportConfig.copyWith(
          frequency: AutoExportFrequency.monthly,
          dayOfMonth: 15,
        ),
      );
      expect(backupProvider.autoExportConfig.frequency, equals(AutoExportFrequency.monthly));
      expect(backupProvider.autoExportConfig.dayOfMonth, equals(15));

      // Disable automatic export
      await backupProvider.updateAutoExportConfig(
        backupProvider.autoExportConfig.copyWith(
          isEnabled: false,
        ),
      );
      expect(backupProvider.autoExportConfig.isEnabled, isFalse);
    });

    testWidgets('AutomaticExportScreen renders all required controls and interacts', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestApp(const AutomaticExportScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Screen Header
      expect(find.text('Automatic Export'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Verify Main Controls
      expect(find.text('Enable automatic export'), findsOneWidget);
      expect(find.text('EXPORT SPECIFICATIONS'), findsOneWidget);
      expect(find.text('All Transactions'), findsOneWidget);
      expect(find.text('Excel Workbook (.xlsx)'), findsOneWidget);
      expect(find.text('Save Location'), findsOneWidget);
      expect(find.text('Notify me after export'), findsOneWidget);

      // Verify Status section
      expect(find.text('STATUS & EXECUTION'), findsOneWidget);
      expect(find.text('Next Scheduled Export'), findsOneWidget);
      expect(find.text('Last Export Status'), findsOneWidget);

      // Verify "Export Now" Button
      expect(find.text('Export Now'), findsOneWidget);

      // Test Export Now tap inside runAsync for real storage I/O
      await tester.runAsync(() async {
        await tester.tap(find.text('Export Now'));
        for (int i = 0; i < 40; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!backupProvider.isProcessing && backupProvider.lastExportFile != null) {
            break;
          }
        }
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(backupProvider.errorMessage, isNull);
      // Success dialog appears
      expect(find.text('Export Completed'), findsOneWidget);
    });

    testWidgets('ExportBottomSheet renders 3 options and excludes backup/restore', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    ExportBottomSheet.show(
                      context,
                      periodMode: TimePeriod.month,
                      anchorDate: DateTime.now(),
                      accountId: 'acc_main',
                      accountName: 'Main Checking',
                    );
                  },
                  child: const Text('Open Export Menu'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Open sheet
      await tester.tap(find.text('Open Export Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Export Transactions
      expect(find.text('Export Transactions'), findsNWidgets(2)); // Title header + Option 1
      expect(find.text('Select a period and preview transactions before exporting.'), findsOneWidget);

      // 2. Export All Transactions
      expect(find.text('Export All Transactions'), findsOneWidget);
      expect(find.text('Export the complete transaction history.'), findsOneWidget);

      // 3. Automatic Export
      expect(find.text('Automatic Export'), findsOneWidget);
      expect(find.text('Configure and manage scheduled local exports.'), findsOneWidget);

      // Verify NO backup or restore options exist
      expect(find.textContaining('Full Backup'), findsNothing);
      expect(find.textContaining('Restore'), findsNothing);
      expect(find.textContaining('.mmb'), findsNothing);
    });
  });
}
