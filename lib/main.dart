import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/app_database.dart';
import 'core/navigation/navigation_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_drawer.dart';
import 'core/widgets/app_splash_view.dart';
import 'features/accounts/data/repositories/account_repository_impl.dart';
import 'features/accounts/domain/repositories/account_repository.dart';
import 'features/accounts/presentation/providers/account_provider.dart';
import 'features/accounts/presentation/screens/accounts_screen.dart';
import 'features/backup/data/services/backup_service.dart';
import 'features/backup/data/services/excel_export_service.dart';
import 'features/backup/data/services/excel_import_service.dart';
import 'features/backup/data/services/integrity_service.dart';
import 'features/backup/presentation/providers/backup_provider.dart';
import 'features/backup/presentation/providers/excel_import_provider.dart';
import 'features/categories/data/repositories/category_repository_impl.dart';
import 'features/categories/domain/repositories/category_repository.dart';
import 'features/categories/presentation/providers/category_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/recurring/data/repositories/recurring_repository_impl.dart';
import 'features/recurring/domain/repositories/recurring_repository.dart';
import 'features/recurring/domain/services/recurring_processor.dart';
import 'features/recurring/presentation/providers/recurring_provider.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/reminders/data/repositories/reminder_repository.dart';
import 'features/reminders/presentation/providers/reminder_provider.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/presentation/providers/transaction_provider.dart';
import 'features/transactions/presentation/screens/transactions_screen.dart';
import 'features/transfers/data/repositories/transfer_repository_impl.dart';
import 'features/transfers/domain/repositories/transfer_repository.dart';
import 'features/transfers/presentation/providers/transfer_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.initializeFfiIfRequired();
  await NotificationService().initialize();

  // Instantiate Repositories
  final db = AppDatabase.instance;
  final AccountRepository accountRepo = AccountRepositoryImpl(database: db);
  final CategoryRepository categoryRepo = CategoryRepositoryImpl(database: db);
  final TransactionRepository transactionRepo = TransactionRepositoryImpl(database: db);
  final TransferRepository transferRepo = TransferRepositoryImpl(database: db);
  final RecurringRepository recurringRepo = RecurringRepositoryImpl(database: db);
  final ReminderRepository reminderRepo = ReminderRepository(db: db);

  final recurringProcessor = RecurringProcessor(
    database: db,
    recurringRepository: recurringRepo,
  );

  final backupService = BackupService(database: db);
  final integrityService = IntegrityService(database: db);
  final excelExportService = ExcelExportService(
    accountRepository: accountRepo,
    categoryRepository: categoryRepo,
    transactionRepository: transactionRepo,
    transferRepository: transferRepo,
    recurringRepository: recurringRepo,
  );
  final excelImportService = ExcelImportService(database: db);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => AccountProvider(repository: accountRepo)..loadAccounts(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(repository: categoryRepo)..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(repository: transactionRepo)..loadLedger(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferProvider(repository: transferRepo)..loadTransfers(),
        ),
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
}

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: "Kal's Money Manager",
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme(settings.accentColor),
      darkTheme: AppTheme.darkTheme(settings.accentColor),
      home: settings.isLoading
          ? const AppSplashView()
          : (settings.isOnboardingCompleted
              ? const MainNavigationShell()
              : const OnboardingScreen()),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MainNavigationService.currentTabNotifier.addListener(_onTabNotifierChanged);
    // Run idempotent recurring schedule processor on app launch!
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final result = await context.read<RecurringProvider>().processDueTransactions();
        if (result.generatedTransactionsCount > 0 && mounted) {
          context.read<AccountProvider>().loadAccounts();
          context.read<TransactionProvider>().loadLedger();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    MainNavigationService.currentTabNotifier.removeListener(_onTabNotifierChanged);
    super.dispose();
  }

  void _onTabNotifierChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = MainNavigationService.currentTabNotifier.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: MainNavigationService.mainScaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          MainNavigationService.currentTabNotifier.value = idx;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined_rounded),
            selectedIcon: Icon(Icons.insert_chart_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
