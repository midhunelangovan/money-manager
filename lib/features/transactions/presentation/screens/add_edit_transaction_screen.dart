import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_select_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_dialog.dart';
import '../../../../core/widgets/category_grid.dart';
import '../../../../core/widgets/transaction_amount_header.dart';
import '../../../../core/widgets/transaction_attachment.dart';
import '../../../../core/widgets/transaction_type_tabs.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transfers/domain/entities/transfer.dart';
import '../../../transfers/presentation/providers/transfer_provider.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_provider.dart';

enum EntryMode { expense, income, transfer }

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? initialTransaction;
  final Transfer? initialTransfer;
  final LedgerItem? transaction;
  final EntryMode initialMode;
  final String? initialAccountId;
  final DateTime? initialDate;

  const AddEditTransactionScreen({
    super.key,
    this.initialTransaction,
    this.initialTransfer,
    this.transaction,
    this.initialMode = EntryMode.expense,
    this.initialAccountId,
    this.initialDate,
  });

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  late EntryMode _mode;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  final FocusNode _commentFocusNode = FocusNode();

  String? _selectedAccountId;
  String? _selectedDestinationAccountId;
  String? _selectedCategoryId;
  String? _receiptPath;
  bool _isSaving = false;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();

    // Determine Mode & pre-populate
    if (widget.transaction != null) {
      final t = widget.transaction!;
      if (t.type == LedgerItemType.transfer) {
        _mode = EntryMode.transfer;
      } else if (t.type == LedgerItemType.income) {
        _mode = EntryMode.income;
      } else {
        _mode = EntryMode.expense;
      }
      _amountController = TextEditingController(text: t.amountUnits > 0 ? (t.amountUnits / 100).toStringAsFixed(2) : '');
      final comment = (t.notes != null && t.notes!.trim().isNotEmpty)
          ? t.notes!.trim()
          : ((t.description.isNotEmpty &&
              t.description != (t.categoryName ?? '') &&
              t.description != 'Transfer' &&
              t.description != 'Imported' &&
              t.description != 'Imported Transfer')
              ? t.description
              : '');
      _descriptionController = TextEditingController(text: comment);
      _selectedDate = t.date;
      _selectedAccountId = t.accountId;
      _selectedDestinationAccountId = t.destinationAccountId;
      _selectedCategoryId = t.categoryId;
      _receiptPath = t.receiptPath;
      _createdAt = t.createdAt;
    } else if (widget.initialTransfer != null) {
      final tr = widget.initialTransfer!;
      _mode = EntryMode.transfer;
      _amountController = TextEditingController(text: tr.amount.units > 0 ? (tr.amount.units / 100).toStringAsFixed(2) : '');
      final comment = (tr.description.isNotEmpty && tr.description != 'Transfer' && tr.description != 'Imported Transfer') ? tr.description : '';
      _descriptionController = TextEditingController(text: comment);
      _selectedDate = tr.date;
      _selectedAccountId = tr.fromAccountId;
      _selectedDestinationAccountId = tr.toAccountId;
      _receiptPath = tr.receiptPath;
      _createdAt = tr.createdAt;
    } else if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      _mode = tx.transactionType == CategoryType.income ? EntryMode.income : EntryMode.expense;
      _amountController = TextEditingController(text: tx.amount.units > 0 ? (tx.amount.units / 100).toStringAsFixed(2) : '');
      final comment = (tx.notes != null && tx.notes!.trim().isNotEmpty)
          ? tx.notes!.trim()
          : ((tx.description.isNotEmpty && tx.description != (tx.categoryName ?? '') && tx.description != 'Imported')
              ? tx.description
              : '');
      _descriptionController = TextEditingController(text: comment);
      _selectedDate = tx.date;
      _selectedAccountId = tx.accountId;
      _selectedCategoryId = tx.categoryId;
      _receiptPath = tx.receiptPath;
      _createdAt = tx.createdAt;
    } else {
      _mode = widget.initialMode;
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedAccountId = widget.initialAccountId;
      _createdAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.transaction != null || widget.initialTransaction != null || widget.initialTransfer != null;

  String get _headerTitle {
    if (_isEditing) {
      switch (_mode) {
        case EntryMode.expense:
          return 'Edit Expense';
        case EntryMode.income:
          return 'Edit Income';
        case EntryMode.transfer:
          return 'Edit Transfer';
      }
    } else {
      switch (_mode) {
        case EntryMode.expense:
          return 'Add Expense';
        case EntryMode.income:
          return 'Add Income';
        case EntryMode.transfer:
          return 'Add Transfer';
      }
    }
  }

  LedgerTabType get _tabType {
    switch (_mode) {
      case EntryMode.expense:
        return LedgerTabType.expenses;
      case EntryMode.income:
        return LedgerTabType.income;
      case EntryMode.transfer:
        return LedgerTabType.transfer;
    }
  }

  void _onTabChanged(LedgerTabType tab) {
    setState(() {
      switch (tab) {
        case LedgerTabType.expenses:
          _mode = EntryMode.expense;
          _selectedCategoryId = null;
          break;
        case LedgerTabType.income:
          _mode = EntryMode.income;
          _selectedCategoryId = null;
          break;
        case LedgerTabType.transfer:
          _mode = EntryMode.transfer;
          break;
      }
    });
  }

  void _openCalculator() async {
    final currentVal = double.tryParse(_amountController.text) ?? 0.0;
    final result = await CalculatorDialog.show(context, initialValue: currentVal);
    if (result != null && mounted) {
      setState(() {
        _amountController.text = result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
      });
    }
  }

  void _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _showAllCategoriesSheet(List<Category> allCategories) async {
    final selected = await Navigator.of(context).push<Category>(
      MaterialPageRoute(
        builder: (_) => CategoriesScreen(
          isPickerMode: true,
          initialType: _mode == EntryMode.income ? CategoryType.income : CategoryType.expense,
          onCategorySelected: (cat) {
            setState(() => _selectedCategoryId = cat.id);
          },
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedCategoryId = selected.id);
    }
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount.')),
      );
      return;
    }

    final amountDouble = double.tryParse(amountText);
    if (amountDouble == null || amountDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount.')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account.')),
      );
      return;
    }

    if (_mode == EntryMode.transfer) {
      if (_selectedDestinationAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination account.')),
        );
        return;
      }
      if (_selectedAccountId == _selectedDestinationAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts must be different.')),
        );
        return;
      }
    } else {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category.')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final amountUnits = (amountDouble * 100).round();
      final money = Money.fromUnits(amountUnits);
      final desc = _descriptionController.text.trim();

      final accProvider = context.read<AccountProvider>();
      final catProvider = context.read<CategoryProvider>();
      final txProvider = context.read<TransactionProvider>();
      final transferProvider = context.read<TransferProvider>();
      final navigator = Navigator.of(context);

      if (_mode == EntryMode.transfer) {
        final transferId = widget.initialTransfer?.id ?? widget.transaction?.id ?? IdGenerator.uuid();
        final originalCreatedAt = _createdAt ?? DateTime.now();

        final transfer = Transfer(
          id: transferId,
          fromAccountId: _selectedAccountId!,
          toAccountId: _selectedDestinationAccountId!,
          amount: money,
          date: _selectedDate,
          description: desc.isNotEmpty ? desc : 'Transfer',
          receiptPath: _receiptPath,
          createdAt: originalCreatedAt,
          updatedAt: DateTime.now(),
        );

        if (_isEditing) {
          await transferProvider.updateTransfer(transfer);
        } else {
          await transferProvider.createTransfer(transfer);
        }
      } else {
        final categoryType = _mode == EntryMode.income ? CategoryType.income : CategoryType.expense;
        final txId = widget.initialTransaction?.id ?? widget.transaction?.id ?? IdGenerator.uuid();
        final originalCreatedAt = _createdAt ?? DateTime.now();
        final cat = catProvider.categories.where((c) => c.id == _selectedCategoryId).firstOrNull;

        final tx = Transaction(
          id: txId,
          transactionType: categoryType,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
          amount: money,
          date: _selectedDate,
          description: desc.isNotEmpty ? desc : (cat?.name ?? 'Transaction'),
          notes: desc.isNotEmpty ? desc : null,
          receiptPath: _receiptPath,
          createdAt: originalCreatedAt,
          updatedAt: DateTime.now(),
        );

        if (_isEditing) {
          await txProvider.updateTransaction(tx);
        } else {
          await txProvider.createTransaction(tx);
        }
      }

      await accProvider.loadAccounts();
      await txProvider.loadLedger();
      if (mounted) {
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Transaction?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This will remove this transaction from your financial records.',
          style: TextStyle(fontSize: 14.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final accProvider = context.read<AccountProvider>();
      final txProvider = context.read<TransactionProvider>();
      final transferProvider = context.read<TransferProvider>();
      final navigator = Navigator.of(context);

      if (_mode == EntryMode.transfer) {
        final id = widget.initialTransfer?.id ?? widget.transaction?.id;
        if (id != null) await transferProvider.deleteTransfer(id);
      } else {
        final id = widget.initialTransaction?.id ?? widget.transaction?.id;
        if (id != null) await txProvider.deleteTransaction(id);
      }

      await accProvider.loadAccounts();
      await txProvider.loadLedger();
      if (mounted) {
        navigator.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accounts = accountProvider.accountsWithBalances.where((a) => !a.account.isArchived).toList();

    // Ensure default account selection if available
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.account.id;
    }
    if (_mode == EntryMode.transfer && _selectedDestinationAccountId == null && accounts.length > 1) {
      _selectedDestinationAccountId = accounts[1].account.id;
    }

    final categories = _mode == EntryMode.income
        ? categoryProvider.incomeCategories
        : categoryProvider.expenseCategories;

    // Set default category if none selected
    if (_mode != EntryMode.transfer && _selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    final accentColor = _mode == EntryMode.income
        ? AppColors.income
        : (_mode == EntryMode.expense ? AppColors.expense : AppColors.transfer);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // 1. Top Header with EXPENSES / INCOME / TRANSFER Tabs
          AppHeader(
            title: _headerTitle,
            actions: _isEditing
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      tooltip: 'Delete Transaction',
                      onPressed: _delete,
                    ),
                  ]
                : null,
            bottom: TransactionTypeTabs(
              selectedTab: _tabType,
              onTabSelected: _onTabChanged,
              showTransfer: true,
              isHeaderStyle: true,
            ),
          ),

          // 2. Compact Fast Direct Form Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Prominent Amount Input with Currency & Calculator
                // In ADD mode: autofocus is true for rapid numeric input with numeric keyboard immediately open.
                TransactionAmountHeader(
                  controller: _amountController,
                  currency: settings.currency,
                  accentColor: accentColor,
                  autofocus: !_isEditing,
                  onCalculatorTap: _openCalculator,
                ),

                const SizedBox(height: 12),

                // Account Selector Row
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: _mode == EntryMode.transfer
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSelectField<String>(
                              label: 'SOURCE ACCOUNT (FROM)',
                              hint: 'Select Source Account',
                              value: _selectedAccountId,
                              items: accounts.map((a) {
                                return AppSelectItem<String>(
                                  value: a.account.id,
                                  title: a.account.name,
                                  subtitle: 'Balance: ${a.calculatedBalance.format(currency: settings.currency)}',
                                  icon: a.account.iconData,
                                  iconColor: a.account.color != null ? Color(a.account.color!) : AppColors.primary,
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedAccountId = val),
                            ),
                            const SizedBox(height: 12),
                            AppSelectField<String>(
                              label: 'DESTINATION ACCOUNT (TO)',
                              hint: 'Select Destination Account',
                              value: _selectedDestinationAccountId,
                              items: accounts.map((a) {
                                return AppSelectItem<String>(
                                  value: a.account.id,
                                  title: a.account.name,
                                  subtitle: 'Balance: ${a.calculatedBalance.format(currency: settings.currency)}',
                                  icon: a.account.iconData,
                                  iconColor: a.account.color != null ? Color(a.account.color!) : AppColors.primary,
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedDestinationAccountId = val),
                            ),
                          ],
                        )
                      : AppSelectField<String>(
                          label: 'ACCOUNT',
                          hint: 'Select Account',
                          value: _selectedAccountId,
                          items: accounts.map((a) {
                            return AppSelectItem<String>(
                              value: a.account.id,
                              title: a.account.name,
                              subtitle: 'Balance: ${a.calculatedBalance.format(currency: settings.currency)}',
                              icon: a.account.iconData,
                              iconColor: a.account.color != null ? Color(a.account.color!) : AppColors.primary,
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedAccountId = val),
                        ),
                ),

                if (_mode != EntryMode.transfer) ...[
                  const SizedBox(height: 12),

                  // 4-Column × 2-Row Category Grid (Direct Fast Selection)
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CategoryGrid(
                          categories: categories,
                          selectedCategoryId: _selectedCategoryId,
                          onCategorySelected: (cat) => setState(() => _selectedCategoryId = cat.id),
                          onMoreTap: () => _showAllCategoriesSheet(categories),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Compact Quick Date Selector (today, yesterday, last, calendar)
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            DateFormatter.formatDate(_selectedDate),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Theme.of(context).colorScheme.primary : AppColors.primary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildQuickDateSelector(isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 5. Comment / Description Input (Single tap focuses immediately, professional input box)
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Comment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _descriptionController,
                        focusNode: _commentFocusNode,
                        hintText: 'Add a comment / description...',
                        maxLines: 2,
                        minLines: 1,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 6. Photo / Receipt Attachment Section (Unified Reusable Component)
                TransactionAttachment(
                  receiptPath: _receiptPath,
                  onAttachmentChanged: (newPath) => setState(() => _receiptPath = newPath),
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Created: ${DateFormatter.formatDate(_createdAt ?? DateTime.now())} · ${DateFormatter.formatTime(_createdAt ?? DateTime.now())}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Large Bottom Rounded Action Button (Add / Save Changes)
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _isEditing ? 'Save Changes' : 'Save',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateSelector(bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final last = today.subtract(const Duration(days: 2));

    final isToday = _selectedDate.year == today.year && _selectedDate.month == today.month && _selectedDate.day == today.day;
    final isYesterday = _selectedDate.year == yesterday.year && _selectedDate.month == yesterday.month && _selectedDate.day == yesterday.day;
    final isLast = _selectedDate.year == last.year && _selectedDate.month == last.month && _selectedDate.day == last.day;
    final isCustom = !isToday && !isYesterday && !isLast;
    final primaryAccent = isDark ? Theme.of(context).colorScheme.primary : AppColors.primary;

    return Row(
      children: [
        // Today Chip
        Expanded(
          child: _quickDateChip(
            dateText: '${today.month}/${today.day}',
            labelText: 'today',
            isSelected: isToday,
            isDark: isDark,
            onTap: () => setState(() => _selectedDate = DateTime.now()),
          ),
        ),
        const SizedBox(width: 8),

        // Yesterday Chip
        Expanded(
          child: _quickDateChip(
            dateText: '${yesterday.month}/${yesterday.day}',
            labelText: 'yesterday',
            isSelected: isYesterday,
            isDark: isDark,
            onTap: () => setState(() => _selectedDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 12, 0)),
          ),
        ),
        const SizedBox(width: 8),

        // Last (2 days ago) Chip
        Expanded(
          child: _quickDateChip(
            dateText: '${last.month}/${last.day}',
            labelText: 'last',
            isSelected: isLast,
            isDark: isDark,
            onTap: () => setState(() => _selectedDate = DateTime(last.year, last.month, last.day, 12, 0)),
          ),
        ),
        const SizedBox(width: 8),

        // Custom Date Calendar Icon Button
        InkWell(
          onTap: _openDatePicker,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCustom
                  ? primaryAccent
                  : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCustom ? primaryAccent : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                width: isCustom ? 2 : 1,
              ),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: isCustom ? Colors.white : primaryAccent,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickDateChip({
    required String dateText,
    required String labelText,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryAccent = isDark ? Theme.of(context).colorScheme.primary : AppColors.primary;
    final activeBg = isDark ? primaryAccent.withValues(alpha: 0.25) : primaryAccent;
    final inactiveBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final borderColor = isSelected ? primaryAccent : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? (isDark ? primaryAccent : Colors.white) : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              labelText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? (isDark ? primaryAccent.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85))
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
