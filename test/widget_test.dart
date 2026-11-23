import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/backup/data/services/backup_service.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/integrity_service.dart';
import 'package:kals_money_manager/features/backup/presentation/providers/backup_provider.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/recurring/domain/services/recurring_processor.dart';
import 'package:kals_money_manager/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/presentation/providers/transfer_provider.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_import_service.dart';
import 'package:kals_money_manager/features/backup/presentation/providers/excel_import_provider.dart';
import 'package:kals_money_manager/features/reminders/data/repositories/reminder_repository.dart';
import 'package:kals_money_manager/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:kals_money_manager/main.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:flutter/services.dart';
import 'package:kals_money_manager/core/services/widget_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    NotificationService.isTestMode = true;
    WidgetService.isTestMode = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (MethodCall methodCall) async => 'UTC',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.kals.kals_money_manager/widget_channel'),
      (MethodCall methodCall) async => null,
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App launches offline with bottom navigation and dashboard', (tester) async {
    late Database db;
    late SettingsProvider settings;
    late AccountProvider accProvider;
    late CategoryProvider catProvider;
    late TransactionProvider txProvider;
    late TransferProvider transferProvider;
    late RecurringProvider recurringProvider;
    late ReminderProvider reminderProvider;
    late BackupProvider backupProvider;
    late ExcelImportProvider excelImportProvider;

    await tester.runAsync(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      );
      final appDb = AppDatabase.withDatabase(db);
      AppDatabase.setTestInstance(appDb);

      final accountRepo = AccountRepositoryImpl(database: appDb);
      final categoryRepo = CategoryRepositoryImpl(database: appDb);
      final txRepo = TransactionRepositoryImpl(database: appDb);
      final transferRepo = TransferRepositoryImpl(database: appDb);
      final recurringRepo = RecurringRepositoryImpl(database: appDb);
      final recurringProcessor = RecurringProcessor(database: appDb, recurringRepository: recurringRepo);

      final backupService = BackupService(database: appDb);
      final integrityService = IntegrityService(database: appDb);
      final excelExportService = ExcelExportService(
        accountRepository: accountRepo,
        categoryRepository: categoryRepo,
        transactionRepository: txRepo,
        transferRepository: transferRepo,
        recurringRepository: recurringRepo,
      );

      final reminderRepo = ReminderRepository(db: appDb);
      final excelImportService = ExcelImportService(database: appDb);

      settings = SettingsProvider(database: appDb);
      await settings.loadSettings();

      final account = Account(
        id: 'acc_main',
        name: 'Main Account',
        accountType: AccountType.bank,
        openingBalance: Money.fromUnits(100000),
        color: 0xFF1E3A5F,
        icon: 'account_balance',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await accountRepo.createAccount(account);
      settings.setPrimaryAccountId(account.id);
      settings.setOnboardingCompleted(true);

      accProvider = AccountProvider(repository: accountRepo);
      await accProvider.loadAccounts();
      catProvider = CategoryProvider(repository: categoryRepo);
      await catProvider.loadCategories();
      txProvider = TransactionProvider(repository: txRepo);
      await txProvider.loadLedger();
      transferProvider = TransferProvider(repository: transferRepo);
      await transferProvider.loadTransfers();
      recurringProvider = RecurringProvider(repository: recurringRepo, processor: recurringProcessor);
      await recurringProvider.loadRecurring();
      reminderProvider = ReminderProvider(repository: reminderRepo);
      await reminderProvider.loadReminders();

      backupProvider = BackupProvider(
        backupService: backupService,
        excelExportService: excelExportService,
        integrityService: integrityService,
      );
      excelImportProvider = ExcelImportProvider(
        importService: excelImportService,
      );
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: accProvider),
          ChangeNotifierProvider.value(value: catProvider),
          ChangeNotifierProvider.value(value: txProvider),
          ChangeNotifierProvider.value(value: transferProvider),
          ChangeNotifierProvider.value(value: recurringProvider),
          ChangeNotifierProvider.value(value: reminderProvider),
          ChangeNotifierProvider.value(value: backupProvider),
          ChangeNotifierProvider.value(value: excelImportProvider),
        ],
        child: const MoneyManagerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify no persistent bottom navigation bar exists anywhere in the app shell
    expect(find.byType(NavigationBar), findsNothing);

    // Verify Dashboard UI elements are rendered
    expect(find.text('EXPENSES'), findsOneWidget);
    expect(find.text('INCOME'), findsOneWidget);

    // Open Sidebar Drawer via hamburger menu button
    final menuButton = find.byTooltip('Navigation Menu');
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify sidebar destinations are present in AppDrawer
    expect(find.text('Home'), findsOneWidget);
    expect(find.descendant(of: find.byType(Drawer), matching: find.text('Transactions')), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Recurring Payments'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      await db.close();
    });
  });
}
