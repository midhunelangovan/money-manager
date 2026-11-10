import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/donut_chart.dart';
import '../../../../core/widgets/period_selector.dart';
import '../../../../core/widgets/transaction_type_tabs.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../accounts/presentation/widgets/edit_account_balance_dialog.dart';
import '../../../../core/widgets/export_bottom_sheet.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/category_transactions_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/screens/add_edit_transaction_screen.dart';
import '../../../transactions/presentation/screens/period_transactions_screen.dart';
import '../models/dashboard_filter_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardFilterState? _filterState;
  List<LedgerItem> _periodItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _queryToken = 0;
  int _lastLedgerRevision = -1;
  bool _hasResolvedInitialAccount = false;
  DashboardFocusMode? _lastKnownFocus;
  String? _lastKnownSelectedAccountId;

  @override
  void initState() {
    super.initState();
    MainNavigationService.currentTabNotifier.addListener(_onTabNavigated);
    final settings = context.read<SettingsProvider>();
    final accountProvider = context.read<AccountProvider>();

    _lastKnownFocus = settings.dashboardFocus;
    _lastKnownSelectedAccountId = settings.dashboardSelectedAccountId;

    if (accountProvider.accountsWithBalances.isEmpty && !accountProvider.isLoading) {
      accountProvider.loadAccounts();
    }

    String? initialAccountId;
    switch (settings.dashboardFocus) {
      case DashboardFocusMode.allAccounts:
        initialAccountId = null;
        break;
      case DashboardFocusMode.selectedAccount:
        initialAccountId = settings.dashboardSelectedAccountId ?? settings.primaryAccountId;
        break;
      case DashboardFocusMode.primaryAccount:
        initialAccountId = settings.primaryAccountId ??
            (accountProvider.accountsWithBalances.isNotEmpty
                ? accountProvider.accountsWithBalances.first.account.id
                : null);
        break;
    }

    _hasResolvedInitialAccount = (initialAccountId != null) || (settings.dashboardFocus == DashboardFocusMode.allAccounts);

    final now = DateTime.now();
    _filterState = DashboardFilterState(
      accountId: initialAccountId,
      periodMode: settings.defaultPeriod,
      anchorDate: DateTime(now.year, now.month, now.day),
      tabType: settings.defaultTransactionType,
    );

    _updateFilter(_filterState!);
  }

  @override
  void dispose() {
    MainNavigationService.currentTabNotifier.removeListener(_onTabNavigated);
    super.dispose();
  }

  void _onTabNavigated() {
    if (MainNavigationService.currentTabNotifier.value == 0 && mounted) {
      final txProvider = context.read<TransactionProvider>();
      final settings = context.read<SettingsProvider>();

      final focusChanged = settings.dashboardFocus != _lastKnownFocus ||
          (settings.dashboardFocus == DashboardFocusMode.selectedAccount &&
              settings.dashboardSelectedAccountId != _lastKnownSelectedAccountId);

      if (focusChanged) {
        _lastKnownFocus = settings.dashboardFocus;
        _lastKnownSelectedAccountId = settings.dashboardSelectedAccountId;
        String? targetId;
        switch (settings.dashboardFocus) {
          case DashboardFocusMode.allAccounts:
            targetId = null;
            break;
          case DashboardFocusMode.selectedAccount:
            targetId = settings.dashboardSelectedAccountId ?? settings.primaryAccountId;
            break;
          case DashboardFocusMode.primaryAccount:
            targetId = settings.primaryAccountId;
            break;
        }
        _lastLedgerRevision = txProvider.ledgerRevision;
        if (_filterState != null) {
          _updateFilter(_filterState!.copyWith(accountId: targetId, clearAccountId: targetId == null));
        }
      } else if (txProvider.ledgerRevision != _lastLedgerRevision) {
        _lastLedgerRevision = txProvider.ledgerRevision;
        if (_filterState != null) {
          _updateFilter(_filterState!);
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final txProvider = Provider.of<TransactionProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    // Check if settings changed externally (e.g. from Currency & Accounts Settings screen)
    final focusChanged = settings.dashboardFocus != _lastKnownFocus ||
        (settings.dashboardFocus == DashboardFocusMode.selectedAccount &&
            settings.dashboardSelectedAccountId != _lastKnownSelectedAccountId);

    if (focusChanged) {
      _lastKnownFocus = settings.dashboardFocus;
      _lastKnownSelectedAccountId = settings.dashboardSelectedAccountId;
      String? targetId;
      switch (settings.dashboardFocus) {
        case DashboardFocusMode.allAccounts:
          targetId = null;
          break;
        case DashboardFocusMode.selectedAccount:
          targetId = settings.dashboardSelectedAccountId ?? settings.primaryAccountId;
          break;
        case DashboardFocusMode.primaryAccount:
          targetId = settings.primaryAccountId;
          break;
      }
      _lastLedgerRevision = txProvider.ledgerRevision;
      if (_filterState != null) {
        _updateFilter(_filterState!.copyWith(accountId: targetId, clearAccountId: targetId == null));
        return;
      }
    }

    // Initial or corrected account resolution once accounts are loaded
    if (accountProvider.accountsWithBalances.isNotEmpty) {
      final validAccountIds = accountProvider.accountsWithBalances.map((a) => a.account.id).toSet();

      // If current filter account ID does not exist in active accounts, re-point to valid account
      if (_filterState != null && _filterState!.accountId != null && !validAccountIds.contains(_filterState!.accountId)) {
        String? targetId;
        switch (settings.dashboardFocus) {
          case DashboardFocusMode.allAccounts:
            targetId = null;
            break;
          case DashboardFocusMode.selectedAccount:
          case DashboardFocusMode.primaryAccount:
            targetId = (settings.primaryAccountId != null && validAccountIds.contains(settings.primaryAccountId))
                ? settings.primaryAccountId
                : accountProvider.accountsWithBalances.first.account.id;
            break;
        }
        _hasResolvedInitialAccount = true;
        _lastLedgerRevision = txProvider.ledgerRevision;
        _updateFilter(_filterState!.copyWith(accountId: targetId));
        return;
      }

      if (!_hasResolvedInitialAccount) {
        _hasResolvedInitialAccount = true;
        if (_filterState != null && _filterState!.accountId == null && settings.dashboardFocus != DashboardFocusMode.allAccounts) {
          final targetId = (settings.primaryAccountId != null && validAccountIds.contains(settings.primaryAccountId))
              ? settings.primaryAccountId
              : accountProvider.accountsWithBalances.first.account.id;
          _lastLedgerRevision = txProvider.ledgerRevision;
          _updateFilter(_filterState!.copyWith(accountId: targetId));
          return;
        }
      }
    }

    // React to ledger revisions (transaction add/edit/delete/transfers/import)
    if (txProvider.ledgerRevision != _lastLedgerRevision) {
      _lastLedgerRevision = txProvider.ledgerRevision;
      if (_filterState != null) {
        _updateFilter(_filterState!);
      }
    }
  }

  Future<void> _updateFilter(DashboardFilterState newFilter, {bool isTabOnlyChange = false}) async {
    _filterState = newFilter;

    // If only the expense/income tab changed, filter in-memory immediately without network/db query
    if (isTabOnlyChange) {
      setState(() {});
      return;
    }

    final currentToken = ++_queryToken;
    final targetFilter = newFilter;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final txProvider = context.read<TransactionProvider>();
      final items = await txProvider.repository.getUnifiedLedger(
        accountId: targetFilter.accountId,
        startDate: targetFilter.startDate,
        endDate: targetFilter.endDate,
        exclusiveEndDate: true,
        limit: -1,
        offset: 0,
      );

      // Verify that this query corresponds to the active token (ignore stale out-of-order queries)
      if (!mounted || currentToken != _queryToken) return;

      setState(() {
        _periodItems = items;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted || currentToken != _queryToken) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load dashboard data: $e';
      });
    }
  }

  void _onPreviousPeriod() {
    if (_filterState == null) return;
    _updateFilter(_filterState!.previousPeriod());
  }

  void _onNextPeriod() {
    if (_filterState == null) return;
    _updateFilter(_filterState!.nextPeriod());
  }

  void _onToday() {
    if (_filterState == null) return;
    _updateFilter(_filterState!.toCurrentPeriod());
  }

  void _onPeriodChanged(TimePeriod p) {
    if (_filterState == null) return;
    _updateFilter(_filterState!.copyWith(periodMode: p));
  }

  void _onTabSelected(LedgerTabType t) {
    if (_filterState == null) return;
    _updateFilter(_filterState!.copyWith(tabType: t), isTabOnlyChange: true);
  }

  Future<void> _pickCalendarDate() async {
    if (_filterState == null) return;
    final period = _filterState!.periodMode;

    if (period == TimePeriod.period) {
      final initialRange = _filterState!.customDateRange ??
          DateTimeRange(
            start: DateTime(_filterState!.anchorDate.year, _filterState!.anchorDate.month, 1),
            end: _filterState!.anchorDate,
          );
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange: initialRange,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null && mounted) {
        _updateFilter(_filterState!.copyWith(
          customDateRange: picked,
          anchorDate: picked.start,
        ));
      }
      return;
    }

    if (period == TimePeriod.month) {
      final picked = await MonthPickerDialog.show(context, _filterState!.anchorDate);
      if (picked != null && mounted) {
        _updateFilter(_filterState!.copyWith(
          anchorDate: picked,
        ));
      }
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _filterState!.anchorDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: period == TimePeriod.year ? DatePickerMode.year : DatePickerMode.day,
    );
    if (picked != null && mounted) {
      _updateFilter(_filterState!.copyWith(
        anchorDate: period == TimePeriod.year
            ? DateTime(picked.year, 1, 1)
            : DateTime(picked.year, picked.month, picked.day),
      ));
    }
  }

  Future<void> _openCategoryDrillDown({
    required BuildContext context,
    required String catId,
    required String catName,
    required IconData catIcon,
    required Color catColor,
    required bool isExpenses,
    required DashboardFilterState filter,
    required String displayedAccountName,
    required AccountProvider accountProvider,
    required TransactionProvider txProvider,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryTransactionsScreen(
          categoryId: catId,
          categoryName: catName,
          categoryIcon: catIcon,
          categoryColor: catColor,
          categoryType: isExpenses ? CategoryType.expense : CategoryType.income,
          dateRangeLabel: filter.dateRangeLabel,
          startMillis: filter.startDate.millisecondsSinceEpoch,
          endMillis: filter.endDate.millisecondsSinceEpoch,
          accountId: filter.accountId,
          accountName: displayedAccountName,
        ),
      ),
    );
    await Future.wait([
      accountProvider.loadAccounts(),
      txProvider.loadLedger(),
      _updateFilter(filter),
    ]);
  }


  void _showAccountPicker(BuildContext context, List<AccountWithBalance> accounts, String? activeAccountId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;
        final settings = context.watch<SettingsProvider>();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Select Account Scope',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Divider(color: isDark ? AppColors.darkBorderSubtle : null),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                    child: Icon(Icons.account_balance_wallet_rounded, color: isDark ? primaryColor : AppColors.primary),
                  ),
                  title: Text(
                    'All Accounts',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    Money.fromUnits(accounts.fold<int>(0, (s, a) => s + a.balanceUnits)).format(currency: settings.currency),
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  trailing: activeAccountId == null
                      ? Icon(Icons.check_circle_rounded, color: isDark ? primaryColor : AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    final settings = context.read<SettingsProvider>();
                    _lastKnownFocus = DashboardFocusMode.allAccounts;
                    _lastKnownSelectedAccountId = null;
                    settings.setDashboardFocus(DashboardFocusMode.allAccounts);
                    settings.setDashboardSelectedAccountId(null);
                    if (_filterState != null) {
                      _updateFilter(_filterState!.copyWith(clearAccountId: true));
                    }
                  },
                ),
                ...accounts.map((acc) {
                  final isSelected = acc.account.id == activeAccountId;
                  final color = acc.account.color != null ? Color(acc.account.color!) : (isDark ? primaryColor : AppColors.primary);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(acc.account.iconData, color: color),
                    ),
                    title: Text(
                      acc.account.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      Money.fromUnits(acc.balanceUnits).format(currency: settings.currency),
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: isDark ? primaryColor : AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      final settings = context.read<SettingsProvider>();
                      _lastKnownFocus = DashboardFocusMode.selectedAccount;
                      _lastKnownSelectedAccountId = acc.account.id;
                      settings.setDashboardFocus(DashboardFocusMode.selectedAccount);
                      settings.setDashboardSelectedAccountId(acc.account.id);
                      if (_filterState != null) {
                        _updateFilter(_filterState!.copyWith(accountId: acc.account.id));
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final accounts = accountProvider.accountsWithBalances;

    // Use current filter state or fallback to default
    final filter = _filterState ??
        DashboardFilterState(
          accountId: null,
          periodMode: settings.defaultPeriod,
          anchorDate: DateTime.now(),
          tabType: settings.defaultTransactionType,
        );

    final effectiveAccountId = filter.accountId;
    final period = filter.periodMode;
    final tab = filter.tabType;

    // Header balance calculation
    int displayedBalanceUnits = 0;
    String displayedAccountName = 'All Accounts';

    if (effectiveAccountId == null) {
      displayedBalanceUnits = accountProvider.totalBalance.units;
      displayedAccountName = 'All Accounts';
    } else {
      final found = accounts.where((a) => a.account.id == effectiveAccountId).firstOrNull;
      if (found != null) {
        displayedBalanceUnits = found.balanceUnits;
        displayedAccountName = found.account.name;
      } else if (accounts.isNotEmpty) {
        displayedBalanceUnits = accounts.first.balanceUnits;
        displayedAccountName = accounts.first.account.name;
      }
    }

    final formattedBalance = Money.fromUnits(displayedBalanceUnits).format(currency: settings.currency);

    // Filter period transactions for current tab (Expenses vs Income vs All)
    final isExpenses = tab == LedgerTabType.expenses;
    final tabTransactions = _periodItems.where((tx) {
      if (tab == LedgerTabType.all) {
        return true;
      } else if (isExpenses) {
        return tx.type == LedgerItemType.expense;
      } else {
        return tx.type == LedgerItemType.income;
      }
    }).toList();

    int totalTabUnits = 0;
    final Map<String, int> categoryTotals = {};
    final Map<String, String> categoryNames = {};
    final Map<String, Color> categoryColors = {};
    final Map<String, IconData> categoryIcons = {};

    for (final tx in tabTransactions) {
      // Transfers under All filter do not add to expense/income category totals
      if (tx.type == LedgerItemType.transfer) continue;

      totalTabUnits += tx.amountUnits;
      final catId = tx.categoryId ?? 'other';
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + tx.amountUnits;
      categoryNames[catId] = tx.categoryName ?? 'Other';
      if (tx.categoryColor != null) {
        categoryColors[catId] = Color(tx.categoryColor!);
      } else {
        final cat = catProvider.categories.where((c) => c.id == catId).firstOrNull;
        if (cat != null && cat.color != null) {
          categoryColors[catId] = Color(cat.color!);
        }
      }
      if (tx.categoryIcon != null) {
        final cat = catProvider.categories.where((c) => c.id == catId).firstOrNull;
        if (cat != null) categoryIcons[catId] = cat.iconData;
      }
    }

    final formattedTabTotal = Money.fromUnits(totalTabUnits).format(currency: settings.currency);

    // Build Donut Segments
    final sortedCatIds = categoryTotals.keys.toList()
      ..sort((a, b) => (categoryTotals[b] ?? 0).compareTo(categoryTotals[a] ?? 0));

    final donutSegments = sortedCatIds.map((catId) {
      final val = (categoryTotals[catId] ?? 0).toDouble();
      final pct = totalTabUnits > 0 ? (val / totalTabUnits) : 0.0;
      return DonutSegment(
        categoryId: catId,
        label: categoryNames[catId] ?? 'Other',
        value: val,
        color: categoryColors[catId] ?? (isDark ? primaryColor : AppColors.primary),
        percentage: pct,
        iconData: categoryIcons[catId],
      );
    }).toList();

    final dateSpecificEmptyMessage = period == TimePeriod.day
        ? (isExpenses
            ? 'There were no expenses on this day'
            : (tab == LedgerTabType.all
                ? 'There were no transactions on this day'
                : 'There was no income on this day'))
        : period == TimePeriod.week
            ? (isExpenses
                ? 'There were no expenses in this week'
                : (tab == LedgerTabType.all
                    ? 'There were no transactions in this week'
                    : 'There was no income in this week'))
            : period == TimePeriod.month
                ? (isExpenses
                    ? 'There were no expenses in this month'
                    : (tab == LedgerTabType.all
                        ? 'There were no transactions in this month'
                        : 'There was no income in this month'))
                : period == TimePeriod.year
                    ? (isExpenses
                        ? 'There were no expenses in this year'
                        : (tab == LedgerTabType.all
                            ? 'There were no transactions in this year'
                            : 'There was no income in this year'))
                    : (isExpenses
                        ? 'There were no expenses in this period'
                        : (tab == LedgerTabType.all
                            ? 'There were no transactions in this period'
                            : 'There was no income in this period'));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // 1. Top Header with Brand Primary, Hamburger Menu, Account Switcher, Balance, and EXPENSES/INCOME tabs
          AppHeader(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              left: 16,
              right: 16,
              bottom: 26,
            ),
            showBackButton: false,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Navigation Menu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () {
                MainNavigationService.openDrawer();
              },
            ),
            titleWidget: GestureDetector(
              onTap: () => _showAccountPicker(context, accounts, effectiveAccountId),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      displayedAccountName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_rounded, color: Colors.white, size: 24),
                tooltip: 'Export',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  ExportBottomSheet.show(
                    context,
                    periodMode: filter.periodMode,
                    anchorDate: filter.anchorDate,
                    customDateRange: filter.customDateRange,
                    accountId: filter.accountId,
                    accountName: displayedAccountName,
                    typeFilter: filter.tabType == LedgerTabType.expenses
                        ? LedgerItemType.expense
                        : (filter.tabType == LedgerTabType.income
                            ? LedgerItemType.income
                            : null),
                  );
                },
              ),
            ],
            bottom: Column(
              children: [
                const SizedBox(height: 2),
                // Prominent Financial Amount with optically centered Edit Icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          formattedBalance,
                          style: AppTypography.displayLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Compact circular touch target edit button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (effectiveAccountId != null) {
                              final targetAcc = accounts.where((a) => a.account.id == effectiveAccountId).firstOrNull;
                              if (targetAcc != null) {
                                EditAccountBalanceDialog.show(context, targetAcc);
                                return;
                              }
                            }
                            if (accounts.length == 1) {
                              EditAccountBalanceDialog.show(context, accounts.first);
                              return;
                            }
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (ctx) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                        child: Text(
                                          'Select Account to Edit Balance',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                      Divider(color: isDark ? AppColors.darkBorderSubtle : null),
                                      ...accounts.map((accItem) => ListTile(
                                        leading: Icon(accItem.account.iconData, color: Color(accItem.account.color ?? (isDark ? primaryColor.toARGB32() : AppColors.primary.toARGB32()))),
                                        title: Text(
                                          accItem.account.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          accItem.calculatedBalance.format(currency: settings.currency),
                                          style: TextStyle(
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        trailing: const Icon(Icons.edit_rounded, size: 20),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          EditAccountBalanceDialog.show(context, accItem);
                                        },
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // EXPENSES / INCOME Tabs with active white underline
                TransactionTypeTabs(
                  selectedTab: tab,
                  onTabSelected: _onTabSelected,
                  isHeaderStyle: true,
                ),
              ],
            ),
          ),

          // 2. Focused Main Content Body: Overlapping White Dashboard Panel
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          accountProvider.loadAccounts(),
                          txProvider.loadLedger(),
                          if (_filterState != null) _updateFilter(_filterState!),
                        ]);
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Period Selector (Day | Week | Month | Year | Period)
                                  PeriodSelector(
                                    selectedPeriod: period,
                                    onPeriodChanged: _onPeriodChanged,
                                    dateRangeLabel: filter.dateRangeLabel,
                                    onPrevious: _onPreviousPeriod,
                                    onNext: _onNextPeriod,
                                    onTapDate: _pickCalendarDate,
                                    onToday: _onToday,
                                    canJumpToToday: !filter.isCurrentPeriod(),
                                  ),

                                  // Subtle Loading Progress Indicator
                                  if (_isLoading) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        minHeight: 2.5,
                                        backgroundColor: Colors.transparent,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? AppColors.darkPrimary : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ] else ...[
                                    const SizedBox(height: 18),
                                  ],

                                  // Error State Banner if query failed
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(color: Colors.red, fontSize: 12),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _updateFilter(filter),
                                            child: const Text('Retry', style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Centered Large Donut Chart with Category Tap Drill-Down
                                  Center(
                                    child: DonutChart(
                                      segments: donutSegments,
                                      centerAmount: formattedTabTotal,
                                      centerLabel: isExpenses ? 'EXPENSES' : (tab == LedgerTabType.all ? 'TOTAL' : 'INCOME'),
                                      size: 230,
                                      strokeWidth: 24,
                                      isLoading: _isLoading,
                                      isEmpty: tabTransactions.isEmpty,
                                      emptyMessage: dateSpecificEmptyMessage,
                                      onCenterTapped: () async {
                                        if (tabTransactions.isEmpty) return;
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PeriodTransactionsScreen(
                                              title: isExpenses
                                                  ? 'Expenses'
                                                  : (tab == LedgerTabType.all ? 'All Transactions' : 'Income'),
                                              dateRangeLabel: filter.dateRangeLabel,
                                              startMillis: filter.startDate.millisecondsSinceEpoch,
                                              endMillis: filter.endDate.millisecondsSinceEpoch,
                                              accountId: filter.accountId,
                                              accountName: displayedAccountName,
                                              typeFilter: isExpenses
                                                  ? LedgerItemType.expense
                                                  : (tab == LedgerTabType.income
                                                      ? LedgerItemType.income
                                                      : null),
                                            ),
                                          ),
                                        );
                                        await Future.wait([
                                          accountProvider.loadAccounts(),
                                          txProvider.loadLedger(),
                                          _updateFilter(filter),
                                        ]);
                                      },
                                      onSegmentTapped: (segment) {
                                        final catId = segment.categoryId;
                                        if (catId == null) return;
                                        _openCategoryDrillDown(
                                          context: context,
                                          catId: catId,
                                          catName: segment.label,
                                          catIcon: segment.iconData ?? (categoryIcons[catId] ?? Icons.category_rounded),
                                          catColor: segment.color,
                                          isExpenses: isExpenses,
                                          filter: filter,
                                          displayedAccountName: displayedAccountName,
                                          accountProvider: accountProvider,
                                          txProvider: txProvider,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),

                          // Circular Yellow Add Button positioned inside the panel at bottom-right
                          Positioned(
                            bottom: 14,
                            right: 14,
                            child: Material(
                              color: AppColors.floatingAction,
                              shape: const CircleBorder(),
                              elevation: 4,
                              shadowColor: Colors.black26,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () async {
                                  final changed = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddEditTransactionScreen(
                                        initialMode: tab == LedgerTabType.expenses
                                            ? EntryMode.expense
                                            : EntryMode.income,
                                        initialAccountId: effectiveAccountId ?? settings.primaryAccountId,
                                        initialDate: filter.anchorDate,
                                      ),
                                    ),
                                  );
                                  if (changed == true) {
                                    await Future.wait([
                                      accountProvider.loadAccounts(),
                                      txProvider.loadLedger(),
                                      if (_filterState != null) _updateFilter(_filterState!),
                                    ]);
                                  }
                                },
                                child: const SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 32,
                                    color: Color(0xFF1B1E24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
