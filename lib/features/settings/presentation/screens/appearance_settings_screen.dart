import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../providers/settings_provider.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required ValueChanged<ThemeMode> onSelect,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;
    final isSelected = mode == currentMode;

    return InkWell(
      onTap: () => onSelect(mode),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? primaryAccent.withValues(alpha: 0.2) : AppColors.primaryContainer)
                    : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightBorder.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryAccent : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? primaryAccent
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryAccent, size: 22)
            else
              Icon(Icons.radio_button_unchecked_rounded, color: isDark ? AppColors.darkBorder : AppColors.lightBorder, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: 'Appearance',
              showBackButton: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Theme Preference',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _buildThemeOption(
                          context: context,
                          title: 'Light Theme',
                          subtitle: 'Warm off-white matte background with navy headers',
                          icon: Icons.light_mode_rounded,
                          mode: ThemeMode.light,
                          currentMode: settings.themeMode,
                          onSelect: (m) => settings.setThemeMode(m),
                        ),
                        Divider(height: 1, indent: 68, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildThemeOption(
                          context: context,
                          title: 'Dark Theme',
                          subtitle: 'Deep midnight slate surface for low light',
                          icon: Icons.dark_mode_rounded,
                          mode: ThemeMode.dark,
                          currentMode: settings.themeMode,
                          onSelect: (m) => settings.setThemeMode(m),
                        ),
                        Divider(height: 1, indent: 68, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildThemeOption(
                          context: context,
                          title: 'System Default',
                          subtitle: 'Follow your device system theme settings',
                          icon: Icons.brightness_auto_rounded,
                          mode: ThemeMode.system,
                          currentMode: settings.themeMode,
                          onSelect: (m) => settings.setThemeMode(m),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Design System',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.palette_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kals Unified Theme',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A single, restrained Slate Navy & Warm Neutral aesthetic engineered for clarity, readability, and dependability across all accounts and reports.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
          ],
        ),
      ),
    );
  }
}
