import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/donut_chart.dart';
import '../../../../core/widgets/period_selector.dart';
import '../../../../core/widgets/transaction_type_tabs.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../accounts/presentation/widgets/edit_account_balance_dialog.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/category_transactions_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/screens/add_edit_transaction_screen.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  LedgerTabType? _selectedTab;
  TimePeriod? _selectedPeriod;
  late DateTime _selectedHomeDate;
  String? _sessionAccountId; // null means follow settings, '__ALL__' means all, or specific ID

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedHomeDate = DateTime(now.year, now.month, now.day);
  }

  TimePeriod _effectivePeriod(SettingsProvider settings) {
    return _selectedPeriod ?? settings.defaultPeriod;
  }

  LedgerTabType _effectiveTab(SettingsProvider settings) {
    return _selectedTab ?? settings.defaultTransactionType;
  }

  // Accurate Date Range calculation for selected period using LOCAL boundaries [start, end)
  DateTime _periodStartDate(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return DateTime(_selectedHomeDate.year, _selectedHomeDate.month, _selectedHomeDate.day, 0, 0, 0, 0);
      case TimePeriod.week:
        return _selectedHomeDate.startOfWeek;
      case TimePeriod.month:
        return DateTime(_selectedHomeDate.year, _selectedHomeDate.month, 1, 0, 0, 0, 0);
      case TimePeriod.year:
        return DateTime(_selectedHomeDate.year, 1, 1, 0, 0, 0, 0);
      case TimePeriod.period:
        return DateTime(_selectedHomeDate.year, _selectedHomeDate.month, 1, 0, 0, 0, 0);
    }
  }

  DateTime _periodEndDate(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return DateTime(_selectedHomeDate.year, _selectedHomeDate.month, _selectedHomeDate.day + 1, 0, 0, 0, 0);
      case TimePeriod.week:
        return _selectedHomeDate.startOfWeek.add(const Duration(days: 7));
      case TimePeriod.month:
        return DateTime(_selectedHomeDate.year, _selectedHomeDate.month + 1, 1, 0, 0, 0, 0);
      case TimePeriod.year:
        return DateTime(_selectedHomeDate.year + 1, 1, 1, 0, 0, 0, 0);
      case TimePeriod.period:
        return DateTime(_selectedHomeDate.year, _selectedHomeDate.month + 1, 1, 0, 0, 0, 0);
    }
  }

  String _periodLabel(TimePeriod period) {
    final start = _periodStartDate(period);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    switch (period) {
      case TimePeriod.day:
        final dayName = daysOfWeek[_selectedHomeDate.weekday - 1];
        return '${_selectedHomeDate.day.toString().padLeft(2, '0')} ${months[_selectedHomeDate.month - 1]} ${_selectedHomeDate.year} ($dayName)';
      case TimePeriod.week:
        final end = start.add(const Duration(days: 6));
        return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]} ${end.year}';
      case TimePeriod.month:
        return '${months[_selectedHomeDate.month - 1]} ${_selectedHomeDate.year}';
      case TimePeriod.year:
        return '${_selectedHomeDate.year}';
      case TimePeriod.period:
        return '${months[_selectedHomeDate.month - 1]} ${_selectedHomeDate.year}';
    }
  }

  void _onPreviousPeriod(TimePeriod period) {
    setState(() {
      switch (period) {
        case TimePeriod.day:
          _selectedHomeDate = _selectedHomeDate.subtract(const Duration(days: 1));
          break;
        case TimePeriod.week:
          _selectedHomeDate = _selectedHomeDate.subtract(const Duration(days: 7));
          break;
        case TimePeriod.month:
        case TimePeriod.period:
          _selectedHomeDate = DateTime(_selectedHomeDate.year, _selectedHomeDate.month - 1, _selectedHomeDate.day.clamp(1, 28));
          break;
        case TimePeriod.year:
          _selectedHomeDate = DateTime(_selectedHomeDate.year - 1, _selectedHomeDate.month, _selectedHomeDate.day.clamp(1, 28));
          break;
      }
    });
  }

  void _onNextPeriod(TimePeriod period) {
    setState(() {
      switch (period) {
        case TimePeriod.day:
          _selectedHomeDate = _selectedHomeDate.add(const Duration(days: 1));
          break;
        case TimePeriod.week:
          _selectedHomeDate = _selectedHomeDate.add(const Duration(days: 7));
          break;
        case TimePeriod.month:
        case TimePeriod.period:
          _selectedHomeDate = DateTime(_selectedHomeDate.year, _selectedHomeDate.month + 1, _selectedHomeDate.day.clamp(1, 28));
          break;
        case TimePeriod.year:
          _selectedHomeDate = DateTime(_selectedHomeDate.year + 1, _selectedHomeDate.month, _selectedHomeDate.day.clamp(1, 28));
          break;
      }
    });
  }

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedHomeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedHomeDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _onToday() {
    final now = DateTime.now();
    setState(() {
      _selectedHomeDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _showAccountPicker(BuildContext context, List<AccountWithBalance> accounts, String? activeAccountId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
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
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _sessionAccountId = '__ALL__');
                    Navigator.pop(ctx);
                  },
                ),
                ...accounts.map((acc) {
                  final isSelected = acc.account.id == activeAccountId;
                  final color = acc.account.color != null ? Color(acc.account.color!) : AppColors.primary;

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
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _sessionAccountId = acc.account.id);
                      Navigator.pop(ctx);
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

    final accounts = accountProvider.accountsWithBalances;
    final period = _effectivePeriod(settings);
    final tab = _effectiveTab(settings);

    final now = DateTime.now();
    final isSelectedToday = _selectedHomeDate.year == now.year &&
        _selectedHomeDate.month == now.month &&
        _selectedHomeDate.day == now.day;

    // Determine Active Account Scope
    String? effectiveAccountId;
    if (_sessionAccountId == '__ALL__') {
      effectiveAccountId = null; // All accounts
    } else if (_sessionAccountId != null) {
      effectiveAccountId = _sessionAccountId;
    } else {
      // Follow Settings
      switch (settings.dashboardFocus) {
        case DashboardFocusMode.allAccounts:
          effectiveAccountId = null;
          break;
        case DashboardFocusMode.selectedAccount:
          effectiveAccountId = settings.dashboardSelectedAccountId ?? settings.primaryAccountId;
          break;
        case DashboardFocusMode.primaryAccount:
          effectiveAccountId = settings.primaryAccountId ?? (accounts.isNotEmpty ? accounts.first.account.id : null);
          break;
      }
    }

    // Header balance
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

    // Filter transactions for the selected local period & account [start, end)
    final startMillis = _periodStartDate(period).millisecondsSinceEpoch;
    final endMillis = _periodEndDate(period).millisecondsSinceEpoch;

    final sourceItems = txProvider.allLedgerItems.isNotEmpty
        ? txProvider.allLedgerItems
        : txProvider.ledgerItems;

    final periodTransactions = sourceItems.where((tx) {
      final txMillis = tx.date.millisecondsSinceEpoch;
      final inDate = txMillis >= startMillis && txMillis < endMillis;
      if (!inDate) return false;
      if (effectiveAccountId != null) {
        if (tx.type == LedgerItemType.transfer) {
          return tx.accountId == effectiveAccountId || tx.destinationAccountId == effectiveAccountId;
        }
        return tx.accountId == effectiveAccountId;
      }
      return true;
    }).toList();

    // Tab-filtered transactions (Expenses vs Income)
    final isExpenses = tab == LedgerTabType.expenses;
    final tabTransactions = periodTransactions.where((tx) {
      if (isExpenses) {
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
        label: categoryNames[catId] ?? 'Other',
        value: val,
        color: categoryColors[catId] ?? AppColors.primary,
        percentage: pct,
      );
    }).toList();

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateSpecificEmptyMessage = period == TimePeriod.day
        ? (isExpenses
            ? 'There were\nno expenses on\n${_selectedHomeDate.day} ${months[_selectedHomeDate.month - 1]} ${_selectedHomeDate.year}'
            : 'There was\nno income on\n${_selectedHomeDate.day} ${months[_selectedHomeDate.month - 1]} ${_selectedHomeDate.year}')
        : (isExpenses
            ? 'There were\nno expenses\nin this ${period.displayName.toLowerCase()}'
            : 'There was\nno income\nin this ${period.displayName.toLowerCase()}');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // 1. Top Header with Hamburger Menu, Account Switcher, Balance, and EXPENSES/INCOME tabs
          AppHeader(
            showBackButton: false,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              tooltip: 'Navigation Menu',
              onPressed: () {
                MainNavigationService.openDrawer();
              },
            ),
            titleWidget: GestureDetector(
              onTap: () => _showAccountPicker(context, accounts, effectiveAccountId),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        displayedAccountName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                tooltip: 'Search Transactions',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                  );
                },
              ),
            ],
            bottom: Column(
              children: [
                const SizedBox(height: 6),
                // Prominent Financial Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedBalance,
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
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
                        // If All Accounts selected, prompt user to select account to edit balance
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
                                    leading: Icon(accItem.account.iconData, color: Color(accItem.account.color ?? AppColors.primary.toARGB32())),
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
                                    trailing: const Icon(Icons.edit_outlined, size: 20),
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
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // EXPENSES / INCOME Tabs with active white underline
                TransactionTypeTabs(
                  selectedTab: tab,
                  onTabSelected: (t) => setState(() => _selectedTab = t),
                  isHeaderStyle: true,
                ),
              ],
            ),
          ),

          // 2. Focused Main Content Body (Panel + Donut Chart + Category Breakdown Cards)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  accountProvider.loadAccounts(),
                  txProvider.loadLedger(),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // Main Visualization Panel (Period Selector + Date Navigation + Donut Chart)
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      children: [
                        // Period Selector (Day | Week | Month | Year | Period) with direct calendar tap
                        PeriodSelector(
                          selectedPeriod: period,
                          onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
                          dateRangeLabel: _periodLabel(period),
                          onPrevious: () => _onPreviousPeriod(period),
                          onNext: () => _onNextPeriod(period),
                          onTapDate: _pickCalendarDate,
                          onToday: _onToday,
                          isToday: isSelectedToday,
                        ),

                        const SizedBox(height: 20),

                        // Donut Chart
                        DonutChart(
                          segments: donutSegments,
                          centerAmount: formattedTabTotal,
                          centerLabel: isExpenses ? 'EXPENSES' : 'INCOME',
                          size: 210,
                          strokeWidth: 20,
                          isEmpty: tabTransactions.isEmpty,
                          emptyMessage: dateSpecificEmptyMessage,
                        ),
                      ],
                    ),
                  ),

                  // Category Breakdown Cards List (Tappable for granular transaction details)
                  if (sortedCatIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...sortedCatIds.map((catId) {
                      final catUnits = categoryTotals[catId] ?? 0;
                      final catName = categoryNames[catId] ?? 'Category';
                      final catColor = categoryColors[catId] ?? AppColors.primary;
                      final catIcon = categoryIcons[catId] ?? Icons.category_rounded;
                      final percentage = totalTabUnits > 0 ? (catUnits / totalTabUnits * 100).round() : 0;
                      final formattedCatAmount = Money.fromUnits(catUnits).format(currency: settings.currency);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CategoryTransactionsScreen(
                                    categoryId: catId,
                                    categoryName: catName,
                                    categoryIcon: catIcon,
                                    categoryColor: catColor,
                                    categoryType: isExpenses ? CategoryType.expense : CategoryType.income,
                                    dateRangeLabel: _periodLabel(period),
                                    startMillis: startMillis,
                                    endMillis: endMillis,
                                    accountId: effectiveAccountId,
                                    accountName: displayedAccountName,
                                  ),
                                ),
                              );
                              await Future.wait([
                                accountProvider.loadAccounts(),
                                txProvider.loadLedger(),
                              ]);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1),
                                    ),
                                    child: Icon(catIcon, color: catColor, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      catName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$percentage%',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    formattedCatAmount,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isExpenses ? AppColors.expense : AppColors.income,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 80), // Clean bottom space for floating + action
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. Floating Add Action Button (Warm Yellow/Amber circular +)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditTransactionScreen(
                initialMode: tab == LedgerTabType.expenses
                    ? EntryMode.expense
                    : EntryMode.income,
                initialAccountId: effectiveAccountId ?? settings.defaultTransactionAccountId ?? settings.primaryAccountId,
                initialDate: _selectedHomeDate,
              ),
            ),
          );
          if (changed == true) {
            await Future.wait([
              accountProvider.loadAccounts(),
              txProvider.loadLedger(),
            ]);
          }
        },
        backgroundColor: AppColors.accentYellow,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}
