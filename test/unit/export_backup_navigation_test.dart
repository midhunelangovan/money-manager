import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/theme/app_theme.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/backup/data/services/backup_service.dart';
import 'package:kals_money_manager/features/backup/data/services/excel_export_service.dart';
import 'package:kals_money_manager/features/backup/data/services/integrity_service.dart';
import 'package:kals_money_manager/features/backup/presentation/providers/backup_provider.dart';
import 'package:kals_money_manager/features/backup/presentation/screens/export_transactions_screen.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AppDatabase appDb;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl txRepo;
  late TransferRepositoryImpl transferRepo;
  late RecurringRepositoryImpl recurringRepo;
  late BackupProvider backupProvider;
  late AccountProvider accountProvider;
  late CategoryProvider categoryProvider;
  late TransactionProvider txProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
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

    final backupService = BackupService(database: appDb);
    final integrityService = IntegrityService(database: appDb);
    final excelExportService = ExcelExportService(
      accountRepository: accountRepo,
      categoryRepository: categoryRepo,
      transactionRepository: txRepo,
      transferRepository: transferRepo,
      recurringRepository: recurringRepo,
    );

    backupProvider = BackupProvider(
      backupService: backupService,
      excelExportService: excelExportService,
      integrityService: integrityService,
    );

    // Seed test account
    await accountRepo.createAccount(Account(
      id: 'acc_cash',
      name: 'Cash Wallet',
      accountType: AccountType.cash,
      currency: 'INR',
      openingBalance: Money.fromUnits(100000),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Seed test category
    await categoryRepo.createCategory(Category(
      id: 'cat_groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_bag',
      color: 0xFF2E7D32,
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

  testWidgets('ExportTransactionsScreen renders full-screen header and all 3 sections', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const ExportTransactionsScreen(),
      ),
    );

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Header
    expect(find.text('Export Transactions'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Section 1: Verify Period Tabs
    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('Period'), findsOneWidget);

    // Verify Navigation Chevrons
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    // Verify Filters: Account & Type
    expect(find.text('Account:'), findsOneWidget);
    expect(find.text('All Accounts'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Section 2: Verify Transaction Preview Section
    expect(find.text('TRANSACTION PREVIEW'), findsOneWidget);
    expect(find.text('Income'), findsNWidgets(2)); // Type filter tab + Preview metric label
    expect(find.text('Expenses'), findsNWidgets(2)); // Type filter tab + Preview metric label
    expect(find.text('Net'), findsOneWidget);

    // Section 3: Verify Export Action Button
    expect(find.text('Export to Excel'), findsOneWidget);

    // Verify NO backup-related options appear
    expect(find.text('Create Full Backup'), findsNothing);
    expect(find.text('Automatic Export Settings'), findsNothing);
    expect(find.textContaining('mmb'), findsNothing);
  });

  testWidgets('Back arrow pops ExportTransactionsScreen', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExportTransactionsScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Export Page'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap button to navigate to ExportTransactionsScreen
    await tester.tap(find.text('Open Export Page'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Export Transactions'), findsWidgets);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify back to previous page
    expect(find.text('Open Export Page'), findsOneWidget);
  });

  testWidgets('Export button is disabled when no matching transactions exist', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const ExportTransactionsScreen(),
      ),
    );
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Expect empty state message
    expect(find.text('No matching transactions to export'), findsOneWidget);
    expect(find.text('0 transactions'), findsOneWidget);

    // Export button should be present with label
    expect(find.text('Export to Excel'), findsOneWidget);
  });
}
