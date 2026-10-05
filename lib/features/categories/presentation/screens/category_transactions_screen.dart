import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/screens/add_edit_transaction_screen.dart';
import '../../../transactions/presentation/widgets/transaction_list_item.dart';
import '../../domain/entities/category.dart';

class CategoryTransactionsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final CategoryType categoryType;
  final String dateRangeLabel;
  final int startMillis;
  final int endMillis;
  final String? accountId;
  final String accountName;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryType,
    required this.dateRangeLabel,
    required this.startMillis,
    required this.endMillis,
    this.accountId,
    this.accountName = 'All Accounts',
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

    // Filter items matching category, date range, and account scope
    final matchingItems = sourceItems.where((item) {
      if (item.categoryId != categoryId) return false;
      final itemMillis = item.date.millisecondsSinceEpoch;
      if (itemMillis < startMillis || itemMillis > endMillis) return false;
      if (accountId != null && item.accountId != accountId) return false;
      return true;
    }).toList();

    // Calculate total amount for this category in the period
    final totalUnits = matchingItems.fold<int>(0, (sum, item) => sum + item.amountUnits);
    final formattedTotal = Money.fromUnits(totalUnits).format(currency: settings.currency);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // App Header with Category Name, Total Amount & Period
          AppHeader(
            title: categoryName,
            showBackButton: true,
            bottom: Column(
              children: [
                const SizedBox(height: 4),
                // Prominent Total Amount for Category
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    if (accountId != null) ...[
                      const SizedBox(width: 8),
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
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Transactions List Body
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
                              color: categoryColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(categoryIcon, color: categoryColor, size: 34),
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
                            'No $categoryName transactions found for $dateRangeLabel.',
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: matchingItems.length,
                    itemBuilder: (context, index) {
                      final item = matchingItems[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TransactionListItem(
                          item: item,
                          onTap: () async {
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
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transaction updated'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          onDelete: () async {
                            await txProvider.deleteTransaction(item.id);
                            await accountProvider.loadAccounts();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction deleted'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
