import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transfers/presentation/screens/transfer_history_screen.dart';
import '../../../transfers/presentation/screens/transfer_screen.dart';
import '../providers/account_provider.dart';
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
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
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
          // 1. Brand-colored Curved Header with Sidebar Hamburger and Centered Title
          AppHeader(
            showBackButton: false,
            centerTitle: true,
            title: 'Accounts',
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
          ),

          // 2. Scrollable Body
          Expanded(
            child: accountProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => accountProvider.loadAccounts(includeArchived: _showArchived),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                      children: [
                        // Total Balance Display
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalBalanceFormatted,
                                style: AppTypography.displayLarge.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Two Transfer Action Buttons: [ Transfer History ] & [ New Transfer ]
                        Row(
                          children: [
                            // Transfer History Action
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const TransferHistoryScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.history_rounded,
                                          color: primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Transfer history',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // New Transfer Action
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final result = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => const TransferScreen(),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    accountProvider.loadAccounts(includeArchived: _showArchived);
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.send_rounded,
                                          color: primaryColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'New transfer',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Account List Header / Rows
                        if (accounts.isEmpty)
                          const EmptyState(
                            icon: Icons.account_balance_rounded,
                            title: 'No Accounts Found',
                            subtitle: 'Tap the + button to create your first financial account.',
                          )
                        else
                          ...accounts.map((accItem) {
                            final acc = accItem.account;
                            final balanceFormatted = accItem.calculatedBalance.format(currency: settings.currency);
                            final color = acc.color != null
                                ? Color(acc.color!)
                                : primaryColor;

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
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(acc.iconData, color: color, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        acc.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      balanceFormatted,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'accounts_fab',
        backgroundColor: AppColors.floatingAction,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AddEditAccountScreen(),
            ),
          );
          if (added == true && mounted) {
            accountProvider.loadAccounts(includeArchived: _showArchived);
          }
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
