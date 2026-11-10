import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_category_icons.dart';
import '../../../../core/constants/app_currency.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_bottom_button.dart';
import '../../../../core/widgets/app_category_icon.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/export_success_dialog.dart';
import '../../../../core/widgets/period_selector.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/screens/add_edit_transaction_screen.dart';
import '../../data/services/excel_export_service.dart';
import '../providers/backup_provider.dart';
import 'export_history_screen.dart';

/// Dedicated, full-screen Export Transactions screen with 3 clear sections:
/// 1. Filters (Period, Chevrons, Account, Type)
/// 2. Transaction Preview (Count, Income/Expenses/Net summary, scrollable item preview)
/// 3. Export Action Button (Exports to Excel using exact preview filter)
class ExportTransactionsScreen extends StatefulWidget {
  final TimePeriod? initialPeriodMode;
  final DateTime? initialAnchorDate;
  final DateTimeRange? initialCustomDateRange;
  final String? initialAccountId;
  final String? initialAccountName;
  final LedgerItemType? initialTypeFilter;

  const ExportTransactionsScreen({
    super.key,
    this.initialPeriodMode,
    this.initialAnchorDate,
    this.initialCustomDateRange,
    this.initialAccountId,
    this.initialAccountName,
    this.initialTypeFilter,
  });

  @override
  State<ExportTransactionsScreen> createState() => _ExportTransactionsScreenState();
}

class _ExportTransactionsScreenState extends State<ExportTransactionsScreen> {
  late TimePeriod _periodMode;
  late DateTime _anchorDate;
  DateTimeRange? _customDateRange;
  String? _selectedAccountId;
  late String _selectedAccountName;
  LedgerItemType? _selectedType;
  bool _isExporting = false;

  // Transaction Preview State
  List<LedgerItem> _previewItems = [];
  bool _isLoadingPreview = false;
  int _totalIncomeUnits = 0;
  int _totalExpenseUnits = 0;
  int _netUnits = 0;
  bool _showAllPreview = false;

