import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../reminders/presentation/screens/reminders_screen.dart';
import '../providers/settings_provider.dart';
import 'about_screen.dart';
import 'appearance_settings_screen.dart';
import 'currency_accounts_settings_screen.dart';
import 'data_storage_settings_screen.dart';
import 'personalization_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildSettingsRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon inside a subtle rounded square (44-48dp)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(width: 16),

              // Setting Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Chevron >
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
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
              title: 'Settings',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsRow(
                          context: context,
                          icon: Icons.person_outline_rounded,
                          title: 'Personalization',
                          subtitle: settings.profileName.isNotEmpty ? settings.profileName : 'Display Name',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PersonalizationSettingsScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 76, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildSettingsRow(
                          context: context,
                          icon: Icons.palette_outlined,
                          title: 'Appearance',
                          subtitle: settings.themeMode == ThemeMode.light
                              ? 'Light Theme'
                              : settings.themeMode == ThemeMode.dark
                                  ? 'Dark Theme'
                                  : 'System Default',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 76, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildSettingsRow(
                          context: context,
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Currency & Accounts',
                          subtitle: '${settings.currencyCode} (${settings.currencySymbol}) • Default account preferences',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CurrencyAccountsSettingsScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 76, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildSettingsRow(
                          context: context,
                          icon: Icons.category_outlined,
                          title: 'Categories',
                          subtitle: 'Manage flat expense and income categories',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 76, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildSettingsRow(
                          context: context,
                          icon: Icons.folder_open_outlined,
                          title: 'Data & Storage',
                          subtitle: 'Backup, restore, and Excel spreadsheet export',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DataStorageSettingsScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 76, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildSettingsRow(
                          context: context,
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications & Reminders',
                          subtitle: 'Offline reminder schedules and notification preferences',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RemindersScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 76, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildSettingsRow(
                          context: context,
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          subtitle: 'Version ${AppConstants.appVersion} • Offline Privacy',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AboutScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Muted Version Footer
                  Center(
                    child: Text(
                      'Kal\'s Money Manager • Version ${AppConstants.appVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
