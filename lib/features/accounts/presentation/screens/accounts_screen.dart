import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/edit_account_balance_dialog.dart';
import 'account_detail_screen.dart';
import 'add_edit_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    final accounts = accountProvider.accountsWithBalances.where((a) {
      if (_showArchived) return true;
      return !a.account.isArchived;
    }).toList();

    final totalBalanceFormatted = accountProvider.totalBalance.format(currency: settings.currency);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          AppHeader(
            showBackButton: false,
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
            title: 'Accounts',
            actions: [
              IconButton(
                icon: Icon(
                  _showArchived ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white,
                ),
                tooltip: _showArchived ? 'Hide Archived' : 'Show Archived',
                onPressed: () {
                  setState(() => _showArchived = !_showArchived);
                  accountProvider.loadAccounts(includeArchived: _showArchived);
                },
              ),
            ],
            bottom: Column(
              children: [
                const Text(
                  'NET WORTH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalBalanceFormatted,
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          Expanded(
            child: accountProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => accountProvider.loadAccounts(includeArchived: _showArchived),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      children: [
                        if (accounts.isEmpty)
                          const EmptyState(
                            icon: Icons.account_balance_rounded,
                            title: 'No Accounts Found',
                            subtitle: 'Tap the + button to create your first financial account.',
                          )
                        else
                          ...accounts.map((accItem) {
                            final acc = accItem.account;
                            final balance = accItem.calculatedBalance;
                            final color = acc.color != null ? Color(acc.color!) : AppColors.primary;
                            final isPositive = accItem.balanceUnits >= 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AccountDetailScreen(account: acc),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(acc.iconData, color: color, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  acc.name,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (acc.isArchived) ...[
                                                const SizedBox(width: 6),
                                                const StatusBadge.type(label: 'ARCHIVED', type: StatusBadgeType.neutral),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            acc.accountType.displayName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => EditAccountBalanceDialog.show(context, accItem),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              balance.format(currency: settings.currency),
                                              style: AppTypography.amountMedium.copyWith(
                                                color: isPositive
                                                    ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                                    : AppColors.expense,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 15,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditAccountScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}
