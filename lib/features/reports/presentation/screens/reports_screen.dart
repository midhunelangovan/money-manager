import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_category_icons.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/donut_chart.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/export_action_dialog.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import 'category_report_detail_screen.dart';

enum ReportTypeFilter {
  all,
  expenses,
  income;

  String get displayName {
    switch (this) {
      case ReportTypeFilter.all:
        return 'All';
      case ReportTypeFilter.expenses:
        return 'Expenses';
      case ReportTypeFilter.income:
        return 'Income';
    }
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DateTime _selectedMonth;
  ReportTypeFilter _typeFilter = ReportTypeFilter.expenses;
  String? _selectedAccountId; // null means All Accounts
  List<LedgerItem> _monthItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _queryVersion = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthData();
    });
  }

  Future<void> _loadMonthData() async {
    final currentVersion = ++_queryVersion;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Boundaries: [startDate, endDate) using exclusive end boundary
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1, 0, 0, 0, 0);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1, 0, 0, 0, 0);

      final txProvider = context.read<TransactionProvider>();
      final items = await txProvider.getItemsForRange(
        startDate: startDate,
        endDate: endDate,
        exclusiveEndDate: true,
        accountId: _selectedAccountId,
      );

      if (currentVersion == _queryVersion && mounted) {
        setState(() {
          _monthItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (currentVersion == _queryVersion && mounted) {
        setState(() {
          _errorMessage = 'Unable to load analytics for ${DateFormatter.formatMonthYear(_selectedMonth)}: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      _loadMonthData();
    }
  }

  void _onPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    _loadMonthData();
  }

  void _onNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
    _loadMonthData();
  }

  void _openCategoryDrillDown({
    required String categoryId,
    required String categoryName,
    required IconData categoryIcon,
    required Color categoryColor,
    required String? accountName,
  }) {
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final monthTitle = DateFormatter.formatMonthYear(_selectedMonth);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryReportDetailScreen(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          startDate: startDate,
          endDate: endDate,
          periodTitle: monthTitle,
          accountId: _selectedAccountId,
          accountName: _selectedAccountId != null ? accountName : null,
        ),
      ),
    );
  }

  void _showAccountPicker(BuildContext context, List<AccountWithBalance> accounts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? Theme.of(context).colorScheme.primary : AppColors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                    'Filter Analytics by Account',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Divider(color: isDark ? AppColors.darkBorderSubtle : null),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                    child: Icon(Icons.account_balance_wallet_rounded, color: primaryAccent),
                  ),
                  title: Text(
                    'All Accounts',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  trailing: _selectedAccountId == null
                      ? Icon(Icons.check_circle_rounded, color: primaryAccent)
                      : null,
                  onTap: () {
                    setState(() => _selectedAccountId = null);
                    Navigator.pop(ctx);
                    _loadMonthData();
                  },
                ),
                ...accounts.map((acc) {
                  final isSelected = acc.account.id == _selectedAccountId;
                  final color = acc.account.color != null ? Color(acc.account.color!) : primaryAccent;

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
                        ? Icon(Icons.check_circle_rounded, color: primaryAccent)
                        : null,
                    onTap: () {
                      setState(() => _selectedAccountId = acc.account.id);
                      Navigator.pop(ctx);
                      _loadMonthData();
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
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    final accounts = accountProvider.accountsWithBalances;
    String selectedAccountName = 'All Accounts';
    if (_selectedAccountId != null) {
      final found = accounts.where((a) => a.account.id == _selectedAccountId).firstOrNull;
      if (found != null) {
        selectedAccountName = found.account.name;
      }
    }

    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1, 0, 0, 0, 0);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1, 0, 0, 0, 0);

    // Calculate metric aggregates
    int totalIncomeUnits = 0;
    int totalExpenseUnits = 0;
    int expenseCount = 0;
    int incomeCount = 0;
    int transferCount = 0;
    final Map<String, int> categoryUnits = {};
    final Map<String, String> categoryNames = {};
    final Map<String, Color> categoryColors = {};
    final Map<String, IconData> categoryIcons = {};

    for (final item in _monthItems) {
      if (item.type == LedgerItemType.income) {
        totalIncomeUnits += item.amountUnits;
        incomeCount++;
        if (_typeFilter == ReportTypeFilter.income || _typeFilter == ReportTypeFilter.all) {
          final catId = item.categoryId ?? 'other_income';
          categoryUnits[catId] = (categoryUnits[catId] ?? 0) + item.amountUnits;
          categoryNames[catId] = item.categoryName ?? 'Income';
          if (item.categoryColor != null) {
            categoryColors[catId] = Color(item.categoryColor!);
          }
          if (item.categoryIcon != null) {
            categoryIcons[catId] = AppCategoryIcons.getIconData(item.categoryIcon);
          }
        }
      } else if (item.type == LedgerItemType.expense) {
        totalExpenseUnits += item.amountUnits;
        expenseCount++;
        if (_typeFilter == ReportTypeFilter.expenses || _typeFilter == ReportTypeFilter.all) {
          final catId = item.categoryId ?? 'other_expense';
          categoryUnits[catId] = (categoryUnits[catId] ?? 0) + item.amountUnits;
          categoryNames[catId] = item.categoryName ?? 'Expense';
          if (item.categoryColor != null) {
            categoryColors[catId] = Color(item.categoryColor!);
          }
          if (item.categoryIcon != null) {
            categoryIcons[catId] = AppCategoryIcons.getIconData(item.categoryIcon);
          }
        }
      } else if (item.type == LedgerItemType.transfer) {
        transferCount++;
      }
    }

    final incomeMoney = Money.fromUnits(totalIncomeUnits);
    final expenseMoney = Money.fromUnits(totalExpenseUnits);
    final netSavingsMoney = Money.fromUnits(totalIncomeUnits - totalExpenseUnits);

    int displayTotalUnits = 0;
    String displayTotalLabel = 'Total Expenses';
    if (_typeFilter == ReportTypeFilter.expenses) {
      displayTotalUnits = totalExpenseUnits;
      displayTotalLabel = 'Total Expenses';
    } else if (_typeFilter == ReportTypeFilter.income) {
      displayTotalUnits = totalIncomeUnits;
      displayTotalLabel = 'Total Income';
    } else {
      displayTotalUnits = totalExpenseUnits + totalIncomeUnits;
      displayTotalLabel = 'Total Volume';
    }
    final displayTotalMoney = Money.fromUnits(displayTotalUnits);

    final sortedCategories = categoryUnits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare Donut Segments for Clickable Chart
    final List<DonutSegment> donutSegments = [];
    if (displayTotalUnits > 0) {
      for (final entry in sortedCategories) {
        final catName = categoryNames[entry.key] ?? 'Category';
        final color = categoryColors[entry.key] ?? AppColors.primary;
        final icon = categoryIcons[entry.key] ?? Icons.category_rounded;
        final percentage = (entry.value / displayTotalUnits);

        donutSegments.add(DonutSegment(
          categoryId: entry.key,
          label: catName,
          value: entry.value.toDouble(),
          color: color,
          percentage: percentage,
          iconData: icon,
        ));
      }
    }

    final monthTitle = DateFormatter.formatMonthYear(_selectedMonth);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // App Header
          AppHeader(
            showBackButton: false,
            leading: IconButton(
              icon: Icon(
                canPop ? Icons.arrow_back_rounded : Icons.menu_rounded,
                color: Colors.white,
                size: 26,
              ),
              tooltip: canPop ? 'Back' : 'Navigation Menu',
              onPressed: () {
                if (canPop) {
                  Navigator.pop(context);
                } else {
                  MainNavigationService.openDrawer();
                }
              },
            ),
            titleWidget: GestureDetector(
              onTap: () => _showAccountPicker(context, accounts),
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
                        selectedAccountName,
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
                icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                tooltip: 'Export Report to Excel',
                onPressed: () {
                  ExportActionDialog.show(
                    context,
                    initialStartDate: startDate,
                    initialEndDate: endDate.subtract(const Duration(milliseconds: 1)),
                  );
                },
              ),
            ],
            bottom: Column(
              children: [
                // Month Navigation: < January 2026 >
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                      tooltip: 'Previous Month',
                      onPressed: _onPreviousMonth,
                    ),
                    InkWell(
                      onTap: _pickMonthYear,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              monthTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                      tooltip: 'Next Month',
                      onPressed: _onNextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Compact Report Type Filter: [ All ] [ Expenses ] [ Income ]
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip(ReportTypeFilter.all),
                      _buildFilterChip(ReportTypeFilter.expenses),
                      _buildFilterChip(ReportTypeFilter.income),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Body
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading $monthTitle analytics...',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : (_errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: AppColors.expense),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry'),
                                onPressed: _loadMonthData,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMonthData,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          children: [
                            // 3 Metric Cards: Income, Expense, Net Savings
                            Row(
                              children: [
                                Expanded(
                                  child: AppCard(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('INCOME', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.income)),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            incomeMoney.format(currency: settings.currency),
                                            style: AppTypography.amountSmall.copyWith(
                                              color: AppColors.income,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AppCard(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('EXPENSES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.expense)),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            expenseMoney.format(currency: settings.currency),
                                            style: AppTypography.amountSmall.copyWith(
                                              color: AppColors.expense,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AppCard(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('SAVINGS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            netSavingsMoney.format(currency: settings.currency),
                                            style: AppTypography.amountSmall.copyWith(
                                              color: netSavingsMoney.amountUnits >= 0 ? AppColors.primary : AppColors.expense,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Monthly Activity Summary Card (Counts)
                            AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryCountItem('Total Records', '${_monthItems.length}', AppColors.primary),
                                  _buildSummaryCountItem('Expenses', '$expenseCount', AppColors.expense),
                                  _buildSummaryCountItem('Income', '$incomeCount', AppColors.income),
                                  _buildSummaryCountItem('Transfers', '$transferCount', AppColors.transfer),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Clickable Donut Chart Card
                            AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              child: Column(
                                children: [
                                  Text(
                                    displayTotalLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  DonutChart(
                                    segments: donutSegments,
                                    centerAmount: displayTotalMoney.format(currency: settings.currency),
                                    centerLabel: _typeFilter.displayName,
                                    size: 190,
                                    strokeWidth: 22,
                                    isEmpty: donutSegments.isEmpty,
                                    emptyMessage: 'No ${_typeFilter.displayName.toLowerCase()} recorded for $monthTitle',
                                    onSegmentTapped: (seg) {
                                      if (seg.categoryId != null) {
                                        _openCategoryDrillDown(
                                          categoryId: seg.categoryId!,
                                          categoryName: seg.label,
                                          categoryIcon: seg.iconData ?? Icons.category_rounded,
                                          categoryColor: seg.color,
                                          accountName: selectedAccountName,
                                        );
                                      }
                                    },
                                  ),
                                  if (donutSegments.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap any segment to view transactions',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Category Breakdown List (Clickable for drill-down)
                            AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_typeFilter.displayName.toUpperCase()} BREAKDOWN',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '${sortedCategories.length} Categories',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (sortedCategories.isEmpty)
                                    EmptyState(
                                      icon: Icons.pie_chart_outline_rounded,
                                      title: 'No ${_typeFilter.displayName} in $monthTitle',
                                      subtitle: 'There are no ${_typeFilter.displayName.toLowerCase()} records recorded for this calendar month.',
                                    )
                                  else
                                    ...sortedCategories.map((entry) {
                                      final catName = categoryNames[entry.key] ?? 'Category';
                                      final amount = Money.fromUnits(entry.value);
                                      final catColor = categoryColors[entry.key] ?? AppColors.primary;
                                      final catIcon = categoryIcons[entry.key] ?? Icons.category_rounded;
                                      final percentage = displayTotalUnits > 0
                                          ? (entry.value / displayTotalUnits)
                                          : 0.0;

                                      return InkWell(
                                        onTap: () {
                                          _openCategoryDrillDown(
                                            categoryId: entry.key,
                                            categoryName: catName,
                                            categoryIcon: catIcon,
                                            categoryColor: catColor,
                                            accountName: selectedAccountName,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 26,
                                                        height: 26,
                                                        decoration: BoxDecoration(
                                                          color: catColor.withValues(alpha: 0.15),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(catIcon, color: catColor, size: 14),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        catName,
                                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${amount.format(currency: settings.currency)} (${(percentage * 100).toStringAsFixed(1)}%)',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.chevron_right_rounded,
                                                        size: 16,
                                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: percentage.clamp(0.0, 1.0),
                                                  minHeight: 6,
                                                  backgroundColor: isDark ? const Color(0xFF222F42) : const Color(0xFFEAEFF2),
                                                  valueColor: AlwaysStoppedAnimation<Color>(catColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ReportTypeFilter filter) {
    final isSelected = _typeFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_typeFilter != filter) {
            setState(() => _typeFilter = filter);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            filter.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCountItem(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
