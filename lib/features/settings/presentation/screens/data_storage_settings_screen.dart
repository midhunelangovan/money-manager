import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/export_success_dialog.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../backup/data/services/excel_export_service.dart';
import '../../../backup/presentation/providers/backup_provider.dart';
import '../../../backup/presentation/screens/excel_import_screen.dart';
import '../../../backup/presentation/screens/integrity_screen.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../recurring/presentation/providers/recurring_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transfers/presentation/providers/transfer_provider.dart';

class DataStorageSettingsScreen extends StatefulWidget {
  const DataStorageSettingsScreen({super.key});

  @override
  State<DataStorageSettingsScreen> createState() => _DataStorageSettingsScreenState();
}

class _DataStorageSettingsScreenState extends State<DataStorageSettingsScreen> {
  Future<void> _handleBackup(BuildContext context, BackupProvider backupProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Creating offline backup in Downloads...'),
              ],
            ),
          ),
        ),
      ),
    );

    final file = await backupProvider.createBackupFile();
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (context.mounted && file != null) {
      await ExportSuccessDialog.show(
        context,
        file: file,
        type: ExportFileType.backup,
      );
    } else if (context.mounted && backupProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(backupProvider.errorMessage!),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _handleExcelExport(BuildContext context, BackupProvider backupProvider) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    DateTimeRange? selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Export Transactions to Excel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select date range to export. The spreadsheet (.xlsx) will be saved to your device Downloads.',
                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                      ),
                      leading: Icon(Icons.date_range_rounded, color: isDark ? theme.colorScheme.primary : AppColors.primary),
                      title: Text(
                        selectedRange != null
                            ? '${selectedRange!.start.day}/${selectedRange!.start.month}/${selectedRange!.start.year} - ${selectedRange!.end.day}/${selectedRange!.end.month}/${selectedRange!.end.year}'
                            : 'All Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down_rounded),
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                          initialDateRange: selectedRange,
                        );
                        if (picked != null) {
                          setModalState(() => selectedRange = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Export XLSX', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Generating Excel spreadsheet...'),
              ],
            ),
          ),
        ),
      ),
    );

    final file = await backupProvider.exportToExcel(
      filter: selectedRange != null
          ? ExcelExportFilter(startDate: selectedRange!.start, endDate: selectedRange!.end)
          : null,
    );
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (context.mounted && file != null) {
      await ExportSuccessDialog.show(
        context,
        file: file,
        type: ExportFileType.excel,
      );
    } else if (context.mounted && backupProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(backupProvider.errorMessage!),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context, BackupProvider backupProvider) async {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.any,
    );

    if (result.isEmpty || result.first.path == null) return;

    final file = File(result.first.path!);

    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Restore',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Restoring from "${p.basename(file.path)}" will validate and replace current data with the backup dataset.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await backupProvider.restoreFromFile(file);
      if (context.mounted) {
        if (success) {
          // Refresh all providers
          context.read<AccountProvider>().loadAccounts();
          context.read<CategoryProvider>().loadCategories();
          context.read<TransactionProvider>().loadLedger();
          context.read<TransferProvider>().loadTransfers();
          context.read<RecurringProvider>().loadRecurring();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data restored successfully!'),
              backgroundColor: AppColors.income,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(backupProvider.errorMessage ?? 'Restore failed'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      }
    }
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryAccent, size: 22),
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
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
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
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backupProvider = context.watch<BackupProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: 'Data & Storage',
              showBackButton: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Backup & Restore',
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
                        _buildActionTile(
                          context: context,
                          icon: Icons.backup_rounded,
                          title: 'Backup Data',
                          subtitle: 'Create complete offline backup (.mmb) with photos in Downloads',
                          onTap: () => _handleBackup(context, backupProvider),
                        ),
                        Divider(height: 1, indent: 68, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildActionTile(
                          context: context,
                          icon: Icons.restore_rounded,
                          title: 'Restore Data',
                          subtitle: 'Validate and restore from a previously created .mmb backup file',
                          onTap: () => _handleRestore(context, backupProvider),
                        ),
                        Divider(height: 1, indent: 68, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildActionTile(
                          context: context,
                          icon: Icons.verified_user_outlined,
                          title: 'Database Integrity Check',
                          subtitle: 'Verify double-entry consistency and ledger audit integrity',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const IntegrityScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Spreadsheet Import & Export',
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
                        _buildActionTile(
                          context: context,
                          icon: Icons.file_download_outlined,
                          title: 'Import from Excel',
                          subtitle: 'Import transactions from another finance application.',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ExcelImportScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 68, endIndent: 16, color: isDark ? AppColors.darkBorderSubtle : null),
                        _buildActionTile(
                          context: context,
                          icon: Icons.table_chart_rounded,
                          title: 'Export to Excel (XLSX)',
                          subtitle: 'Export accounts, categories, and transactions to standard XLSX',
                          onTap: () => _handleExcelExport(context, backupProvider),
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