  @override
  void initState() {
    super.initState();
    _periodMode = widget.initialPeriodMode ?? TimePeriod.month;
    _anchorDate = widget.initialAnchorDate ?? DateTime.now();
    _customDateRange = widget.initialCustomDateRange;
    _selectedAccountId = widget.initialAccountId;
    _selectedAccountName = widget.initialAccountName ?? 'All Accounts';
    _selectedType = widget.initialTypeFilter;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreview();
    });
  }

  DateTime get _startDate {
    switch (_periodMode) {
      case TimePeriod.day:
        return DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day, 0, 0, 0);
      case TimePeriod.week:
        return _anchorDate.startOfWeek;
      case TimePeriod.month:
        return DateTime(_anchorDate.year, _anchorDate.month, 1, 0, 0, 0);
      case TimePeriod.year:
        return DateTime(_anchorDate.year, 1, 1, 0, 0, 0);
      case TimePeriod.period:
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          return DateTime(s.year, s.month, s.day, 0, 0, 0);
        }
        return DateTime(_anchorDate.year, _anchorDate.month, 1, 0, 0, 0);
    }
  }

  DateTime get _endDate {
    switch (_periodMode) {
      case TimePeriod.day:
        return DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day + 1, 0, 0, 0);
      case TimePeriod.week:
        return _anchorDate.startOfWeek.add(const Duration(days: 7));
      case TimePeriod.month:
        return DateTime(_anchorDate.year, _anchorDate.month + 1, 1, 0, 0, 0);
      case TimePeriod.year:
        return DateTime(_anchorDate.year + 1, 1, 1, 0, 0, 0);
      case TimePeriod.period:
        if (_customDateRange != null) {
          final e = _customDateRange!.end;
          return DateTime(e.year, e.month, e.day + 1, 0, 0, 0);
        }
        return DateTime(_anchorDate.year, _anchorDate.month + 1, 1, 0, 0, 0);
    }
  }

  String get _formattedDateRangeLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    switch (_periodMode) {
      case TimePeriod.day:
        final dayName = daysOfWeek[_anchorDate.weekday - 1];
        return '${_anchorDate.day.toString().padLeft(2, '0')} ${months[_anchorDate.month - 1]} ${_anchorDate.year} ($dayName)';
      case TimePeriod.week:
        final start = _anchorDate.startOfWeek;
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${months[start.month - 1]} ${start.day} – ${end.day}, ${end.year}';
        }
        return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}, ${end.year}';
      case TimePeriod.month:
        return '${months[_anchorDate.month - 1]} ${_anchorDate.year}';
      case TimePeriod.year:
        return '${_anchorDate.year}';
      case TimePeriod.period:
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          final e = _customDateRange!.end;
          if (s.month == e.month && s.year == e.year) {
            return '${months[s.month - 1]} ${s.day} – ${e.day}, ${e.year}';
          }
          return '${months[s.month - 1]} ${s.day} – ${months[e.month - 1]} ${e.day}, ${e.year}';
        }
        return '${months[_anchorDate.month - 1]} ${_anchorDate.year}';
    }
  }

  Future<void> _loadPreview() async {
    if (!mounted) return;
    setState(() => _isLoadingPreview = true);

    try {
      final txRepo = context.read<TransactionProvider>().repository;
      final items = await txRepo.getUnifiedLedger(
        accountId: _selectedAccountId,
        startDate: _startDate,
        endDate: _endDate,
        exclusiveEndDate: true,
        typeFilter: _selectedType,
      );

      int inc = 0;
      int exp = 0;
      for (final it in items) {
        if (it.type == LedgerItemType.income) {
          inc += it.amountUnits;
        } else if (it.type == LedgerItemType.expense) {
          exp += it.amountUnits;
        }
      }

      if (mounted) {
        setState(() {
          _previewItems = items;
          _totalIncomeUnits = inc;
          _totalExpenseUnits = exp;
          _netUnits = inc - exp;
          _isLoadingPreview = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  void _previousPeriod() {
    setState(() {
      switch (_periodMode) {
        case TimePeriod.day:
          _anchorDate = _anchorDate.subtract(const Duration(days: 1));
          break;
        case TimePeriod.week:
          _anchorDate = _anchorDate.subtract(const Duration(days: 7));
          break;
        case TimePeriod.month:
          final prevMonth = _anchorDate.month == 1 ? 12 : _anchorDate.month - 1;
          final prevYear = _anchorDate.month == 1 ? _anchorDate.year - 1 : _anchorDate.year;
          final maxDay = DateTime(prevYear, prevMonth + 1, 0).day;
          final safeDay = _anchorDate.day.clamp(1, maxDay);
          _anchorDate = DateTime(prevYear, prevMonth, safeDay);
          break;
        case TimePeriod.year:
          final prevYear = _anchorDate.year - 1;
          final maxDay = DateTime(prevYear, _anchorDate.month + 1, 0).day;
          final safeDay = _anchorDate.day.clamp(1, maxDay);
          _anchorDate = DateTime(prevYear, _anchorDate.month, safeDay);
          break;
        case TimePeriod.period:
          if (_customDateRange != null) {
            final days = _customDateRange!.duration.inDays + 1;
            _customDateRange = DateTimeRange(
              start: _customDateRange!.start.subtract(Duration(days: days)),
              end: _customDateRange!.end.subtract(Duration(days: days)),
            );
            _anchorDate = _customDateRange!.start;
          } else {
            final prevMonth = _anchorDate.month == 1 ? 12 : _anchorDate.month - 1;
            final prevYear = _anchorDate.month == 1 ? _anchorDate.year - 1 : _anchorDate.year;
            _anchorDate = DateTime(prevYear, prevMonth, 1);
          }
          break;
      }
    });
    _loadPreview();
  }

  void _nextPeriod() {
    setState(() {
      switch (_periodMode) {
        case TimePeriod.day:
          _anchorDate = _anchorDate.add(const Duration(days: 1));
          break;
        case TimePeriod.week:
          _anchorDate = _anchorDate.add(const Duration(days: 7));
          break;
        case TimePeriod.month:
          final nextMonth = _anchorDate.month == 12 ? 1 : _anchorDate.month + 1;
          final nextYear = _anchorDate.month == 12 ? _anchorDate.year + 1 : _anchorDate.year;
          final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
          final safeDay = _anchorDate.day.clamp(1, maxDay);
          _anchorDate = DateTime(nextYear, nextMonth, safeDay);
          break;
        case TimePeriod.year:
          final nextYear = _anchorDate.year + 1;
          final maxDay = DateTime(nextYear, _anchorDate.month + 1, 0).day;
          final safeDay = _anchorDate.day.clamp(1, maxDay);
          _anchorDate = DateTime(nextYear, _anchorDate.month, safeDay);
          break;
        case TimePeriod.period:
          if (_customDateRange != null) {
            final days = _customDateRange!.duration.inDays + 1;
            _customDateRange = DateTimeRange(
              start: _customDateRange!.start.add(Duration(days: days)),
              end: _customDateRange!.end.add(Duration(days: days)),
            );
            _anchorDate = _customDateRange!.start;
          } else {
            final nextMonth = _anchorDate.month == 12 ? 1 : _anchorDate.month + 1;
            final nextYear = _anchorDate.month == 12 ? _anchorDate.year + 1 : _anchorDate.year;
            _anchorDate = DateTime(nextYear, nextMonth, 1);
          }
          break;
      }
    });
    _loadPreview();
  }

  Future<void> _pickCustomDateRange() async {
    final initialStart = _customDateRange?.start ?? _startDate;
    final initialEnd = _customDateRange?.end ??
        (_periodMode == TimePeriod.day
            ? _startDate
            : _endDate.subtract(const Duration(days: 1)));

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
      setState(() {
        _periodMode = TimePeriod.period;
        _customDateRange = picked;
        _anchorDate = picked.start;
      });
      _loadPreview();
    }
  }

  Future<void> _onTapDate() async {
    if (_periodMode == TimePeriod.period) {
      await _pickCustomDateRange();
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked != null && mounted) {
      setState(() {
        _anchorDate = picked;
      });
      _loadPreview();
    }
  }

  void _showAccountSelector() {
    final accounts = context.read<AccountProvider>().accounts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorderSubtle : null),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('All Accounts', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: _selectedAccountId == null
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedAccountId = null;
                      _selectedAccountName = 'All Accounts';
                    });
                    Navigator.pop(ctx);
                    _loadPreview();
                  },
                ),
                ...accounts.where((a) => !a.isArchived).map((acc) {
                  final isSelected = _selectedAccountId == acc.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isSelected ? AppColors.primary : AppColors.lightInputSurface).withValues(alpha: 0.2),
                      child: Icon(Icons.credit_card_rounded, color: isSelected ? AppColors.primary : AppColors.lightTextSecondary, size: 20),
                    ),
                    title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedAccountId = acc.id;
                        _selectedAccountName = acc.name;
                      });
                      Navigator.pop(ctx);
                      _loadPreview();
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

  Future<void> _exportTransactions() async {
    if (_isExporting) return;

    final messenger = ScaffoldMessenger.of(context);

    if (_previewItems.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No transactions found matching the selected period and filters to export.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final backupProvider = context.read<BackupProvider>();

    final filter = ExcelExportFilter(
      startDate: _startDate,
      endDate: _endDate,
      exclusiveEndDate: true,
      accountId: _selectedAccountId,
      typeFilter: _selectedType,
    );

    setState(() {
      _isExporting = true;
    });

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Generating Excel export...'),
        duration: Duration(seconds: 1),
      ),
    );

    File? file;
    try {
      file = await backupProvider.exportToExcel(
        filter: filter,
        notify: backupProvider.autoExportConfig.notifyOnComplete,
      );
    } catch (_) {
      // Error handled below via provider message
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }

    if (!mounted) return;

    if (file != null) {
      await ExportSuccessDialog.show(
        context,
        file: file,
        type: ExportFileType.excel,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(backupProvider.errorMessage ?? 'Export failed. Please check storage permissions.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;

    final displayedList = _showAllPreview
        ? _previewItems
        : _previewItems.take(8).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Full-screen curved brand header
          AppHeader(
            title: 'Export Transactions',
            centerTitle: false,
            showBackButton: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                tooltip: 'Export History',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExportHistoryScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Scrollable content with the 3 clear sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // ==================== SECTION 1: FILTERS ====================
                // 1.1 Period Selector (Day, Week, Month, Year, Period + Date navigation)
                PeriodSelector(
                  selectedPeriod: _periodMode,
                  onPeriodChanged: (mode) {
                    setState(() {
                      _periodMode = mode;
                      if (mode == TimePeriod.period && _customDateRange == null) {
                        _pickCustomDateRange();
                      }
                    });
                    _loadPreview();
                  },
                  dateRangeLabel: _formattedDateRangeLabel,
                  onPrevious: _previousPeriod,
                  onNext: _nextPeriod,
                  onTapDate: _onTapDate,
                ),

                const SizedBox(height: 18),

                // 1.2 Account Filter
                Row(
                  children: [
                    Text(
                      'Account:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _showAccountSelector,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _selectedAccountName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 1.3 Transaction Type Filter
                Row(
                  children: [
                    Text(
                      'Type:      ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            _buildTypeTab(
                              label: 'All',
                              isSelected: _selectedType == null,
                              onTap: () {
                                setState(() => _selectedType = null);
                                _loadPreview();
                              },
                              isDark: isDark,
                            ),
                            _buildTypeTab(
                              label: 'Expenses',
                              isSelected: _selectedType == LedgerItemType.expense,
                              onTap: () {
                                setState(() => _selectedType = LedgerItemType.expense);
                                _loadPreview();
                              },
                              isDark: isDark,
                            ),
                            _buildTypeTab(
                              label: 'Income',
                              isSelected: _selectedType == LedgerItemType.income,
                              onTap: () {
                                setState(() => _selectedType = LedgerItemType.income);
                                _loadPreview();
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ==================== SECTION 2: TRANSACTION PREVIEW ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRANSACTION PREVIEW',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (_isLoadingPreview)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_previewItems.length} transactions',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Financial Totals Summary Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildSummaryMetric(
                        label: 'Income',
                        amount: Money.fromUnits(_totalIncomeUnits).format(currency: currency),
                        color: AppColors.income,
                        prefix: '+',
                      ),
                      Container(width: 1, height: 32, color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE5E7EB)),
                      _buildSummaryMetric(
                        label: 'Expenses',
                        amount: Money.fromUnits(_totalExpenseUnits).format(currency: currency),
                        color: AppColors.expense,
                        prefix: '-',
                      ),
                      Container(width: 1, height: 32, color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE5E7EB)),
                      _buildSummaryMetric(
                        label: 'Net',
                        amount: Money.fromUnits(_netUnits.abs()).format(currency: currency),
                        color: _netUnits >= 0 ? (isDark ? AppColors.darkPrimary : AppColors.primary) : AppColors.expense,
                        prefix: _netUnits >= 0 ? '+' : '-',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Preview List of Transactions
                if (_isLoadingPreview) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ] else if (_previewItems.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 36,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No matching transactions to export',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try choosing a different period, account, or type.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ...displayedList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final isLast = idx == displayedList.length - 1 && (_previewItems.length <= 8 || _showAllPreview);
                          return Column(
                            children: [
                              _buildPreviewRow(item, isDark, currency),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: 56,
                                  endIndent: 16,
                                  color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFF3F4F6),
                                ),
                            ],
                          );
                        }),
                        if (_previewItems.length > 8) ...[
                          Divider(height: 1, color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE5E7EB)),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showAllPreview = !_showAllPreview;
                              });
                            },
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              child: Text(
                                _showAllPreview
                                    ? 'Show fewer transactions'
                                    : 'View all ${_previewItems.length} matching transactions',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ==================== SECTION 3: EXPORT ACTION ====================
          AppBottomButton(
            label: 'Export to Excel',
            backgroundColor: _previewItems.isEmpty ? Colors.grey : AppColors.primary,
            foregroundColor: Colors.white,
            width: double.infinity,
            isLoading: _isExporting,
            onPressed: _previewItems.isEmpty ? null : _exportTransactions,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String amount,
    required Color color,
    required String prefix,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E95A2),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$prefix$amount',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(LedgerItem item, bool isDark, AppCurrency currency) {
    final isExpense = item.type == LedgerItemType.expense;
    final isIncome = item.type == LedgerItemType.income;
    final isTransfer = item.type == LedgerItemType.transfer;

    final color = isExpense
        ? AppColors.expense
        : (isIncome ? AppColors.income : const Color(0xFF6B7280));

    final prefix = isExpense ? '-' : (isIncome ? '+' : '');
    final amountFormatted = Money.fromUnits(item.amountUnits).format(currency: currency);
    final dateStr = DateFormat('dd MMM').format(item.date);
    final iconData = item.categoryIcon != null
        ? AppCategoryIcons.getIconData(item.categoryIcon!)
        : (isTransfer ? Icons.swap_horiz_rounded : Icons.category_rounded);
    final itemDesc = item.description.isNotEmpty
        ? item.description
        : (item.categoryName ?? (isTransfer ? 'Transfer' : 'Transaction'));

    return InkWell(
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AddEditTransactionScreen(
              transaction: item,
            ),
          ),
        );
        if (changed == true) {
          _loadPreview();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Date label
            SizedBox(
              width: 50,
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                ),
              ),
            ),

            // Category Icon
            AppCategoryIcon(
              icon: iconData,
              color: item.categoryColor != null
                  ? Color(item.categoryColor!)
                  : (isDark ? AppColors.darkPrimary : AppColors.primary),
              size: 32,
              iconSize: 18,
            ),
            const SizedBox(width: 10),

            // Description / Category / Notes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemDesc,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.categoryName != null && item.description.isNotEmpty)
                    Text(
                      item.categoryName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF9CA3AF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Amount
            Text(
              '$prefix$amountFormatted',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final activeTextColor = isDark ? theme.colorScheme.primary : AppColors.primary;
    final inactiveTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer.withValues(alpha: 0.6))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeTextColor : inactiveTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
