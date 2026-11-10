import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/services/attachment_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_bottom_button.dart';
import '../../../../core/widgets/app_category_icon.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_dialog.dart';
import '../../../../core/widgets/photo_preview_dialog.dart';
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
  late FocusNode _amountFocusNode;

  String? _selectedAccountId;
  String? _selectedDestinationAccountId;
  String? _selectedCategoryId;
  String? _receiptPath;
  bool _isSaving = false;
  DateTime? _createdAt;

  // Tracking baseline snapshot to detect unsaved changes
  late EntryMode _initialMode;
  late String _initialAmountText;
  late String _initialDescriptionText;
  late DateTime _initialDate;
  String? _initialAccountId;
  String? _initialDestinationAccountId;
  String? _initialCategoryId;
  String? _initialReceiptPath;
  bool _isSaved = false;
  bool _isShowingDiscardDialog = false;

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();

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

    // Capture initial snapshot
    _initialMode = _mode;
    _initialAmountText = _amountController.text.trim();
    _initialDescriptionText = _descriptionController.text.trim();
    _initialDate = _selectedDate;
    _initialAccountId = _selectedAccountId;
    _initialDestinationAccountId = _selectedDestinationAccountId;
    _initialCategoryId = _selectedCategoryId;
    _initialReceiptPath = _receiptPath;
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.transaction != null || widget.initialTransaction != null || widget.initialTransfer != null;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Determines whether the user has entered or modified details in the form.
  bool get _isDirty {
    if (_isSaved) return false;
    if (!_isEditing) {
      final hasAmount = _amountController.text.trim().isNotEmpty &&
          (double.tryParse(_amountController.text.trim()) ?? 0.0) > 0;
      final hasDescription = _descriptionController.text.trim().isNotEmpty;
      final hasCategory = _selectedCategoryId != null;
      final hasReceipt = _receiptPath != null && _receiptPath!.isNotEmpty;
      final modeChanged = _mode != _initialMode;
      final dateChanged = !_isSameDay(_selectedDate, _initialDate);
      final accountChanged = _initialAccountId != null && _selectedAccountId != _initialAccountId;
      final destAccountChanged = _selectedDestinationAccountId != null;

      return hasAmount ||
          hasDescription ||
          hasCategory ||
          hasReceipt ||
          modeChanged ||
          dateChanged ||
          accountChanged ||
          destAccountChanged;
    } else {
      final amountChanged = _amountController.text.trim() != _initialAmountText;
      final descChanged = _descriptionController.text.trim() != _initialDescriptionText;
      final modeChanged = _mode != _initialMode;
      final catChanged = _selectedCategoryId != _initialCategoryId;
      final accChanged = _selectedAccountId != _initialAccountId;
      final destAccChanged = _selectedDestinationAccountId != _initialDestinationAccountId;
      final dateChanged = !_isSameDay(_selectedDate, _initialDate);
      final receiptChanged = _receiptPath != _initialReceiptPath;

      return amountChanged ||
          descChanged ||
          modeChanged ||
          catChanged ||
          accChanged ||
          destAccChanged ||
          dateChanged ||
          receiptChanged;
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty || _isSaved) return true;
    if (_isShowingDiscardDialog) return false;
    _isShowingDiscardDialog = true;
    try {
      final shouldDiscard = await DiscardChangesDialog.show(context);
      return shouldDiscard == true;
    } finally {
      _isShowingDiscardDialog = false;
    }
  }

  Future<void> _confirmDeleteTransaction() async {
    if (!_isEditing) return;
    final catProvider = context.read<CategoryProvider>();
    final cat = catProvider.categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final accProvider = context.read<AccountProvider>();
    final account = accProvider.accounts.where((a) => a.id == _selectedAccountId).firstOrNull;

    final parsedAmount = (double.tryParse(_amountController.text.trim()) ?? 0.0);
    final amount = Money.fromUnits((parsedAmount * 100).round());

    final confirmed = await TransactionDeleteConfirmationDialog.show(
      context,
      amount: amount,
      accountName: account?.name ?? 'Account',
      categoryName: cat?.name ?? (_mode == EntryMode.income ? 'Income' : (_mode == EntryMode.expense ? 'Expense' : 'Transfer')),
      date: _selectedDate,
      description: _descriptionController.text.trim(),
    );

    if (confirmed == true && mounted) {
      final txProvider = context.read<TransactionProvider>();
      final transferProvider = context.read<TransferProvider>();

      final txId = widget.transaction?.id ?? widget.initialTransaction?.id;
      final transferId = widget.transaction?.id ?? widget.initialTransfer?.id;

      try {
        if (_mode == EntryMode.transfer && transferId != null) {
          await transferProvider.deleteTransfer(transferId);
        } else if (txId != null) {
          await txProvider.deleteTransaction(txId);
        }

        await accProvider.loadAccounts();
        await txProvider.loadLedger();

        _isSaved = true;
        if (mounted) {
          Navigator.of(context).pop(true);
          final rootContext = MainNavigationService.navigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            final entryLabel = _mode == EntryMode.income
                ? 'Income'
                : (_mode == EntryMode.expense ? 'Expense' : 'Transfer');
            AppSnackBar.showSuccess(rootContext, '$entryLabel deleted successfully.');
          }
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to delete transaction: $e');
        }
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
        case LedgerTabType.all:
          _mode = EntryMode.expense;
          _selectedCategoryId = null;
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
          selectedCategoryId: _selectedCategoryId,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCategoryId = selected.id;
        if (selected.type == CategoryType.income) {
          _mode = EntryMode.income;
        } else if (selected.type == CategoryType.expense) {
          _mode = EntryMode.expense;
        }
      });
    }
  }

  void _showAccountPicker(BuildContext context, bool isDestination) {
    final accountProvider = context.read<AccountProvider>();
    final accounts = accountProvider.accountsWithBalances;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    isDestination ? 'Select Destination Account' : 'Select Account',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Divider(color: isDark ? AppColors.darkBorderSubtle : null),
                Expanded(
                  child: ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (ctx, idx) {
                      final accWithBal = accounts[idx];
                      final acc = accWithBal.account;
                      final isSelected = isDestination
                          ? acc.id == _selectedDestinationAccountId
                          : acc.id == _selectedAccountId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                          child: Icon(
                            Icons.account_balance_rounded,
                            color: isDark ? Theme.of(context).colorScheme.primary : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          acc.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                        subtitle: Text(
                          accWithBal.calculatedBalance.format(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary)
                            : null,
                        onTap: () {
                          setState(() {
                            if (isDestination) {
                              _selectedDestinationAccountId = acc.id;
                            } else {
                              _selectedAccountId = acc.id;
                            }
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
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
                  'Attach Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Divider(color: isDark ? AppColors.darkBorderSubtle : null),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                  child: Icon(Icons.photo_camera_rounded, color: isDark ? theme.colorScheme.primary : AppColors.primary),
                ),
                title: Text(
                  'Take Photo (Camera)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await AttachmentService.pickAndSaveImage(ImageSource.camera);
                  if (path != null) {
                    setState(() => _receiptPath = path);
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                  child: Icon(Icons.photo_library_rounded, color: isDark ? theme.colorScheme.primary : AppColors.primary),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await AttachmentService.pickAndSaveImage(ImageSource.gallery);
                  if (path != null) {
                    setState(() => _receiptPath = path);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      AppSnackBar.showError(context, 'Please enter an amount.');
      return;
    }

    final amountDouble = double.tryParse(amountText);
    if (amountDouble == null || amountDouble <= 0) {
      AppSnackBar.showError(context, 'Please enter a valid positive amount.');
      return;
    }

    if (_selectedAccountId == null) {
      AppSnackBar.showError(context, 'Please select an account.');
      return;
    }

    if (_mode == EntryMode.transfer) {
      if (_selectedDestinationAccountId == null) {
        AppSnackBar.showError(context, 'Please select a destination account.');
        return;
      }
      if (_selectedAccountId == _selectedDestinationAccountId) {
        AppSnackBar.showError(context, 'Source and destination accounts must be different.');
        return;
      }
    } else {
      if (_selectedCategoryId == null) {
        AppSnackBar.showError(context, 'Please select a category.');
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

      String? savedTxId;
      String? savedTransferId;

      if (_mode == EntryMode.transfer) {
        final transferId = widget.initialTransfer?.id ?? widget.transaction?.id ?? IdGenerator.uuid();
        savedTransferId = transferId;
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
        savedTxId = txId;
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

      if (mounted) {
        final isNewEntry = !_isEditing;
        final entryLabel = _mode == EntryMode.expense
            ? 'Expense'
            : (_mode == EntryMode.income ? 'Income' : 'Transfer');

        _isSaved = true;
        navigator.pop(true);
        accProvider.loadAccounts();
        txProvider.loadLedger();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final rootContext = MainNavigationService.navigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            if (isNewEntry) {
              AppSnackBar.showSuccessWithUndo(
                rootContext,
                message: '$entryLabel added successfully.',
                onUndo: () async {
                  if (savedTxId != null) {
                    await txProvider.deleteTransaction(savedTxId);
                  } else if (savedTransferId != null) {
                    await transferProvider.deleteTransfer(savedTransferId);
                  }
                  await accProvider.loadAccounts();
                  await txProvider.loadLedger();

                  final currentCtx = MainNavigationService.navigatorKey.currentContext;
                  if (currentCtx != null && currentCtx.mounted) {
                    AppSnackBar.showInfo(currentCtx, '$entryLabel addition undone.');
                  }
                },
              );
            } else {
              AppSnackBar.showSuccess(
                rootContext,
                '$entryLabel updated successfully.',
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final currencyCode = settings.currencyCode;
    final accountProvider = context.watch<AccountProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Resolve default account if unselected
    if (_selectedAccountId == null && accountProvider.accounts.isNotEmpty) {
      String? defaultAccId;
      try {
        defaultAccId = settings.primaryAccountId;
      } catch (_) {}
      final isValidDefault = defaultAccId != null && accountProvider.accounts.any((a) => a.id == defaultAccId);
      _selectedAccountId = isValidDefault ? defaultAccId : accountProvider.accounts.first.id;
      _initialAccountId ??= _selectedAccountId;
    }

    final selectedAccount = accountProvider.accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
    final selectedDestAccount = accountProvider.accounts.where((a) => a.id == _selectedDestinationAccountId).firstOrNull;

    // Filter categories for active mode (Expenses / Income)
    final activeCatType = _mode == EntryMode.income ? CategoryType.income : CategoryType.expense;
    final modeCategories = categoryProvider.categories.where((c) => c.type == activeCatType).toList();

    // Reconstruct 8 items for Wireframe B:
    // Row 1: Split Pays, Food, Repays, Invest.
    // Row 2: Transp., Family, Transfers, More
    final gridItems = _buildWireframeCategories(modeCategories);

    return PopScope(
      canPop: !_isDirty || _isSaved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _onWillPop();
        if (shouldDiscard && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Column(
          children: [
            // 1. Curved Brand Header with Integrated EXPENSES / INCOME Tabs
            AppHeader(
              title: _isEditing ? 'Edit Transaction' : 'Add Transactions',
              centerTitle: false,
              actions: [
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                    tooltip: 'Delete Transaction',
                    onPressed: _confirmDeleteTransaction,
                  ),
              ],
              bottom: TransactionTypeTabs(
                selectedTab: _tabType,
                onTabSelected: _onTabChanged,
                isHeaderStyle: true,
                showTransfer: true,
                showAll: false,
              ),
            ),

          // Scrollable Form Body with background tap to unfocus
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                children: [
                  // 2. Amount Entry Row (Minimal, centered, transparent background, thin underline)
                  Center(
                    child: Theme(
                      data: theme.copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          filled: false,
                          fillColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                        ),
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                          selectionColor: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.2),
                          selectionHandleColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: IntrinsicWidth(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 32),
                                  child: TextField(
                                    controller: _amountController,
                                    focusNode: _amountFocusNode,
                                    autofocus: !_isEditing,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      height: 1.15,
                                    ),
                                    textAlign: TextAlign.center,
                                    cursorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                                    cursorWidth: 2.0,
                                    cursorHeight: 36.0,
                                    cursorRadius: const Radius.circular(1.0),
                                    decoration: InputDecoration(
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      hintText: '0',
                                      hintStyle: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        height: 1.15,
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              currencyCode,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.calculate_rounded),
                              iconSize: 26,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              onPressed: _openCalculator,
                              tooltip: 'Calculator',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 3. Account Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _showAccountPicker(context, false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              selectedAccount?.name ?? 'Select Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Destination Account if Transfer mode
                if (_mode == EntryMode.transfer) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destination Account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _showAccountPicker(context, true),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                selectedDestAccount?.name ?? 'Select Destination Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // 4. Categories Section Label & 4-Column Grid
                if (_mode != EntryMode.transfer) ...[
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gridItems.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (ctx, idx) {
                      final item = gridItems[idx];
                      final isSelected = !item.isMore && !item.isTransfer && item.categoryId != null && item.categoryId == _selectedCategoryId;
                      final brandTeal = isDark ? AppColors.darkPrimary : AppColors.primary;

                      return GestureDetector(
                        onTap: () {
                          if (item.isMore) {
                            _showAllCategoriesSheet(modeCategories);
                          } else if (item.isTransfer) {
                            setState(() => _mode = EntryMode.transfer);
                          } else if (item.categoryId != null) {
                            setState(() => _selectedCategoryId = item.categoryId);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (item.isMore)
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE2EFF1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    item.icon,
                                    size: 26,
                                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  ),
                                ),
                              )
                            else
                              AppCategoryIcon(
                                icon: item.icon,
                                color: item.color,
                                size: 52,
                                iconSize: 26,
                                isSelected: isSelected,
                              ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 32,
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? brandTeal
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Date Shortcuts Section ([MM/dd today], [MM/dd yesterday], [MM/dd previous], [Calendar])
                _buildDateShortcuts(isDark),

                const SizedBox(height: 24),

                // 6. Comment Section (Integrated warm neutral surface)
                AppTextField(
                  controller: _descriptionController,
                  label: 'Comment',
                  hintText: 'Add a note...',
                  maxLines: 2,
                  minLines: 1,
                ),

                const SizedBox(height: 24),

                // 7. Photo Attachments Section
                _buildPhotoSection(isDark),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

          // 8. Bottom Add Button (Warm yellow wide pill button)
          AppBottomButton(
            label: _isEditing ? 'Save' : 'Add',
            onPressed: _save,
            isLoading: _isSaving,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDateShortcuts(bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final previousDay = today.subtract(const Duration(days: 2));

    final selDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isTodaySelected = selDay == today;
    final isYesterdaySelected = selDay == yesterday;
    final isPreviousSelected = selDay == previousDay;
    final isCalendarSelected = !isTodaySelected && !isYesterdaySelected && !isPreviousSelected;

    return Row(
      children: [
        Expanded(
          child: _buildDateTile(
            dateText: DateFormat('MM/dd').format(today),
            label: 'today',
            isSelected: isTodaySelected,
            onTap: () => setState(() => _selectedDate = today),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateTile(
            dateText: DateFormat('MM/dd').format(yesterday),
            label: 'yesterday',
            isSelected: isYesterdaySelected,
            onTap: () => setState(() => _selectedDate = yesterday),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateTile(
            dateText: DateFormat('MM/dd').format(previousDay),
            label: 'previous',
            isSelected: isPreviousSelected,
            onTap: () => setState(() => _selectedDate = previousDay),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _openDatePicker,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: isCalendarSelected
                  ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                  : (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEFEFEA)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCalendarSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : (isDark ? AppColors.darkBorder : const Color(0xFFE5E4DE)),
              ),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: isCalendarSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTile({
    required String dateText,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeBg = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveBg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEFEFEA);
    final borderColor = isSelected
        ? activeBg
        : (isDark ? AppColors.darkBorder : const Color(0xFFE5E4DE));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(bool isDark) {
    final tileBg = isDark ? const Color(0xFF1B3B38) : const Color(0xFFE2EFEF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Tile 1: Attached image or empty +
            if (_receiptPath != null && _receiptPath!.isNotEmpty)
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => PhotoPreviewDialog.show(context, imagePath: _receiptPath!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FutureBuilder<File?>(
                          future: AttachmentService.resolveFile(_receiptPath),
                          builder: (context, snapshot) {
                            final file = snapshot.data;
                            if (file != null && file.existsSync()) {
                              return Image.file(file, fit: BoxFit.cover);
                            }
                            return const Icon(Icons.image_rounded, size: 28, color: AppColors.primary);
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _receiptPath = null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.expense,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            else
              _buildAddPhotoTile(tileBg, isDark),

            const SizedBox(width: 12),
            _buildAddPhotoTile(tileBg, isDark),
            const SizedBox(width: 12),
            _buildAddPhotoTile(tileBg, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildAddPhotoTile(Color tileBg, bool isDark) {
    return InkWell(
      onTap: () => _showImagePickerOptions(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            size: 32,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
          ),
        ),
      ),
    );
  }

  List<_TransactionCategoryItem> _buildWireframeCategories(List<Category> allCategories) {
    final result = <_TransactionCategoryItem>[];

    if (_mode == EntryMode.income) {
      // Income Mode: Use user's real Income categories
      final visibleCats = allCategories.take(6).toList();

      if (_selectedCategoryId != null) {
        final isAlreadyPresent = visibleCats.any((c) => c.id == _selectedCategoryId);
        if (!isAlreadyPresent) {
          final selCat = allCategories.where((c) => c.id == _selectedCategoryId).firstOrNull;
          if (selCat != null) {
            if (visibleCats.length >= 6) {
              visibleCats[visibleCats.length - 1] = selCat;
            } else {
              visibleCats.add(selCat);
            }
          }
        }
      }

      for (final cat in visibleCats) {
        result.add(_TransactionCategoryItem(
          label: cat.name,
          icon: cat.iconData,
          color: cat.color != null ? Color(cat.color!) : const Color(0xFF475569),
          categoryId: cat.id,
        ));
      }
    } else {
      // Expense Mode: Map wireframe definitions strictly to UNIQUE user categories
      final wireframeDefs = [
        (label: 'Split Pays', icon: Icons.call_split_rounded, keywords: ['split', 'share', 'bill']),
        (label: 'Food', icon: Icons.restaurant_rounded, keywords: ['food', 'dining', 'groceries', 'eating']),
        (label: 'Repays', icon: Icons.handshake_rounded, keywords: ['repay', 'debt', 'lend', 'settle']),
        (label: 'Invest.', icon: Icons.trending_up_rounded, keywords: ['invest', 'stock', 'mutual', 'sip']),
        (label: 'Transp.', icon: Icons.directions_car_rounded, keywords: ['transport', 'car', 'fuel', 'cab', 'travel']),
        (label: 'Family', icon: Icons.family_restroom_rounded, keywords: ['family', 'kids', 'contribution', 'home']),
      ];

      final matches = List<Category?>.filled(wireframeDefs.length, null);
      final usedIds = <String>{};

      // Pass 1: Semantic keyword & name matches
      for (var i = 0; i < wireframeDefs.length; i++) {
        final def = wireframeDefs[i];
        for (final cat in allCategories) {
          if (usedIds.contains(cat.id)) continue;
          final name = cat.name.toLowerCase();
          if (name == def.label.toLowerCase() || def.keywords.any((k) => name.contains(k))) {
            matches[i] = cat;
            usedIds.add(cat.id);
            break;
          }
        }
      }

      // Pass 2: Fill remaining empty slots with unassigned categories
      for (var i = 0; i < wireframeDefs.length; i++) {
        if (matches[i] == null) {
          final unassigned = allCategories.where((c) => !usedIds.contains(c.id)).firstOrNull;
          if (unassigned != null) {
            matches[i] = unassigned;
            usedIds.add(unassigned.id);
          }
        }
      }

      for (var i = 0; i < wireframeDefs.length; i++) {
        final def = wireframeDefs[i];
        final matched = matches[i];
        result.add(_TransactionCategoryItem(
          label: def.label,
          icon: matched != null ? matched.iconData : def.icon,
          color: matched?.color != null ? Color(matched!.color!) : const Color(0xFF475569),
          categoryId: matched?.id,
        ));
      }

      // If a category is selected (e.g. editing existing transaction or selected via More)
      // ensure it is visible in the grid rather than hidden
      if (_selectedCategoryId != null) {
        final isAlreadyPresent = result.any((r) => r.categoryId == _selectedCategoryId);
        if (!isAlreadyPresent) {
          final selCat = allCategories.where((c) => c.id == _selectedCategoryId).firstOrNull;
          if (selCat != null && result.isNotEmpty) {
            result[result.length - 1] = _TransactionCategoryItem(
              label: selCat.name,
              icon: selCat.iconData,
              color: selCat.color != null ? Color(selCat.color!) : const Color(0xFF475569),
              categoryId: selCat.id,
            );
          }
        }
      }
    }

    // 7. Transfers
    result.add(const _TransactionCategoryItem(
      label: 'Transfers',
      icon: Icons.swap_horiz_rounded,
      color: AppColors.transfer,
      isTransfer: true,
    ));

    // 8. More
    result.add(const _TransactionCategoryItem(
      label: 'More',
      icon: Icons.more_horiz_rounded,
      isMore: true,
    ));

    return result;
  }
}

class _TransactionCategoryItem {
  final String label;
  final IconData icon;
  final Color? color;
  final String? categoryId;
  final bool isTransfer;
  final bool isMore;

  const _TransactionCategoryItem({
    required this.label,
    required this.icon,
    this.color,
    this.categoryId,
    this.isTransfer = false,
    this.isMore = false,
  });
}
