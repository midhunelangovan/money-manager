import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
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

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (MethodCall methodCall) async => 'UTC',
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App launches offline with bottom navigation and dashboard', (tester) async {
    final db = await openDatabase(
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

    final settings = SettingsProvider(database: appDb);
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider(create: (_) => AccountProvider(repository: accountRepo)..loadAccounts()),
          ChangeNotifierProvider(create: (_) => CategoryProvider(repository: categoryRepo)..loadCategories()),
          ChangeNotifierProvider(create: (_) => TransactionProvider(repository: txRepo)..loadLedger()),
          ChangeNotifierProvider(create: (_) => TransferProvider(repository: transferRepo)..loadTransfers()),
          ChangeNotifierProvider(
            create: (_) => RecurringProvider(
              repository: recurringRepo,
              processor: recurringProcessor,
            )..loadRecurring(),
          ),
          ChangeNotifierProvider(
            create: (_) => ReminderProvider(
              repository: reminderRepo,
            )..loadReminders(),
          ),
          ChangeNotifierProvider(
            create: (_) => BackupProvider(
              backupService: backupService,
              excelExportService: excelExportService,
              integrityService: integrityService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ExcelImportProvider(
              importService: excelImportService,
            ),
          ),
        ],
        child: const MoneyManagerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Dashboard UI elements
    expect(find.text('EXPENSES'), findsOneWidget);
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}

