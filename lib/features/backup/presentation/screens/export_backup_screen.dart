import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/export_success_dialog.dart';
import '../../data/services/excel_export_service.dart';
import '../providers/backup_provider.dart';
import 'automatic_export_screen.dart';

/// Dedicated, full-screen Export & Backup screen.
/// Replaces the legacy modal bottom sheet navigation with a first-class route.
class ExportBackupScreen extends StatefulWidget {
  final ExcelExportFilter? currentFilter;
  final String? periodDescription;

  const ExportBackupScreen({
    super.key,
    this.currentFilter,
    this.periodDescription,
  });

  @override
  State<ExportBackupScreen> createState() => _ExportBackupScreenState();
}

class _ExportBackupScreenState extends State<ExportBackupScreen> {
  String? _executingActionId;

  bool get _isBusy => _executingActionId != null;

  Future<void> _runAction({
    required String actionId,
    required String title,
    required bool isFullBackup,
    ExcelExportFilter? filter,
  }) async {
    if (_isBusy) return;

    final backupProvider = context.read<BackupProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _executingActionId = actionId;
    });

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Generating $title...'),
        duration: const Duration(seconds: 1),
      ),
    );

    File? file;
    try {
      if (isFullBackup) {
        file = await backupProvider.createBackupFile(
          notify: backupProvider.autoExportConfig.notifyOnComplete,
        );
      } else {
        file = await backupProvider.exportToExcel(
          filter: filter,
          notify: backupProvider.autoExportConfig.notifyOnComplete,
        );
      }
    } catch (e) {
      // Error handled below via provider message or fallback
    } finally {
      if (mounted) {
        setState(() {
          _executingActionId = null;
        });
      }
    }

    if (!mounted) return;

    if (file != null) {
      await ExportSuccessDialog.show(
        context,
        file: file,
        type: isFullBackup ? ExportFileType.backup : ExportFileType.excel,
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(backupProvider.errorMessage ?? 'Operation failed. Please try again.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final currentPeriodSubtitle = widget.periodDescription != null
        ? 'Excel (.xlsx) • Scope: ${widget.periodDescription}'
        : 'Excel (.xlsx) • Current period & account scope';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Curved full-width branded header with white back arrow
          AppHeader(
            title: 'Export & Backup',
            centerTitle: false,
            showBackButton: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),

          // Scrollable page content
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: bottomInset + 20,
              ),
              children: [
                // Privacy / Local-only info badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'All exports and backups are generated locally on your device. Offline and private.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action A: Export Transactions (Current Period & Scope)
                _buildActionCard(
                  context: context,
                  actionId: 'current',
                  icon: Icons.table_chart_rounded,
                  iconColor: AppColors.income,
                  iconBgColor: AppColors.income.withValues(alpha: 0.14),
                  title: 'Export Transactions',
                  description: currentPeriodSubtitle,
                  onTap: () => _runAction(
                    actionId: 'current',
                    title: 'Current Period Excel Export',
                    isFullBackup: false,
                    filter: widget.currentFilter,
                  ),
                ),

                // Action B: Export All Transactions
                _buildActionCard(
                  context: context,
                  actionId: 'all',
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.income,
                  iconBgColor: AppColors.income.withValues(alpha: 0.14),
                  title: 'Export All Transactions',
                  description: 'Excel (.xlsx) • Complete history across all accounts',
                  onTap: () => _runAction(
                    actionId: 'all',
                    title: 'All Transactions Excel Export',
                    isFullBackup: false,
                    filter: null, // Full history across all accounts
                  ),
                ),

                // Action C: Create Full Backup
                _buildActionCard(
                  context: context,
                  actionId: 'backup',
                  icon: Icons.backup_rounded,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primary.withValues(alpha: 0.14),
                  title: 'Create Full Backup',
                  description: 'Restorable .mmb archive with accounts, transactions & settings',
                  onTap: () => _runAction(
                    actionId: 'backup',
                    title: 'Full Application Backup',
                    isFullBackup: true,
                  ),
                ),

                // Action D: Automatic Export Settings
                _buildActionCard(
                  context: context,
                  actionId: 'settings',
                  icon: Icons.settings_suggest_rounded,
                  iconColor: primaryAccent,
                  iconBgColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.primaryContainer.withValues(alpha: 0.6),
                  title: 'Automatic Export Settings',
                  description: 'Configure offline daily, weekly, or monthly scheduled exports',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AutomaticExportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String actionId,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = _executingActionId == actionId;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: _isBusy ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
        ],
      ),
    );
  }
}
