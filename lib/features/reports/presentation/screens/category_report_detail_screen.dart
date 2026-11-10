import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_category_icon.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/screens/add_edit_transaction_screen.dart';

class CategoryReportDetailScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final DateTime startDate;
  final DateTime endDate;
  final String periodTitle;
  final String? accountId;
  final String? accountName;

  const CategoryReportDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.startDate,
    required this.endDate,
    required this.periodTitle,
    this.accountId,
    this.accountName,
  });

  @override
  State<CategoryReportDetailScreen> createState() => _CategoryReportDetailScreenState();
}

class _CategoryReportDetailScreenState extends State<CategoryReportDetailScreen> {
  List<LedgerItem> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final txProvider = context.read<TransactionProvider>();
      final allItems = await txProvider.getItemsForRange(
        startDate: widget.startDate,
        endDate: widget.endDate,
        exclusiveEndDate: true,
        accountId: widget.accountId,
      );

      final filtered = allItems.where((i) => i.categoryId == widget.categoryId).toList();

      if (mounted) {
        setState(() {
          _transactions = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load transactions: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalUnits = 0;
    for (final item in _transactions) {
      totalUnits += item.amountUnits;
    }
    final totalMoney = Money.fromUnits(totalUnits);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Header with Category Info, Period and Total
          AppHeader(
            showBackButton: true,
            title: widget.categoryName,
            bottom: Column(
              children: [
                Text(
                  widget.accountName != null
                      ? '${widget.periodTitle} • ${widget.accountName}'
                      : widget.periodTitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppCategoryIcon(
                      icon: widget.categoryIcon,
                      color: Colors.white,
                      backgroundColor: widget.categoryColor.withValues(alpha: 0.3),
                      size: 44,
                      iconSize: 24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalMoney.format(currency: settings.currency),
                          style: AppTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${_transactions.length} ${_transactions.length == 1 ? 'Transaction' : 'Transactions'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : (_errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 48),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.expense)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTransactions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : (_transactions.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_rounded,
                            title: 'No Transactions Found',
                            subtitle: 'No transactions found for ${widget.categoryName} in ${widget.periodTitle}.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final tx = _transactions[index];
                                final dateStr = DateFormatter.formatShort(tx.date);
                                final amountFormatted = Money.fromUnits(tx.amountUnits).format(currency: settings.currency);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AppCard(
                                    onTap: () async {
                                      final changed = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => AddEditTransactionScreen(transaction: tx),
                                        ),
                                      );
                                      if (changed == true && mounted) {
                                        await _loadTransactions();
                                      }
                                    },
                                    onLongPress: () async {
                                      final action = await showModalBottomSheet<String>(
                                        context: context,
                                        backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        builder: (ctx) => SafeArea(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(height: 8),
                                              Container(
                                                width: 36,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white24 : Colors.black12,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.edit_rounded),
                                                title: const Text('Edit Transaction'),
                                                onTap: () => Navigator.pop(ctx, 'edit'),
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                                                title: const Text('Delete Transaction', style: TextStyle(color: AppColors.expense)),
                                                onTap: () => Navigator.pop(ctx, 'delete'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );

                                      if (action == 'edit' && mounted) {
                                        final changed = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => AddEditTransactionScreen(transaction: tx),
                                          ),
                                        );
                                        if (changed == true && mounted) {
                                          await _loadTransactions();
                                        }
                                      } else if (action == 'delete' && mounted) {
                                        final confirmed = await TransactionDeleteConfirmationDialog.show(
                                          context,
                                          amount: Money.fromUnits(tx.amountUnits),
                                          accountName: tx.accountName ?? 'Account',
                                          categoryName: widget.categoryName,
                                          date: tx.date,
                                          description: tx.description,
                                        );
                                        if (confirmed == true && mounted) {
                                          try {
                                            await context.read<TransactionProvider>().deleteTransaction(tx.id);
                                            await context.read<AccountProvider>().loadAccounts();
                                            await _loadTransactions();
                                            if (mounted) {
                                              AppSnackBar.showSuccess(context, 'Transaction deleted successfully.');
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              AppSnackBar.showError(context, 'Failed to delete transaction: $e');
                                            }
                                          }
                                        }
                                      }
                                    },
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          // Date Column
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSelectedBackground,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Details Column
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tx.description.isNotEmpty ? tx.description : widget.categoryName,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  tx.accountName ?? 'Account',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (tx.notes != null && tx.notes!.trim().isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    tx.notes!,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontStyle: FontStyle.italic,
                                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Neutral Amount
                                          Text(
                                            amountFormatted,
                                            style: AppTypography.amountMedium.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                              },
                            ),
                          ))),
          ),
        ],
      ),
    );
  }
}
