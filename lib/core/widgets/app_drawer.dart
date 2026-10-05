import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_service.dart';
import '../../features/accounts/presentation/providers/account_provider.dart';
import '../../features/backup/presentation/screens/integrity_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/recurring/presentation/screens/recurring_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../utilities/money.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accountProvider = context.watch<AccountProvider>();

    final totalBalanceFormatted = Money.fromUnits(accountProvider.totalBalance.units).format(currency: settings.currency);
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeFormatted = '${now.day} ${months[now.month - 1]} ${now.year} · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final drawerBg = isDark ? AppColors.darkSurface : theme.colorScheme.primary;

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Profile & Balance Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.profileName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Balance: $totalBalanceFormatted',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                ],
              ),
            ),

            // 2. Navigation Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      MainNavigationService.navigateToTab(context, 0);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Transactions',
                    onTap: () {
                      Navigator.pop(context);
                      MainNavigationService.navigateToTab(context, 1);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_outlined,
                    label: 'Accounts',
                    onTap: () {
                      Navigator.pop(context);
                      MainNavigationService.navigateToTab(context, 2);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.pie_chart_outline_rounded,
                    label: 'Charts',
                    onTap: () {
                      Navigator.pop(context);
                      MainNavigationService.navigateToTab(context, 3);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.repeat_rounded,
                    label: 'Recurring Payments',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RecurringScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none_rounded,
                    label: 'Reminders',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RemindersScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.backup_rounded,
                    label: 'Backup & Restore',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const IntegrityScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),

            // 3. Drawer Footer: Offline Local Storage Status
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Data saved locally',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      timeFormatted,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      visualDensity: const VisualDensity(vertical: -1),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icons/app_icon.png', width: 36, height: 36),
            ),
            const SizedBox(width: 12),
            const Text(AppConstants.appName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version ${AppConstants.appVersion}', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Database Schema v${AppConstants.databaseVersion} (SQLite Offline)'),
            const SizedBox(height: 12),
            Text(
              '100% Offline Personal Finance Ledger. No tracking, no cloud servers, strict financial auditability.',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
