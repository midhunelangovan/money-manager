import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../../../core/constants/app_category_icons.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/utilities/storage_helper.dart';
import '../../../../core/widgets/app_category_icon.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/donut_chart.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/export_success_dialog.dart';
import '../../../../core/widgets/period_selector.dart';
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
  TimePeriod _selectedPeriod = TimePeriod.month;
  late DateTime _selectedDate;
  DateTimeRange? _customRange;
  ReportTypeFilter _typeFilter = ReportTypeFilter.expenses;
  String? _selectedAccountId; // null means All Accounts
  List<LedgerItem> _periodItems = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  int _queryVersion = 0;
  int _lastLoadedRevision = -1;
  int _lastAccountBalanceUnits = -1;
  int _lastAccountCount = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final txProvider = Provider.of<TransactionProvider>(context);
    final accProvider = Provider.of<AccountProvider>(context);
    final currentAccBal = accProvider.totalBalance.units;
    final currentAccCount = accProvider.accountsWithBalances.length;

    if (_lastLoadedRevision != txProvider.ledgerRevision ||
        _lastAccountBalanceUnits != currentAccBal ||
        _lastAccountCount != currentAccCount) {
      _lastLoadedRevision = txProvider.ledgerRevision;
      _lastAccountBalanceUnits = currentAccBal;
      _lastAccountCount = currentAccCount;
      _loadReportData();
    }
  }

  DateTime get _startDate {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0, 0);
      case TimePeriod.week:
        final monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day, 0, 0, 0, 0);
      case TimePeriod.month:
        return DateTime(_selectedDate.year, _selectedDate.month, 1, 0, 0, 0, 0);
      case TimePeriod.year:
        return DateTime(_selectedDate.year, 1, 1, 0, 0, 0, 0);
      case TimePeriod.period:
        if (_customRange != null) {
          return DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day, 0, 0, 0, 0);
        }
        return DateTime(_selectedDate.year, _selectedDate.month, 1, 0, 0, 0, 0);
    }
  }

  DateTime get _endDate {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return _startDate.add(const Duration(days: 1));
      case TimePeriod.week:
        return _startDate.add(const Duration(days: 7));
      case TimePeriod.month:
        return DateTime(_selectedDate.year, _selectedDate.month + 1, 1, 0, 0, 0, 0);
      case TimePeriod.year:
        return DateTime(_selectedDate.year + 1, 1, 1, 0, 0, 0, 0);
      case TimePeriod.period:
        if (_customRange != null) {
          return DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day + 1, 0, 0, 0, 0);
        }
        return DateTime(_selectedDate.year, _selectedDate.month + 1, 1, 0, 0, 0, 0);
    }
  }

  String get _periodLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    switch (_selectedPeriod) {
      case TimePeriod.day:
        final dayName = daysOfWeek[_selectedDate.weekday - 1];
        return '${_selectedDate.day.toString().padLeft(2, '0')} ${months[_selectedDate.month - 1]} ${_selectedDate.year} ($dayName)';
      case TimePeriod.week:
        final start = _startDate;
        final end = start.add(const Duration(days: 6));
        return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]} ${end.year}';
      case TimePeriod.month:
        return '${months[_selectedDate.month - 1]} ${_selectedDate.year}';
      case TimePeriod.year:
        return '${_selectedDate.year}';
      case TimePeriod.period:
        if (_customRange != null) {
          return '${_customRange!.start.day} ${months[_customRange!.start.month - 1]} ${_customRange!.start.year} – ${_customRange!.end.day} ${months[_customRange!.end.month - 1]} ${_customRange!.end.year}';
        }
        return '${months[_selectedDate.month - 1]} ${_selectedDate.year}';
    }
  }

  bool get _shouldShowToday => shouldShowToday(
        periodMode: _selectedPeriod,
        selectedDate: _selectedDate,
        customRange: _customRange,
      );

  void _onToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedDate = today;
      if (_customRange != null) {
        _customRange = DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: today,
        );
      }
    });
    _loadReportData();
  }

  void _onPrevious() {
    setState(() {
      switch (_selectedPeriod) {
        case TimePeriod.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case TimePeriod.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case TimePeriod.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day.clamp(1, 28));
          break;
        case TimePeriod.year:
          _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month, _selectedDate.day.clamp(1, 28));
          break;
        case TimePeriod.period:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day.clamp(1, 28));
          break;
      }
    });
    _loadReportData();
  }

  void _onNext() {
    setState(() {
      switch (_selectedPeriod) {
        case TimePeriod.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case TimePeriod.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case TimePeriod.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day.clamp(1, 28));
          break;
        case TimePeriod.year:
          _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month, _selectedDate.day.clamp(1, 28));
          break;
        case TimePeriod.period:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day.clamp(1, 28));
          break;
      }
    });
    _loadReportData();
  }

  Future<void> _pickDate() async {
    if (_selectedPeriod == TimePeriod.period) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: _customRange ??
            DateTimeRange(
              start: _selectedDate.subtract(const Duration(days: 30)),
              end: _selectedDate,
            ),
      );
      if (picked != null && mounted) {
        setState(() {
          _customRange = picked;
          _selectedDate = picked.start;
        });
        _loadReportData();
      }
      return;
    }

    if (_selectedPeriod == TimePeriod.month) {
      final picked = await MonthPickerDialog.show(context, _selectedDate);
      if (picked != null && mounted) {
        setState(() {
          _selectedDate = picked;
        });
        _loadReportData();
      }
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: _selectedPeriod == TimePeriod.year ? DatePickerMode.year : DatePickerMode.day,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    final currentVersion = ++_queryVersion;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final startDate = _startDate;
      final endDate = _endDate;

      final txProvider = context.read<TransactionProvider>();
      final items = await txProvider.getItemsForRange(
        startDate: startDate,
        endDate: endDate,
        exclusiveEndDate: true,
        accountId: _selectedAccountId,
      );

      if (currentVersion == _queryVersion && mounted) {
        setState(() {
          _periodItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (currentVersion == _queryVersion && mounted) {
        setState(() {
          _errorMessage = 'Unable to load analytics for $_periodLabel: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);

    try {
      final accountProvider = context.read<AccountProvider>();
      final accounts = accountProvider.accountsWithBalances;
      String accountName = 'All Accounts';
      if (_selectedAccountId != null) {
        final found = accounts.where((a) => a.account.id == _selectedAccountId).firstOrNull;
        if (found != null) accountName = found.account.name;
      }

      final excel = Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

      // 1. Summary Sheet
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');
      if (defaultSheet != 'Summary' && excel.sheets.containsKey(defaultSheet)) {
        excel.delete(defaultSheet);
      }

      int totalIncomeUnits = 0;
      int totalExpenseUnits = 0;
      int expenseCount = 0;
      int incomeCount = 0;
      int transferCount = 0;

      final filteredItems = _periodItems.where((item) {
        if (_typeFilter == ReportTypeFilter.expenses) {
          return item.type == LedgerItemType.expense;
        } else if (_typeFilter == ReportTypeFilter.income) {
          return item.type == LedgerItemType.income;
        }
        return true;
      }).toList();

      for (final item in _periodItems) {
        if (item.type == LedgerItemType.income) {
          totalIncomeUnits += item.amountUnits;
          incomeCount++;
        } else if (item.type == LedgerItemType.expense) {
          totalExpenseUnits += item.amountUnits;
          expenseCount++;
        } else if (item.type == LedgerItemType.transfer) {
          transferCount++;
        }
      }

      final netMovementUnits = totalIncomeUnits - totalExpenseUnits;

      summarySheet.appendRow([TextCellValue("Kal's Money Manager - Period Financial Report")]);
      summarySheet.appendRow([TextCellValue('Period: $_periodLabel')]);
      summarySheet.appendRow([TextCellValue('Account: $accountName')]);
      summarySheet.appendRow([TextCellValue('Filter Type: ${_typeFilter.displayName}')]);
      summarySheet.appendRow([TextCellValue('Generated on: ${DateFormatter.formatIsoDateTime(DateTime.now())}')]);
      summarySheet.appendRow([TextCellValue('')]);

      summarySheet.appendRow([TextCellValue('Metric'), TextCellValue('Amount (INR)')]);
      summarySheet.appendRow([TextCellValue('Total Income'), DoubleCellValue(totalIncomeUnits / 100.0)]);
      summarySheet.appendRow([TextCellValue('Total Expenses'), DoubleCellValue(totalExpenseUnits / 100.0)]);
      summarySheet.appendRow([TextCellValue('Net Movement / Savings'), DoubleCellValue(netMovementUnits / 100.0)]);
      summarySheet.appendRow([TextCellValue('Income Count'), IntCellValue(incomeCount)]);
      summarySheet.appendRow([TextCellValue('Expense Count'), IntCellValue(expenseCount)]);
      summarySheet.appendRow([TextCellValue('Transfer Count'), IntCellValue(transferCount)]);
      summarySheet.appendRow([TextCellValue('Matching Filter Records'), IntCellValue(filteredItems.length)]);

      // 2. Transactions Sheet
      final txSheet = excel['Transactions'];
      txSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Type'),
        TextCellValue('Amount (INR)'),
        TextCellValue('Account'),
        TextCellValue('Category'),
        TextCellValue('Description / Comment'),
      ]);

      for (final item in filteredItems) {
        final accountDisplay = item.type == LedgerItemType.transfer
            ? '${item.accountName ?? item.accountId} → ${item.destinationAccountName ?? item.destinationAccountId}'
            : (item.accountName ?? item.accountId);

        final comment = (item.notes != null && item.notes!.trim().isNotEmpty)
            ? item.notes!.trim()
            : item.description;

        txSheet.appendRow([
          TextCellValue(DateFormatter.format(item.date)),
          TextCellValue(item.type.displayName),
          DoubleCellValue(item.amount.toDoubleForDisplay()),
          TextCellValue(accountDisplay ?? ''),
          TextCellValue(item.categoryName ?? (item.type == LedgerItemType.transfer ? 'Transfer' : '-')),
          TextCellValue(comment),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to generate Excel file');

      // Descriptive filename: Kals_Report_2026-10.xlsx or Kals_Report_YYYY-MM-DD.xlsx
      String periodSlug;
      if (_selectedPeriod == TimePeriod.month) {
        periodSlug = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
      } else if (_selectedPeriod == TimePeriod.year) {
        periodSlug = '${_selectedDate.year}';
      } else {
        periodSlug = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      }

      final fileName = 'Kals_Report_$periodSlug${AppConstants.excelFileExtension}';

      final exportDir = await StorageHelper.getDownloadsDirectory();
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = File(p.join(exportDir.path, fileName));
      await file.writeAsBytes(fileBytes, flush: true);

      if (mounted) {
        await ExportSuccessDialog.show(
          context,
          file: file,
          type: ExportFileType.excel,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Export failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _openCategoryDrillDown({
    required String categoryId,
    required String categoryName,
    required IconData categoryIcon,
    required Color categoryColor,
    required String? accountName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryReportDetailScreen(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          startDate: _startDate,
          endDate: _endDate,
          periodTitle: _periodLabel,
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
                    _loadReportData();
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
                      _loadReportData();
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final canPop = Navigator.canPop(context);

    final accounts = accountProvider.accountsWithBalances;
    String selectedAccountName = 'All Accounts';
    if (_selectedAccountId != null) {
      final found = accounts.where((a) => a.account.id == _selectedAccountId).firstOrNull;
      if (found != null) {
        selectedAccountName = found.account.name;
      }
    }

    // Calculate metric aggregates
    int totalIncomeUnits = 0;
    int totalExpenseUnits = 0;
    final Map<String, int> categoryUnits = {};
    final Map<String, String> categoryNames = {};
    final Map<String, Color> categoryColors = {};
    final Map<String, IconData> categoryIcons = {};

    for (final item in _periodItems) {
      if (item.type == LedgerItemType.income) {
        totalIncomeUnits += item.amountUnits;
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
        final color = categoryColors[entry.key] ?? primaryColor;
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // App Header
          AppHeader(
            showBackButton: false,
            title: 'Reports',
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
            actions: [
              IconButton(
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_rounded, color: Colors.white),
                tooltip: 'Export Report to Excel',
                onPressed: _isExporting ? null : _exportToExcel,
              ),
            ],
          ),

          // Main Body
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'Loading $_periodLabel analytics...',
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
                                  backgroundColor: primaryColor,
                                  foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry'),
                                onPressed: _loadReportData,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReportData,
                        color: primaryColor,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          children: [
                            // 1. Account Selector Pill
                            Center(
                              child: GestureDetector(
                                onTap: () => _showAccountPicker(context, accounts),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_rounded,
                                        size: 15,
                                        color: isDark ? primaryColor : AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          selectedAccountName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 18,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 2. Period Navigation Selector (Day | Week | Month | Year | Period + ‹ 📅 Oct 2026 ▼ ›)
                            PeriodSelector(
                              selectedPeriod: _selectedPeriod,
                              onPeriodChanged: (period) {
                                setState(() => _selectedPeriod = period);
                                _loadReportData();
                              },
                              dateRangeLabel: _periodLabel,
                              onPrevious: _onPrevious,
                              onNext: _onNext,
                              onTapDate: _pickDate,
                              onToday: _onToday,
                              showToday: _shouldShowToday,
                            ),

                            const SizedBox(height: 12),

                            // 3. Report Type Filter: [ All ] [ Expenses ] [ Income ]
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: isDark ? Border.all(color: AppColors.darkBorderSubtle) : null,
                              ),
                              child: Row(
                                children: [
                                  _buildFilterChip(ReportTypeFilter.all),
                                  _buildFilterChip(ReportTypeFilter.expenses),
                                  _buildFilterChip(ReportTypeFilter.income),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            // 1. Primary Volume & Metric Summary (Typographic & Spacious)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    displayTotalMoney.format(currency: settings.currency),
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayTotalLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Subtle Metric Badges
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildTypographicStat(
                                          'Income',
                                          incomeMoney.format(currency: settings.currency),
                                          AppColors.income,
                                        ),
                                        Container(
                                          width: 1,
                                          height: 24,
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                        _buildTypographicStat(
                                          'Expenses',
                                          expenseMoney.format(currency: settings.currency),
                                          AppColors.expense,
                                        ),
                                        Container(
                                          width: 1,
                                          height: 24,
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                        _buildTypographicStat(
                                          'Savings',
                                          netSavingsMoney.format(currency: settings.currency),
                                          isDark ? primaryColor : AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 2. Clickable Donut Chart (Spacious, Uncluttered)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
                                ),
                              ),
                              child: Column(
                                children: [
                                  DonutChart(
                                    segments: donutSegments,
                                    centerAmount: displayTotalMoney.format(currency: settings.currency),
                                    centerLabel: _typeFilter.displayName,
                                    size: 220,
                                    strokeWidth: 24,
                                    isEmpty: donutSegments.isEmpty,
                                    emptyMessage: 'No ${_typeFilter.displayName.toLowerCase()} recorded for $_periodLabel',
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
                                    const SizedBox(height: 14),
                                    Text(
                                      'Tap any segment to view transactions',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 3. Category Breakdown List (Clean 2-level layout)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CATEGORY BREAKDOWN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    letterSpacing: 0.6,
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
                            const SizedBox(height: 12),

                            if (sortedCategories.isEmpty)
                              EmptyState(
                                icon: Icons.pie_chart_outline_rounded,
                                title: 'No ${_typeFilter.displayName} in $_periodLabel',
                                subtitle: 'There are no ${_typeFilter.displayName.toLowerCase()} records recorded for this time period.',
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
                                  ),
                                ),
                                child: Column(
                                  children: sortedCategories.map((entry) {
                                    final catName = categoryNames[entry.key] ?? 'Category';
                                    final amount = Money.fromUnits(entry.value);
                                    final catColor = categoryColors[entry.key] ?? primaryColor;
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
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Top Level: [Icon] Category Name ... Amount
                                            Row(
                                              children: [
                                                AppCategoryIcon(
                                                  icon: catIcon,
                                                  color: catColor,
                                                  size: 28,
                                                  iconSize: 16,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    catName,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  amount.format(currency: settings.currency),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                                            const SizedBox(height: 6),
                                            // Bottom Level: Progress Bar aligned with category name + XX.X% on right
                                            Padding(
                                              padding: const EdgeInsets.only(left: 36, right: 20),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(3),
                                                      child: LinearProgressIndicator(
                                                        value: percentage.clamp(0.0, 1.0),
                                                        minHeight: 5,
                                                        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSelectedBackground,
                                                        valueColor: AlwaysStoppedAnimation<Color>(catColor),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  SizedBox(
                                                    width: 46,
                                                    child: Text(
                                                      '${(percentage * 100).toStringAsFixed(1)}%',
                                                      textAlign: TextAlign.end,
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                            const SizedBox(height: 28),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_typeFilter != filter) {
            setState(() => _typeFilter = filter);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? primaryColor.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            filter.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? primaryColor : AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypographicStat(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: color,
          ),
        ),
      ],
    );
  }
}
