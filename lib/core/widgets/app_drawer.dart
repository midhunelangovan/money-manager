import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/recurring/presentation/screens/recurring_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../constants/app_constants.dart';
import '../navigation/navigation_service.dart';
import '../theme/app_colors.dart';
import 'profile_avatar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final activeTab = MainNavigationService.currentTabNotifier.value;

    final drawerBg = AppColors.surface(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final selectedBg = isDark
        ? primaryColor.withValues(alpha: 0.22)
        : primaryColor.withValues(alpha: 0.12);
    final selectedTextColor = isDark ? primaryColor : primaryColor;

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Compact Header: Initials Avatar + Saved Display Name
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: settings.profileName,
                    size: 44,
                    fontSize: 16.5,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      settings.profileName,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.divider(isDark), height: 1),

            // 2. Navigation Menu Items (Direct, Uncluttered, Reference-Inspired)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    label: 'Home',
                    isSelected: activeTab == 0,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      MainNavigationService.navigateToTab(context, 0);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_rounded,
                    label: 'Transactions',
                    isSelected: activeTab == 1,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      MainNavigationService.navigateToTab(context, 1);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_rounded,
                    label: 'Accounts',
                    isSelected: activeTab == 2,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      MainNavigationService.navigateToTab(context, 2);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.insert_chart_rounded,
                    label: 'Reports',
                    isSelected: activeTab == 3,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      MainNavigationService.navigateToTab(context, 3);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.category_rounded,
                    label: 'Categories',
                    isSelected: false,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
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
                    isSelected: false,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RecurringScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_rounded,
                    label: 'Reminders',
                    isSelected: false,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RemindersScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    isSelected: false,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_rounded,
                    label: 'About',
                    isSelected: false,
                    selectedBg: selectedBg,
                    selectedTextColor: selectedTextColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
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
    required bool isSelected,
    required Color selectedBg,
    required Color selectedTextColor,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? selectedTextColor : textSecondary,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedTextColor : textPrimary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        minLeadingWidth: 28,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: const VisualDensity(horizontal: -2, vertical: -1.5),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icons/app_icon.png', width: 36, height: 36),
            ),
            const SizedBox(width: 12),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${AppConstants.appVersion}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Database Schema v${AppConstants.databaseVersion} (SQLite Offline)',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '100% Offline Personal Finance Ledger. No tracking, no cloud servers, strict financial auditability.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
