import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/date_wise_timeline.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transfers/presentation/providers/transfer_provider.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_provider.dart';
import 'add_edit_transaction_screen.dart';

/// Screen displayed when tapping the center of the dashboard pie/donut chart.
///
/// Shows all transactions matching the currently active period and account scope,
/// using the exact same database query rules and totals as the dashboard.
class PeriodTransactionsScreen extends StatelessWidget {
  final String title;
  final String dateRangeLabel;
  final int startMillis;
  final int endMillis;
  final String? accountId;
  final String accountName;
  final LedgerItemType? typeFilter;

  const PeriodTransactionsScreen({
    super.key,
    required this.title,
    required this.dateRangeLabel,
    required this.startMillis,
    required this.endMillis,
    this.accountId,
    this.accountName = 'All Accounts',
    this.typeFilter,
  });

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sourceItems = txProvider.allLedgerItems.isNotEmpty
        ? txProvider.allLedgerItems
        : txProvider.ledgerItems;

    // Filter items matching type, date range [start, end), and account scope
    final matchingItems = sourceItems.where((item) {
      if (typeFilter != null && item.type != typeFilter) return false;
      final itemMillis = item.date.millisecondsSinceEpoch;
      if (itemMillis < startMillis || itemMillis >= endMillis) return false;
      if (accountId != null && item.accountId != accountId) return false;
      return true;
    }).toList();

    // Calculate total amount for this period (excluding transfers from pure income/expense totals)
    int totalUnits = 0;
    for (final item in matchingItems) {
      if (item.type != LedgerItemType.transfer) {
        totalUnits += item.amountUnits;
      }
    }
    final formattedTotal = Money.fromUnits(totalUnits).format(currency: settings.currency);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // App Header with Screen Title, Total Amount & Filter Chips
          AppHeader(
            title: title,
            showBackButton: true,
            bottom: Column(
              children: [
                const SizedBox(height: 4),
                // Prominent Total Amount
                Text(
                  formattedTotal,
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Period & Account Scope Subtitle Chips
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dateRangeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (accountName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          accountName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${matchingItems.length} transactions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Date-Grouped Transactions Timeline Body
          Expanded(
            child: matchingItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primary,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No transactions found for $dateRangeLabel in $accountName.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    children: [
                      DateGroupedTransactionTimeline(
                        transactions: matchingItems,
                        onItemTap: (item) async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AddEditTransactionScreen(
                                transaction: item,
                              ),
                            ),
                          );

                          if (changed == true && context.mounted) {
                            await Future.wait([
                              accountProvider.loadAccounts(),
                              txProvider.loadLedger(),
                            ]);
                          }
                        },
                        onItemDelete: (item) async {
                          try {
                            if (item.type == LedgerItemType.transfer) {
                              await context.read<TransferProvider>().deleteTransfer(item.id);
                            } else {
                              await context.read<TransactionProvider>().deleteTransaction(item.id);
                            }
                            if (context.mounted) {
                              await Future.wait([
                                accountProvider.loadAccounts(),
                                txProvider.loadLedger(),
                              ]);
                              AppSnackBar.showSuccess(context, 'Transaction deleted successfully.');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppSnackBar.showError(context, 'Failed to delete transaction: $e');
                            }
                          }
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
