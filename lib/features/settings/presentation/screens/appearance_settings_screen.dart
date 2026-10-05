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
                          icon: Icons.light_mode_outlined,
                          mode: ThemeMode.light,
                          currentMode: settings.themeMode,
                          onSelect: (m) => settings.setThemeMode(m),
                        ),
                        Divider(height: 1, indent: 68, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildThemeOption(
                          context: context,
                          title: 'Dark Theme',
                          subtitle: 'Deep midnight slate surface for low light',
                          icon: Icons.dark_mode_outlined,
                          mode: ThemeMode.dark,
                          currentMode: settings.themeMode,
                          onSelect: (m) => settings.setThemeMode(m),
                        ),
                        Divider(height: 1, indent: 68, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildThemeOption(
                          context: context,
                          title: 'System Default',
                          subtitle: 'Follow your device system theme settings',
                          icon: Icons.brightness_auto_outlined,
                          mode: ThemeMode.system,
                          currentMode: settings.themeMode,
                          onSelect: (m) => settings.setThemeMode(m),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Application Accent Color',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accent Color Palette',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select your preferred accent tint for highlights and primary buttons.',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: AppAccentColor.values.map((accent) {
                            final isSelected = settings.accentColor == accent;
                            return InkWell(
                              onTap: () => settings.setAccentColor(accent),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: accent.primary.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                    : null,
                              ),
                            );
                          }).toList(),
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
