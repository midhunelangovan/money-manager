import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.categoryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.categoryColor.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(widget.categoryIcon, color: Colors.white, size: 22),
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
                            icon: Icons.receipt_long_outlined,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        // Date Column
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8EEF5),
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
