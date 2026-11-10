import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/navigation/navigation_service.dart';
import 'package:kals_money_manager/core/services/notification_service.dart';
import 'package:kals_money_manager/core/theme/app_theme.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';
import 'package:kals_money_manager/core/widgets/transaction_type_tabs.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/dashboard/presentation/models/dashboard_filter_state.dart';
import 'package:kals_money_manager/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:kals_money_manager/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:kals_money_manager/features/recurring/domain/services/recurring_processor.dart';
import 'package:kals_money_manager/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:kals_money_manager/features/reminders/data/repositories/reminder_repository.dart';
import 'package:kals_money_manager/features/reminders/domain/entities/reminder.dart';
import 'package:kals_money_manager/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:kals_money_manager/features/transfers/presentation/providers/transfer_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));

  setUpAll(() {
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
  late ReminderRepository reminderRepo;
  late AccountProvider accountProvider;
  late CategoryProvider categoryProvider;
  late TransactionProvider txProvider;
  late TransferProvider transferProvider;
  late RecurringProvider recurringProvider;
  late ReminderProvider reminderProvider;
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
    AppDatabase.setTestInstance(appDb);

    await db.delete(DbTables.recurringTransactions);
    await db.delete(DbTables.reminders);
    await db.delete(DbTables.transactions);
    await db.delete(DbTables.transfers);
    await db.delete(DbTables.categories);
    await db.delete(DbTables.accounts);

    accountRepo = AccountRepositoryImpl(database: appDb);
    categoryRepo = CategoryRepositoryImpl(database: appDb);
    txRepo = TransactionRepositoryImpl(database: appDb);
    transferRepo = TransferRepositoryImpl(database: appDb);
    recurringRepo = RecurringRepositoryImpl(database: appDb);
    reminderRepo = ReminderRepository(db: appDb);

    // Seed Accounts: HDFC (₹5,000) and Canara (₹10,000)
    await accountRepo.createAccount(Account(
      id: 'acc_hdfc',
      name: 'HDFC',
      accountType: AccountType.bank,
      currency: 'INR',
      openingBalance: Money.fromUnits(500000), // ₹5,000.00
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await accountRepo.createAccount(Account(
      id: 'acc_canara',
      name: 'Canara Bank',
      accountType: AccountType.bank,
      currency: 'INR',
      openingBalance: Money.fromUnits(1000000), // ₹10,000.00
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await categoryRepo.createCategory(Category(
      id: 'cat_rent',
      name: 'Rent',
      type: CategoryType.expense,
      icon: 'home_rounded',
      color: 0xFF23818D,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    accountProvider = AccountProvider(repository: accountRepo);
    await accountProvider.loadAccounts();

    categoryProvider = CategoryProvider(repository: categoryRepo);
    await categoryProvider.loadCategories();

    txProvider = TransactionProvider(repository: txRepo);
    await txProvider.loadLedger();

    transferProvider = TransferProvider(repository: transferRepo);
    await transferProvider.loadTransfers();

    final recurringProc = RecurringProcessor(database: appDb, recurringRepository: recurringRepo);
    recurringProvider = RecurringProvider(repository: recurringRepo, processor: recurringProc);
    await recurringProvider.loadRecurring();

    reminderProvider = ReminderProvider(repository: reminderRepo);
    await reminderProvider.loadReminders();

    settingsProvider = SettingsProvider(database: appDb);
    await settingsProvider.loadSettings();
  });

  tearDown(() async {
    AppDatabase.setTestInstance(null);
    await db.close();
  });

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccountProvider>.value(value: accountProvider),
        ChangeNotifierProvider<CategoryProvider>.value(value: categoryProvider),
        ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
        ChangeNotifierProvider<TransferProvider>.value(value: transferProvider),
        ChangeNotifierProvider<RecurringProvider>.value(value: recurringProvider),
        ChangeNotifierProvider<ReminderProvider>.value(value: reminderProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        navigatorKey: MainNavigationService.navigatorKey,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        home: child,
      ),
    );
  }

  group('Area 6 & 7: Account Transfers and Balances Consistency', () {
    test('Moving ₹500 from HDFC to Canara adjusts both accounts and keeps total balance constant', () async {
      // Initial balances: HDFC = 500,000 units (₹5,000), Canara = 1,000,000 units (₹10,000), Total = ₹15,000
      expect(accountProvider.totalBalance.units, 1500000);

      final transfer = Transfer(
        id: 'tr_test_1',
        fromAccountId: 'acc_hdfc',
        toAccountId: 'acc_canara',
        amount: Money.fromUnits(50000), // ₹500.00
        date: DateTime.now(),
        description: 'Monthly savings',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await transferProvider.createTransfer(transfer);
      await accountProvider.loadAccounts();
      await txProvider.loadLedger();

      // Check updated account balances
      final hdfc = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == 'acc_hdfc');
      final canara = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == 'acc_canara');

      expect(hdfc.calculatedBalance.units, 450000); // 5000 - 500 = 4500
      expect(canara.calculatedBalance.units, 1050000); // 10000 + 500 = 10500
      expect(accountProvider.totalBalance.units, 1500000); // Combined unchanged!

      // Check that ordinary financial summary (income / expenses) is NOT affected
      final summary = txProvider.globalSummary;
      expect(summary.totalIncome.units, 0);
      expect(summary.totalExpense.units, 0);

      // Check Transfer History records
      final allTransfers = await transferRepo.getAllTransfers();
      expect(allTransfers.length, 1);
      expect(allTransfers.first.id, 'tr_test_1');
      expect(allTransfers.first.amount.units, 50000);

      // Delete/Reverse transfer
      await transferProvider.deleteTransfer('tr_test_1');
      await accountProvider.loadAccounts();
      await txProvider.loadLedger();

      final hdfcRestored = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == 'acc_hdfc');
      final canaraRestored = accountProvider.accountsWithBalances.firstWhere((a) => a.account.id == 'acc_canara');

      expect(hdfcRestored.calculatedBalance.units, 500000);
      expect(canaraRestored.calculatedBalance.units, 1000000);
    });

    testWidgets('AccountsScreen renders Header, Total, Transfer History, New Transfer, and Account rows', (tester) async {
      await tester.pumpWidget(buildTestApp(const AccountsScreen()));
      await tester.pumpAndSettle();

      // Header title 'Accounts'
      expect(find.text('Accounts'), findsOneWidget);

      // 'Total:' label and formatted total amount
      expect(find.text('Total:'), findsOneWidget);
      expect(find.text('₹ 15,000.00'), findsOneWidget);

      // Two distinct transfer actions
      expect(find.text('Transfer history'), findsOneWidget);
      expect(find.text('New transfer'), findsOneWidget);

      // Account items
      expect(find.text('HDFC'), findsOneWidget);
      expect(find.text('₹ 5,000.00'), findsOneWidget);
      expect(find.text('Canara Bank'), findsOneWidget);
      expect(find.text('₹ 10,000.00'), findsOneWidget);

      // Floating Add button exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('Area 3: Recurring Payments Distinction from Financial Transactions', () {
    test('Creating a recurring payment schedule does NOT insert a transaction into ledger', () async {
      final initialTxCount = (await txRepo.getUnifiedLedger()).length;
      expect(initialTxCount, 0);

      final recurring = RecurringTransaction(
        id: 'rec_rent_1',
        transactionType: CategoryType.expense,
        accountId: 'acc_hdfc',
        categoryId: 'cat_rent',
        amount: Money.fromUnits(1500000), // ₹15,000
        description: 'Apartment Rent',
        frequency: RecurringFrequency.monthly,
        interval: 1,
        startDate: DateTime.now(),
        nextExecutionDate: DateTime.now().add(const Duration(days: 10)),
        isActive: true,
        remindMe: true,
        reminderLeadDays: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await recurringProvider.createRecurring(recurring);
      await txProvider.loadLedger();

      // Ledger must remain 0! No transaction was silently added!
      final txList = await txRepo.getUnifiedLedger();
      expect(txList.isEmpty, isTrue);

      // Recurring schedule is saved
      final savedRec = await recurringRepo.getRecurringById('rec_rent_1');
      expect(savedRec, isNotNull);
      expect(savedRec!.description, 'Apartment Rent');
    });
  });

  group('Area 5: Dashboard Period Navigation & Today Indicator Tests', () {
    final fixedNow = DateTime(2026, 10, 24, 12, 0); // Saturday 24 Oct 2026

    test('Today indicator appears ONLY when current period is active; disappears on previous/future', () {
      // 1. Week Mode
      final currentWeekFilter = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 24),
        tabType: LedgerTabType.expenses,
      );
      final prevWeekFilter = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 15), // Previous week
        tabType: LedgerTabType.expenses,
      );
      final nextWeekFilter = DashboardFilterState(
        periodMode: TimePeriod.week,
        anchorDate: DateTime(2026, 10, 28), // Next week
        tabType: LedgerTabType.expenses,
      );

      // Current week -> Today appears
      expect(currentWeekFilter.shouldShowToday(localNow: fixedNow), isTrue);
      // Previous week -> Today disappears
      expect(prevWeekFilter.shouldShowToday(localNow: fixedNow), isFalse);
      // Next week -> Today disappears
      expect(nextWeekFilter.shouldShowToday(localNow: fixedNow), isFalse);

      // 2. Month Mode
      final currentMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 10, 1),
        tabType: LedgerTabType.expenses,
      );
      final prevMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2026, 9, 15),
        tabType: LedgerTabType.expenses,
      );
      final lastYearSameMonthFilter = DashboardFilterState(
        periodMode: TimePeriod.month,
        anchorDate: DateTime(2025, 10, 1),
        tabType: LedgerTabType.expenses,
      );

      expect(currentMonthFilter.shouldShowToday(localNow: fixedNow), isTrue);
      expect(prevMonthFilter.shouldShowToday(localNow: fixedNow), isFalse);
      expect(lastYearSameMonthFilter.shouldShowToday(localNow: fixedNow), isFalse);

      // 3. Day Mode
      final currentDayFilter = DashboardFilterState(
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 24),
        tabType: LedgerTabType.expenses,
      );
      final yesterdayFilter = DashboardFilterState(
        periodMode: TimePeriod.day,
        anchorDate: DateTime(2026, 10, 23),
        tabType: LedgerTabType.expenses,
      );

      expect(currentDayFilter.shouldShowToday(localNow: fixedNow), isTrue);
      expect(yesterdayFilter.shouldShowToday(localNow: fixedNow), isFalse);
    });
  });

  group('Area 2: Reminder Trigger Calculation Tests', () {
    final notifService = NotificationService();

    test('Reminder frequencies calculate accurate future local trigger times', () {
      final nowTz = tz.TZDateTime(tz.local, 2026, 10, 24, 10, 0);
      // Daily reminder at 21:30
      final dailyReminder = Reminder(
        id: 'rem_daily',
        name: 'Evening review',
        frequency: ReminderFrequency.daily,
        date: DateTime(2026, 10, 24),
        time: const TimeOfDay(hour: 21, minute: 30),
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final nextDaily = notifService.calculateNextTrigger(dailyReminder, nowTz);
      expect(nextDaily.year, 2026);
      expect(nextDaily.month, 10);
      expect(nextDaily.day, 24);
      expect(nextDaily.hour, 21);
      expect(nextDaily.minute, 30);

      // Weekly reminder for Tuesday (weekday 2)
      final weeklyReminder = Reminder(
        id: 'rem_weekly',
        name: 'Weekly check',
        frequency: ReminderFrequency.weekly,
        date: DateTime(2026, 10, 20), // A Tuesday
        time: const TimeOfDay(hour: 9, minute: 0),
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final nextWeekly = notifService.calculateNextTrigger(weeklyReminder, nowTz);
      expect(nextWeekly.weekday, DateTime.tuesday);
      expect(nextWeekly.isAfter(nowTz), isTrue);

      // Monthly reminder on the 31st handles month end without crashing
      final monthlyReminder = Reminder(
        id: 'rem_monthly',
        name: 'Month end bills',
        frequency: ReminderFrequency.monthly,
        date: DateTime(2026, 10, 31),
        time: const TimeOfDay(hour: 18, minute: 0),
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final nextMonthly = notifService.calculateNextTrigger(monthlyReminder, nowTz);
      expect(nextMonthly.day, 31);
      expect(nextMonthly.month, 10);
      expect(nextMonthly.hour, 18);
    });
  });
}
