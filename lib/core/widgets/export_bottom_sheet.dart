import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/backup/data/services/excel_export_service.dart';
import '../../features/backup/presentation/providers/backup_provider.dart';
import '../../features/backup/presentation/screens/automatic_export_screen.dart';
import '../../features/backup/presentation/screens/export_transactions_screen.dart';
import '../../features/transactions/domain/entities/transaction.dart';
import '../theme/app_colors.dart';
import '../utilities/app_snack_bar.dart';
import 'export_success_dialog.dart';
import 'period_selector.dart';

enum ExportSheetAction {
  exportTransactions,
  exportAllTransactions,
  automaticExport,
}

/// Modal bottom sheet presenting transaction export options.
/// Strictly limited to transaction export (no database backup/restore options).
class ExportBottomSheet extends StatelessWidget {
  final TimePeriod? periodMode;
  final DateTime? anchorDate;
  final DateTimeRange? customDateRange;
  final String? accountId;
  final String? accountName;
  final LedgerItemType? typeFilter;

  const ExportBottomSheet({
    super.key,
    this.periodMode,
    this.anchorDate,
    this.customDateRange,
    this.accountId,
    this.accountName,
    this.typeFilter,
  });

  static Future<void> show(
    BuildContext context, {
    TimePeriod? periodMode,
    DateTime? anchorDate,
    DateTimeRange? customDateRange,
    String? accountId,
    String? accountName,
    LedgerItemType? typeFilter,
  }) async {
    final action = await showModalBottomSheet<ExportSheetAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportBottomSheet(
        periodMode: periodMode,
        anchorDate: anchorDate,
        customDateRange: customDateRange,
        accountId: accountId,
        accountName: accountName,
        typeFilter: typeFilter,
      ),
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case ExportSheetAction.exportTransactions:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExportTransactionsScreen(
              initialPeriodMode: periodMode,
              initialAnchorDate: anchorDate,
              initialCustomDateRange: customDateRange,
              initialAccountId: accountId,
              initialAccountName: accountName,
              initialTypeFilter: typeFilter,
            ),
          ),
        );
        break;
      case ExportSheetAction.exportAllTransactions:
        await _executeExportAll(context);
        break;
      case ExportSheetAction.automaticExport:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AutomaticExportScreen(),
          ),
        );
        break;
    }
  }

  static Future<void> _executeExportAll(BuildContext context) async {
    final backupProvider = context.read<BackupProvider>();

    AppSnackBar.showInfo(context, 'Exporting complete transaction history...');

    try {
      final file = await backupProvider.exportToExcel(
        filter: const ExcelExportFilter(),
        notify: backupProvider.autoExportConfig.notifyOnComplete,
      );

      if (context.mounted && file != null) {
        await ExportSuccessDialog.show(
          context,
          file: file,
          type: ExportFileType.excel,
        );
      } else if (context.mounted) {
        AppSnackBar.showError(
          context,
          backupProvider.errorMessage ?? 'Failed to export transactions.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Export failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: bottomInset + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Export Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Option 1: Export Transactions (Period selection & Preview)
              _buildOptionTile(
                context: context,
                icon: Icons.calendar_month_rounded,
                iconBgColor: primaryAccent.withValues(alpha: 0.12),
                iconColor: primaryAccent,
                title: 'Export Transactions',
                subtitle: 'Select a period and preview transactions before exporting.',
                onTap: () => Navigator.of(context).pop(ExportSheetAction.exportTransactions),
              ),
              const SizedBox(height: 10),

              // Option 2: Export All Transactions (Complete History)
              _buildOptionTile(
                context: context,
                icon: Icons.all_inclusive_rounded,
                iconBgColor: AppColors.income.withValues(alpha: 0.12),
                iconColor: AppColors.income,
                title: 'Export All Transactions',
                subtitle: 'Export the complete transaction history.',
                onTap: () => Navigator.of(context).pop(ExportSheetAction.exportAllTransactions),
              ),
              const SizedBox(height: 10),

              // Option 3: Automatic Export (Schedule management)
              _buildOptionTile(
                context: context,
                icon: Icons.schedule_rounded,
                iconBgColor: Colors.purple.withValues(alpha: 0.12),
                iconColor: Colors.purple,
                title: 'Automatic Export',
                subtitle: 'Configure and manage scheduled local exports.',
                onTap: () => Navigator.of(context).pop(ExportSheetAction.automaticExport),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
