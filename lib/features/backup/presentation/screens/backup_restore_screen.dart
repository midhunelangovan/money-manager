import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../providers/backup_provider.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _lastExportPath;
  String? _lastBackupPath;

  Future<void> _createBackup() async {
    final provider = context.read<BackupProvider>();
    final file = await provider.createBackupFile();
    if (file != null) {
      setState(() => _lastBackupPath = file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created: ${file.path.split(Platform.pathSeparator).last}'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.any,
    );

    if (result.isNotEmpty) {
      final selectedPath = result.first.path;
      if (selectedPath == null) return;
      final file = File(selectedPath);

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Restore'),
          content: Text(
            'Restoring from "${file.path.split(Platform.pathSeparator).last}" will validate and replace current data. Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore Data'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final accProvider = context.read<AccountProvider>();
        final txProvider = context.read<TransactionProvider>();
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        final success = await context.read<BackupProvider>().restoreFromFile(file);
        if (success) {
          await accProvider.loadAccounts();
          await txProvider.loadLedger();
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Data restored successfully!'),
                backgroundColor: AppColors.income,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _exportExcel() async {
    final provider = context.read<BackupProvider>();
    final file = await provider.exportToExcel();
    if (file != null) {
      setState(() => _lastExportPath = file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel workbook exported: ${file.path.split(Platform.pathSeparator).last}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupProvider = context.watch<BackupProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

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
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
            ),
            title: 'Backup & Export',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          // Section 1: Native Application Backup (.mmb)
          AppCard(
            padding: const EdgeInsets.all(20),
            color: isDark ? const Color(0xFF141C2B) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Native Backup (.mmb)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Secure, versioned, offline backup with checksum',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Creates a single encrypted/structured backup file holding all accounts, categories, transactions, transfers, and recurring schedules.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: backupProvider.isProcessing ? null : _createBackup,
                        icon: const Icon(Icons.backup_outlined, size: 18),
                        label: const Text('Create Backup'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: backupProvider.isProcessing ? null : _restoreBackup,
                        icon: const Icon(Icons.restore_outlined, size: 18),
                        label: const Text('Restore Data'),
                      ),
                    ),
                  ],
                ),
                if (_lastBackupPath != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Saved at: $_lastBackupPath',
                    style: const TextStyle(fontSize: 11, color: AppColors.income),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Excel Export (.xlsx)
          AppCard(
            padding: const EdgeInsets.all(20),
            color: isDark ? const Color(0xFF141C2B) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.table_chart_outlined, color: AppColors.income, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Excel Export (.xlsx)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Multi-sheet audit workbook for spreadsheet apps',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Includes 6 formatted sheets: Summary, Transactions, Accounts, Categories, Transfers, and Recurring rules.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: backupProvider.isProcessing ? null : _exportExcel,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export Excel Workbook'),
                ),
                if (_lastExportPath != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Exported: $_lastExportPath',
                    style: const TextStyle(fontSize: 11, color: AppColors.income),
                  ),
                ],
              ],
            ),
          ),

          if (backupProvider.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                backupProvider.errorMessage!,
                style: const TextStyle(color: AppColors.expense, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    ),
  ],
),
    );
  }
}
