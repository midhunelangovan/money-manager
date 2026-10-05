import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/export_action_dialog.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_list_item.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectDate(BuildContext context) async {
    final txProvider = context.read<TransactionProvider>();
    final initialDate = txProvider.filter.selectedDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked != null && mounted) {
      txProvider.updateFilter(
        txProvider.filter.copyWith(
          dateMode: DateFilterMode.singleDate,
          selectedDate: DateTime(picked.year, picked.month, picked.day),
        ),
      );
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final txProvider = context.read<TransactionProvider>();
    final initialStart = txProvider.filter.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final initialEnd = txProvider.filter.endDate ?? DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: DateTimeRange(
        start: initialStart.isBefore(initialEnd) ? initialStart : initialEnd,
        end: initialEnd.isAfter(initialStart) ? initialEnd : initialStart,
      ),
    );

    if (picked != null && mounted) {
      txProvider.updateFilter(
        txProvider.filter.copyWith(
          dateMode: DateFilterMode.dateRange,
          startDate: DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0),
          endDate: DateTime(picked.end.year, picked.end.month, picked.end.day + 1, 0, 0, 0),
          exclusiveEndDate: true,
        ),
      );
    }
  }

  void _showDateModeMenu(BuildContext context) {
    final txProvider = context.read<TransactionProvider>();
    final currentMode = txProvider.filter.dateMode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: primaryAccent, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Select Date Filter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: isDark ? AppColors.darkBorderSubtle : null),
                ListTile(
                  leading: Icon(Icons.today_rounded, color: primaryAccent),
                  title: Text(
                    'Today',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  onTap: () {
                    final now = DateTime.now();
                    txProvider.updateFilter(
                      txProvider.filter.copyWith(
                        dateMode: DateFilterMode.singleDate,
                        selectedDate: DateTime(now.year, now.month, now.day),
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit_calendar_rounded, color: primaryAccent),
                  title: Text(
                    'Pick Specific Date (Calendar)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Jump directly to any day in any month or year',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDirectDate(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.date_range_rounded, color: primaryAccent),
                  title: Text(
                    'Custom Date Range',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Filter between two dates',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDateRange(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.all_inclusive_rounded, color: primaryAccent),
                  title: Text(
                    'All Dates',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Show all historical transactions',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  trailing: currentMode == DateFilterMode.allDates ? Icon(Icons.check_rounded, color: primaryAccent) : null,
                  onTap: () {
                    txProvider.updateFilter(
                      txProvider.filter.copyWith(
                        clearDates: true,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFilterSheet() {
    final txProvider = context.read<TransactionProvider>();
    final accProvider = context.read<AccountProvider>();
    final catProvider = context.read<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? selectedAccount = txProvider.filter.accountId;
        String? selectedCategory = txProvider.filter.categoryId;
        LedgerItemType? selectedType = txProvider.filter.typeFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          txProvider.resetFilter();
                          _searchController.clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transaction Type Filter
                  Text(
                    'Transaction Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<LedgerItemType?>(
                    initialValue: selectedType,
                    dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                    decoration: const InputDecoration(hintText: 'All Types'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Types')),
                      DropdownMenuItem(value: LedgerItemType.expense, child: Text('Expenses')),
                      DropdownMenuItem(value: LedgerItemType.income, child: Text('Income')),
                      DropdownMenuItem(value: LedgerItemType.transfer, child: Text('Transfers')),
                    ],
                    onChanged: (val) => setModalState(() => selectedType = val),
                  ),

                  const SizedBox(height: 16),

                  // Account Filter
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedAccount,
                    dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                    decoration: const InputDecoration(hintText: 'All Accounts'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Accounts')),
                      ...accProvider.accountsWithBalances.map(
                        (a) => DropdownMenuItem(value: a.account.id, child: Text(a.account.name)),
                      ),
                    ],
                    onChanged: (val) => setModalState(() => selectedAccount = val),
                  ),

                  const SizedBox(height: 16),

                  // Category Filter
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedCategory,
                    dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                    decoration: const InputDecoration(hintText: 'All Categories'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...[...catProvider.expenseCategories, ...catProvider.incomeCategories].map(
                        (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (val) => setModalState(() => selectedCategory = val),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      txProvider.updateFilter(
                        txProvider.filter.copyWith(
                          typeFilter: selectedType,
                          clearTypeFilter: selectedType == null,
                          accountId: selectedAccount,
                          clearAccountId: selectedAccount == null,
                          categoryId: selectedCategory,
                          clearCategoryId: selectedCategory == null,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChips(TransactionProvider txProvider) {
    final activeType = txProvider.filter.typeFilter;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;

    Widget chip({required String label, required LedgerItemType? type}) {
      final isSelected = activeType == type;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: InkWell(
            onTap: () {
              txProvider.updateFilter(
                txProvider.filter.copyWith(
                  typeFilter: type,
                  clearTypeFilter: type == null,
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? primaryAccent.withValues(alpha: 0.25) : AppColors.primary)
                    : (isDark ? AppColors.darkSurfaceCard : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? primaryAccent
                      : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? primaryAccent : Colors.white)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      child: Row(
        children: [
          chip(label: 'All', type: null),
          chip(label: 'Expenses', type: LedgerItemType.expense),
          chip(label: 'Income', type: LedgerItemType.income),
          chip(label: 'Transfers', type: LedgerItemType.transfer),
        ],
      ),
    );
  }

  Widget _buildDateHeader(TransactionProvider txProvider) {
    final filter = txProvider.filter;
    final mode = filter.dateMode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;

    String dateLabel;
    bool isTodaySelected = false;

    if (mode == DateFilterMode.singleDate && filter.selectedDate != null) {
      final d = filter.selectedDate!;
      dateLabel = DateFormat('dd MMMM yyyy').format(d);
      isTodaySelected = d.year == today.year && d.month == today.month && d.day == today.day;
    } else if (mode == DateFilterMode.dateRange && filter.startDate != null) {
      final startStr = DateFormat('dd MMM').format(filter.startDate!);
      final endD = filter.endDate ?? filter.startDate!;
      final endDisplay = filter.exclusiveEndDate ? endD.subtract(const Duration(days: 1)) : endD;
      final endStr = DateFormat('dd MMM yyyy').format(endDisplay);
      dateLabel = '$startStr – $endStr';
    } else {
      dateLabel = 'All Dates';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            // Previous Date Navigation Button
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: primaryAccent, size: 24),
              tooltip: 'Previous Date',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                final baseDate = filter.selectedDate ?? today;
                final prevDate = baseDate.subtract(const Duration(days: 1));
                txProvider.updateFilter(
                  filter.copyWith(
                    dateMode: DateFilterMode.singleDate,
                    selectedDate: DateTime(prevDate.year, prevDate.month, prevDate.day),
                  ),
                );
              },
            ),

            // Center Date Control — Opens direct date picker / mode selector
            Expanded(
              child: InkWell(
                onTap: () => _showDateModeMenu(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: primaryAccent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ],
                  ),
                ),
              ),
            ),

            // Next Date Navigation Button
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: primaryAccent, size: 24),
              tooltip: 'Next Date',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                final baseDate = filter.selectedDate ?? today;
                final nextDate = baseDate.add(const Duration(days: 1));
                txProvider.updateFilter(
                  filter.copyWith(
                    dateMode: DateFilterMode.singleDate,
                    selectedDate: DateTime(nextDate.year, nextDate.month, nextDate.day),
                  ),
                );
              },
            ),

            // Today Shortcut Button if not already on Today
            if (!isTodaySelected && mode == DateFilterMode.singleDate) ...[
              const SizedBox(width: 2),
              InkWell(
                onTap: () {
                  txProvider.updateFilter(
                    filter.copyWith(
                      dateMode: DateFilterMode.singleDate,
                      selectedDate: today,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCountBar(TransactionProvider txProvider) {
    final count = txProvider.ledgerItems.length;
    final hasActive = txProvider.filter.hasActiveFilters;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? Theme.of(context).colorScheme.primary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            count == 0
                ? 'No transactions'
                : count == 1
                    ? '1 Transaction'
                    : '$count Transactions',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          if (hasActive)
            GestureDetector(
              onTap: () {
                txProvider.resetFilter();
                _searchController.clear();
              },
              child: Row(
                children: [
                  Icon(Icons.close_rounded, size: 14, color: primaryAccent),
                  const SizedBox(width: 3),
                  Text(
                    'Clear Filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);
    final hasActiveFilters = txProvider.filter.hasActiveFilters;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: Column(
        children: [
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
            title: 'Transactions',
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                tooltip: 'Export to Excel',
                onPressed: () {
                  ExportActionDialog.show(
                    context,
                    initialStartDate: txProvider.filter.startDate,
                    initialEndDate: txProvider.filter.endDate,
                    accountId: txProvider.filter.accountId,
                  );
                },
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                    tooltip: 'Filter',
                    onPressed: _openFilterSheet,
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: AppTextField(
              controller: _searchController,
              fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: 12,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 14),
              hintText: 'Search description, notes, category, account...',
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.primary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      onPressed: () {
                        _searchController.clear();
                        txProvider.updateFilter(
                          txProvider.filter.copyWith(
                            clearSearchQuery: true,
                          ),
                        );
                      },
                    )
                  : null,
              onChanged: (query) {
                txProvider.updateFilter(
                  txProvider.filter.copyWith(
                    searchQuery: query.trim().isEmpty ? null : query.trim(),
                    clearSearchQuery: query.trim().isEmpty,
                  ),
                );
              },
            ),
          ),

          // 1. Type Filter Pills (All, Expenses, Income, Transfers)
          _buildTypeChips(txProvider),

          // 2. Direct Date Header & Picker Control
          _buildDateHeader(txProvider),

          // 3. Result Count & Clear Filters
          _buildResultCountBar(txProvider),

          const SizedBox(height: 2),

          // 4. Filtered Ledger Items List
          Expanded(
            child: txProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => txProvider.loadLedger(),
                    color: AppColors.primary,
                    child: txProvider.ledgerItems.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                              EmptyState(
                                icon: Icons.receipt_long_rounded,
                                title: 'No Transactions Found',
                                subtitle: hasActiveFilters
                                    ? 'No transactions match your current filters.'
                                    : 'No transactions recorded yet.',
                                actionLabel: hasActiveFilters ? 'Clear Filters' : null,
                                onAction: hasActiveFilters
                                    ? () {
                                        txProvider.resetFilter();
                                        _searchController.clear();
                                      }
                                    : null,
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: txProvider.ledgerItems.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = txProvider.ledgerItems[index];
                              return TransactionListItem(
                                item: item,
                                onTap: () async {
                                  final changed = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => AddEditTransactionScreen(transaction: item),
                                    ),
                                  );
                                  if (changed == true && context.mounted) {
                                    await Future.wait([
                                      context.read<AccountProvider>().loadAccounts(),
                                      context.read<TransactionProvider>().loadLedger(),
                                    ]);
                                  }
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEditTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.accentYellow,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}
