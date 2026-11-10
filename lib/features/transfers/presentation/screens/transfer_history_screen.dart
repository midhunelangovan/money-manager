import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/transfer.dart';
import '../providers/transfer_provider.dart';
import 'transfer_screen.dart';

class TransferHistoryScreen extends StatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransferProvider>().loadTransfers();
    });
  }

  Future<void> _deleteTransfer(Transfer transfer) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Transfer?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'This will reverse this transfer of ${transfer.amount.format()} and restore the balances of both accounts.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final transferProvider = context.read<TransferProvider>();
      final accountProvider = context.read<AccountProvider>();
      final txProvider = context.read<TransactionProvider>();

      try {
        await transferProvider.deleteTransfer(transfer.id);
        await accountProvider.loadAccounts();
        await txProvider.loadLedger();

        if (mounted) {
          AppSnackBar.showSuccess(context, 'Transfer deleted and balances restored.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to delete transfer: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.watch<TransferProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final transfers = transferProvider.transfers;
    final accountMap = {
      for (final a in accountProvider.accountsWithBalances) a.account.id: a.account.name
    };

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          AppHeader(
            title: 'Transfer History',
            showBackButton: true,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                tooltip: 'New Transfer',
                onPressed: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const TransferScreen()),
                  );
                  if (added == true && mounted) {
                    transferProvider.loadTransfers();
                  }
                },
              ),
            ],
          ),
          Expanded(
            child: transferProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        transferProvider.loadTransfers(),
                        accountProvider.loadAccounts(),
                      ]);
                    },
                    child: transfers.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: EmptyState(
                                icon: Icons.swap_horiz_rounded,
                                title: 'No Transfers Found',
                                subtitle: 'Transfers between your accounts will be recorded here.',
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: transfers.length,
                            separatorBuilder: (_, i) => const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final item = transfers[index];
                              final fromName = item.fromAccountName ?? accountMap[item.fromAccountId] ?? 'Source Account';
                              final toName = item.toAccountName ?? accountMap[item.toAccountId] ?? 'Destination Account';
                              final formattedAmount = item.amount.format(currency: settings.currency);
                              final formattedDate = DateFormatter.formatDate(item.date);

                              return AppCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.transfer.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.swap_horiz_rounded,
                                                color: AppColors.transfer,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              formattedAmount,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.transfer,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                              tooltip: 'Delete Transfer',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              onPressed: () => _deleteTransfer(item),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkInputSurface : AppColors.lightInputSurface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fromName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8),
                                            child: Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                              color: AppColors.transfer,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              toName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                              textAlign: TextAlign.end,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.description.isNotEmpty && item.description != 'Account Transfer' && item.description != 'Transfer') ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        item.description,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w400,
                                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
