import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/currency_picker_dialog.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../providers/settings_provider.dart';

class CurrencyAccountsSettingsScreen extends StatelessWidget {
  const CurrencyAccountsSettingsScreen({super.key});

  Future<void> _showCurrencyPicker(BuildContext context, SettingsProvider settings) async {
    final picked = await CurrencyPickerDialog.show(
      context,
      selectedCurrency: settings.currency,
    );
    if (picked != null) {
      settings.setCurrency(picked);
    }
  }

  void _showPrimaryAccountPicker(BuildContext context, AccountProvider accountProvider, SettingsProvider settings) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final activeAccounts = accountProvider.accountsWithBalances
            .where((a) => !a.account.isArchived)
            .map((a) => a.account)
            .toList();

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
                    'Select Primary Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Divider(color: isDark ? AppColors.darkBorderSubtle : null),
                if (activeAccounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No accounts available', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  )
                else
                  ...activeAccounts.map((acc) {
                    final isSelected = acc.id == settings.primaryAccountId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                        child: Icon(Icons.account_balance_wallet_rounded, color: primaryAccent, size: 20),
                      ),
                      title: Text(
                        acc.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? primaryAccent : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      subtitle: Text(
                        acc.accountType.name.toUpperCase(),
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: primaryAccent)
                          : null,
                      onTap: () {
                        settings.setPrimaryAccountId(acc.id);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDashboardAccountPicker(BuildContext context, AccountProvider accountProvider, SettingsProvider settings) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final activeAccounts = accountProvider.accountsWithBalances
            .where((a) => !a.account.isArchived)
            .toList();

        final isAllAccounts = settings.dashboardFocus == DashboardFocusMode.allAccounts;
        final currentSelectedId = settings.dashboardFocus == DashboardFocusMode.selectedAccount
            ? (settings.dashboardSelectedAccountId ?? settings.primaryAccountId)
            : (isAllAccounts ? null : settings.primaryAccountId);

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
                    'Select Dashboard View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Divider(color: isDark ? AppColors.darkBorderSubtle : null),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: CircleAvatar(
                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                    child: Icon(Icons.all_inclusive_rounded, color: primaryAccent, size: 20),
                  ),
                  title: Text(
                    'All Accounts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isAllAccounts ? FontWeight.w700 : FontWeight.w500,
                      color: isAllAccounts ? primaryAccent : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                  subtitle: Text(
                    'Combined dashboard balances, income, expenses & charts across all accounts',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  trailing: isAllAccounts
                      ? Icon(Icons.check_circle_rounded, color: primaryAccent)
                      : null,
                  onTap: () {
                    settings.setDashboardFocus(DashboardFocusMode.allAccounts);
                    settings.setDashboardSelectedAccountId(null);
                    Navigator.pop(ctx);
                  },
                ),
                Divider(height: 1, indent: 68, endIndent: 20, color: isDark ? AppColors.darkBorderSubtle : null),
                if (activeAccounts.isNotEmpty)
                  ...activeAccounts.map((accWithBal) {
                    final acc = accWithBal.account;
                    final isSelected = !isAllAccounts && (acc.id == currentSelectedId);
                    final color = acc.color != null ? Color(acc.color!) : primaryAccent;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(acc.iconData, color: color, size: 20),
                      ),
                      title: Text(
                        acc.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? primaryAccent : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      subtitle: Text(
                        '${acc.accountType.name.toUpperCase()} • ${accWithBal.calculatedBalance.format(currency: settings.currency)}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: primaryAccent)
                          : null,
                      onTap: () {
                        settings.setDashboardFocus(DashboardFocusMode.selectedAccount);
                        settings.setDashboardSelectedAccountId(acc.id);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;

    final currInfo = settings.currency;

    final primaryAcc = accountProvider.accountsWithBalances
        .where((a) => a.account.id == settings.primaryAccountId)
        .firstOrNull
        ?.account;

    final dashboardSelectedAcc = settings.dashboardFocus == DashboardFocusMode.selectedAccount
        ? accountProvider.accountsWithBalances
            .where((a) => a.account.id == (settings.dashboardSelectedAccountId ?? settings.primaryAccountId))
            .firstOrNull
            ?.account
        : null;

    final String dashboardFocusLabel;
    if (settings.dashboardFocus == DashboardFocusMode.allAccounts) {
      dashboardFocusLabel = 'All Accounts (Combined view)';
    } else if (dashboardSelectedAcc != null) {
      dashboardFocusLabel = '${dashboardSelectedAcc.name} (Single account filter)';
    } else if (primaryAcc != null) {
      dashboardFocusLabel = '${primaryAcc.name} (Primary account filter)';
    } else {
      dashboardFocusLabel = 'All Accounts (Combined view)';
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: 'Currency & Accounts',
              showBackButton: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Currency Configuration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => _showCurrencyPicker(context, settings),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  currInfo.symbol,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: primaryAccent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Application Currency',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${currInfo.name} (${currInfo.code})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currInfo.code,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primaryAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Default Account Preferences',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // 1. Primary Account for New Transactions
                        InkWell(
                          onTap: () => _showPrimaryAccountPicker(context, accountProvider, settings),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.star_outline_rounded,
                                    color: primaryAccent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Primary Account (New Transactions)',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        primaryAcc != null
                                            ? '${primaryAcc.name} (Default account for new entries)'
                                            : 'First active account (Default)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, size: 22),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, indent: 74, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        // 2. Dashboard Account Filter (with All Accounts option)
                        InkWell(
                          onTap: () => _showDashboardAccountPicker(context, accountProvider, settings),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.dashboard_customize_rounded,
                                    color: primaryAccent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dashboard Account Filter',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dashboardFocusLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, size: 22),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
