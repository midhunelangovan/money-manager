using System;
using System.IO;

class FixColors
{
    static void Main()
    {
        // 1. export_action_dialog.dart
        ReplaceInFile("lib/core/widgets/export_action_dialog.dart",
            "const Color(0xFF1E2838) : const Color(0xFFF1F5F9)",
            "AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated");
        ReplaceInFile("lib/core/widgets/export_action_dialog.dart",
            "const Color(0xFF283646) : const Color(0xFFCBD5E1)",
            "AppColors.darkBorder : AppColors.lightBorder");

        // 2. backup_restore_screen.dart
        ReplaceInFile("lib/features/backup/presentation/screens/backup_restore_screen.dart",
            "color: isDark ? const Color(0xFF141C2B) : Colors.white,",
            "color: isDark ? AppColors.darkSurfaceCard : Colors.white,");

        // 3. integrity_screen.dart
        ReplaceInFile("lib/features/backup/presentation/screens/integrity_screen.dart",
            "color: isDark ? const Color(0xFF141C2B) : Colors.white,",
            "color: isDark ? AppColors.darkSurfaceCard : Colors.white,");
        ReplaceInFile("lib/features/backup/presentation/screens/integrity_screen.dart",
            "color: isDark ? const Color(0xFF202C3F) : const Color(0xFFE2E8F0),",
            "color: isDark ? AppColors.darkBorder : AppColors.lightBorder,");

        // 4. edit_account_balance_dialog.dart
        ReplaceInFile("lib/features/accounts/presentation/widgets/edit_account_balance_dialog.dart",
            "color: isDark ? const Color(0xFF16202C) : Colors.white,",
            "color: isDark ? AppColors.darkSurfaceCard : Colors.white,");
        ReplaceInFile("lib/features/accounts/presentation/widgets/edit_account_balance_dialog.dart",
            "color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF8FAFC),",
            "color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,");
        ReplaceInFile("lib/features/accounts/presentation/widgets/edit_account_balance_dialog.dart",
            "color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9),",
            "color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,");

        // 5. calculator_dialog.dart
        ReplaceInFile("lib/core/widgets/calculator_dialog.dart",
            "backgroundColor: isDark ? const Color(0xFF16202E) : Colors.white,",
            "backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,");
        ReplaceInFile("lib/core/widgets/calculator_dialog.dart",
            "color: isDark ? const Color(0xFF0F1722) : AppColors.lightSurfaceElevated,",
            "color: isDark ? AppColors.darkInputSurface : AppColors.lightSurfaceElevated,");
        ReplaceInFile("lib/core/widgets/calculator_dialog.dart",
            ": (isDark ? const Color(0xFF222F42) : const Color(0xFFF1F5F4)));",
            ": (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated));");

        // 6. account_detail_screen.dart
        ReplaceInFile("lib/features/accounts/presentation/screens/account_detail_screen.dart",
            "color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8EEF5),",
            "color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSelectedBackground,");

        // 7. category_report_detail_screen.dart
        ReplaceInFile("lib/features/reports/presentation/screens/category_report_detail_screen.dart",
            "color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8EEF5),",
            "color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSelectedBackground,");

        // 8. reports_screen.dart
        ReplaceInFile("lib/features/reports/presentation/screens/reports_screen.dart",
            "backgroundColor: isDark ? const Color(0xFF1E2B3E) : const Color(0xFFEAEFF2),",
            "backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSelectedBackground,");

        // 9. recurring_screen.dart
        ReplaceInFile("lib/features/recurring/presentation/screens/recurring_screen.dart",
            "color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),",
            "color: isDark ? AppColors.darkBorder : AppColors.lightBorder,");
        ReplaceInFile("lib/features/recurring/presentation/screens/recurring_screen.dart",
            ": (isDark ? const Color(0xFFFB7185) : AppColors.expense),",
            ": AppColors.expense,");

        // 10. date_wise_timeline.dart
        ReplaceInFile("lib/core/widgets/date_wise_timeline.dart",
            "final dividerColor = isDark ? AppColors.darkBorderSubtle : const Color(0xFFF1F5F9);",
            "final dividerColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;");

        // 11. currency_picker_dialog.dart
        ReplaceInFile("lib/core/widgets/currency_picker_dialog.dart",
            ": (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),",
            ": (isDark ? AppColors.darkBorder : AppColors.lightBorder),");

        // 12. app_select_field.dart
        ReplaceInFile("lib/core/widgets/app_select_field.dart",
            "color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),",
            "color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,");

        // 13. add_edit_account_screen.dart
        ReplaceInFile("lib/features/accounts/presentation/screens/add_edit_account_screen.dart",
            "color: isDark ? AppColors.darkInputSurface : const Color(0xFFF1F5F9),",
            "color: isDark ? AppColors.darkInputSurface : AppColors.lightInputSurface,");

        // 14. add_edit_category_screen.dart
        ReplaceInFile("lib/features/categories/presentation/screens/add_edit_category_screen.dart",
            "color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),",
            "color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,");

        Console.WriteLine("FixColors completed successfully.");
    }

    static void ReplaceInFile(string file, string target, string replacement)
    {
        if (!File.Exists(file)) return;
        string text = File.ReadAllText(file);
        if (text.Contains(target))
        {
            text = text.Replace(target, replacement);
            File.WriteAllText(file, text);
            Console.WriteLine("Updated: " + file);
        }
    }
}
