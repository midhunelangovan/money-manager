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
import '../../../transfers/presentation/screens/transfer_screen.dart';
import '../../domain/entities/account.dart';
import '../providers/account_provider.dart';
import '../widgets/edit_account_balance_dialog.dart';
import 'add_edit_account_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  List<LedgerItem> _accountTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final txProvider = context.read<TransactionProvider>();
      final items = await txProvider.getItemsForRange(
        accountId: widget.account.id,
      );

      if (mounted) {
        setState(() {
          _accountTransactions = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load account transactions: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Retrieve the authoritative calculated balance from AccountProvider
    final accountItem = accountProvider.accountsWithBalances
        .where((a) => a.account.id == widget.account.id)
        .firstOrNull;

    final currentAccount = accountItem?.account ?? widget.account;
    final balance = accountItem?.calculatedBalance ?? currentAccount.openingBalance;
    final color = currentAccount.color != null ? Color(currentAccount.color!) : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Header with Account Name, Type & Balance
          AppHeader(
            showBackButton: true,
            title: currentAccount.name,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                tooltip: 'Edit Account Details',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditAccountScreen(account: currentAccount),
                    ),
                  );
                  _loadAccountData();
                },
              ),
            ],
            bottom: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(currentAccount.iconData, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT BALANCE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.8,
                          ),
                        ),
                        InkWell(
                          onTap: accountItem != null
                              ? () async {
                                  await EditAccountBalanceDialog.show(context, accountItem);
                                  _loadAccountData();
                                }
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                balance.format(currency: settings.currency),
                                style: AppTypography.displayMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_outlined, size: 16, color: Colors.white70),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transfer Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => TransferScreen(
                            initialFromAccountId: currentAccount.id,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _loadAccountData();
                      }
                    },
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                      size: 20,
                    ),
                    label: Text(
                      'Transfer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Transactions Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRANSACTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '${_accountTransactions.length} ${_accountTransactions.length == 1 ? 'Record' : 'Records'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
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
                                onPressed: _loadAccountData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : (_accountTransactions.isEmpty
                        ? const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Transactions for this Account',
                            subtitle: 'Transactions linked to this account will appear here.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAccountData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _accountTransactions.length,
                              itemBuilder: (context, index) {
                                final item = _accountTransactions[index];
                                final dateStr = DateFormatter.formatShort(item.date);
                                final amountFormatted = Money.fromUnits(item.amountUnits).format(currency: settings.currency);

                                String title = item.description;
                                String subtitle = '';
                                if (item.type == LedgerItemType.transfer) {
                                  final isOutgoing = item.accountId == currentAccount.id;
                                  title = item.description.isNotEmpty ? item.description : 'Transfer';
                                  subtitle = isOutgoing
                                      ? 'To: ${item.destinationAccountName ?? 'Account'}'
                                      : 'From: ${item.accountName ?? 'Account'}';
                                } else {
                                  title = item.description.isNotEmpty ? item.description : (item.categoryName ?? 'Transaction');
                                  subtitle = item.categoryName ?? (item.type == LedgerItemType.income ? 'Income' : 'Expense');
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AppCard(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        // Date Badge
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

                                        // Title & Subtitle
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                subtitle,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.notes!,
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

                                        // Neutral Amount Display
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
