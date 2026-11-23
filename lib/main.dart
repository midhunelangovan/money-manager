import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/database/app_database.dart';
import 'core/navigation/navigation_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utilities/app_logger.dart';
import 'core/widgets/app_drawer.dart';
import 'core/widgets/app_splash_view.dart';
import 'features/accounts/data/repositories/account_repository_impl.dart';
import 'features/accounts/domain/repositories/account_repository.dart';
import 'features/accounts/presentation/providers/account_provider.dart';
import 'features/accounts/presentation/screens/accounts_screen.dart';
import 'features/backup/data/services/auto_export_background_scheduler.dart';
import 'features/backup/data/services/automatic_export_service.dart';
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
import 'features/reminders/data/repositories/reminder_repository.dart';
import 'features/reminders/presentation/providers/reminder_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/presentation/providers/transaction_provider.dart';
import 'features/transactions/presentation/screens/transactions_screen.dart';
import 'features/transfers/data/repositories/transfer_repository_impl.dart';
import 'features/transfers/domain/repositories/transfer_repository.dart';
import 'features/transfers/presentation/providers/transfer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Diagnostics and graceful error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('FlutterError', details.exceptionAsString(), details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformDispatcher', error.toString(), error, stack);
    return true;
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Something unexpected occurred',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'A view encountered an issue. Tap below to return safely.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final nav = MainNavigationService.navigatorKey.currentState;
                  if (nav != null && nav.canPop()) {
                    nav.pop();
                  } else if (MainNavigationService.navigatorKey.currentContext != null) {
                    MainNavigationService.navigateToTab(
                      MainNavigationService.navigatorKey.currentContext!,
                      0,
                    );
                  }
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  AppDatabase.initializeFfiIfRequired();
  await NotificationService().initialize();
  await AutoExportBackgroundScheduler.initialize();
  WidgetService.initialize();

  // Instantiate Repositories
  final db = AppDatabase.instance;
  final settingsProvider = SettingsProvider(database: db);
  await settingsProvider.loadSettings();

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
  final automaticExportService = AutomaticExportService(
    database: db,
    backupService: backupService,
    excelExportService: excelExportService,
  );
  // Reconcile automatic export scheduling and catch up any missed exports
  automaticExportService.reconcileAndCatchUpIfDue().catchError((e) {
    AppLogger.log('KALS_AUTO_EXPORT', 'Startup reconciliation failed: $e');
    return false;
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
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
          )..loadRecurring(rescheduleReminders: true),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderProvider(
            repository: reminderRepo,
          )..loadReminders(rescheduleAlarms: true),
        ),
        ChangeNotifierProvider(
          create: (_) => BackupProvider(
            backupService: backupService,
            excelExportService: excelExportService,
            integrityService: integrityService,
            automaticExportService: automaticExportService,
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
      navigatorKey: MainNavigationService.navigatorKey,
      navigatorObservers: [AppNavigationObserver()],
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme(settings.accentColor, settings.isMinimalMode),
      darkTheme: AppTheme.darkTheme(settings.accentColor, settings.isMinimalMode),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return child;
      },
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
  ];

  @override
  void initState() {
    super.initState();
    MainNavigationService.currentTabNotifier.addListener(_onTabNotifierChanged);
    // Run idempotent recurring schedule processor on app launch!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final recurring = Provider.of<RecurringProvider?>(context, listen: false);
        recurring?.processDueTransactions().then((result) {
          if (result.generatedTransactionsCount > 0 && mounted) {
            context.read<AccountProvider>().loadAccounts();
            context.read<TransactionProvider>().loadLedger();
          }
        }).catchError((_) {});
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
    final currentIndex = MainNavigationService.currentTabNotifier.value.clamp(0, _screens.length - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        AppLogger.log('KALS_TXN_NAV', 'MainNavigationShell root PopScope invoked: didPop=$didPop');
        if (didPop) return;
        // User pressed Android Back at root shell. Allow Android to background/exit the app cleanly
        // via platform channel without destroying Flutter root Route and leaving a zero-route black screen.
        SystemNavigator.pop();
      },
      child: Scaffold(
        key: MainNavigationService.mainScaffoldKey,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ),
      ),
    );
  }
}
