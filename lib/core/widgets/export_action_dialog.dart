import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/backup/data/services/excel_export_service.dart';
import '../../features/backup/presentation/providers/backup_provider.dart';
import '../extensions/date_extensions.dart';
import '../theme/app_colors.dart';
import '../utilities/date_formatter.dart';
import 'export_success_dialog.dart';

enum ExportPeriodPreset {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom,
}

class ExportActionDialog {
  static Future<void> show(
    BuildContext context, {
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String? accountId,
    String? defaultPeriodTitle,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    DateTime? customStart = initialStartDate;
    DateTime? customEnd = initialEndDate;
    ExportPeriodPreset selectedPreset = ExportPeriodPreset.thisMonth;

    if (initialStartDate != null && initialEndDate != null) {
      final now = DateTime.now();
      if (initialStartDate.year == now.year &&
          initialStartDate.month == now.month &&
          initialStartDate.day == now.day &&
          initialEndDate.day == now.day) {
        selectedPreset = ExportPeriodPreset.today;
      } else if (initialStartDate.isAtSameMomentAs(now.startOfWeek)) {
        selectedPreset = ExportPeriodPreset.thisWeek;
      } else if (initialStartDate.isAtSameMomentAs(now.startOfMonth)) {
        selectedPreset = ExportPeriodPreset.thisMonth;
      } else {
        selectedPreset = ExportPeriodPreset.custom;
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            final now = DateTime.now();

            DateTime getStartDate() {
              switch (selectedPreset) {
                case ExportPeriodPreset.today:
                  return DateTime(now.year, now.month, now.day, 0, 0, 0);
                case ExportPeriodPreset.thisWeek:
                  return now.startOfWeek;
                case ExportPeriodPreset.thisMonth:
                  return now.startOfMonth;
                case ExportPeriodPreset.thisYear:
                  return DateTime(now.year, 1, 1, 0, 0, 0);
                case ExportPeriodPreset.custom:
                  return customStart ?? now.startOfMonth;
              }
            }

            DateTime getEndDate() {
              switch (selectedPreset) {
                case ExportPeriodPreset.today:
                  return DateTime(now.year, now.month, now.day, 23, 59, 59);
                case ExportPeriodPreset.thisWeek:
                  return now.endOfWeek;
                case ExportPeriodPreset.thisMonth:
                  return now.endOfMonth;
                case ExportPeriodPreset.thisYear:
                  return DateTime(now.year, 12, 31, 23, 59, 59);
                case ExportPeriodPreset.custom:
                  return customEnd ?? now.endOfMonth;
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Export to Excel (XLSX)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    const Text(
                      'Select Period to Export',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 10),

                    // Period Segment / Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _periodChip(
                          label: 'Today',
                          isSelected: selectedPreset == ExportPeriodPreset.today,
                          isDark: isDark,
                          onTap: () => setModalState(() => selectedPreset = ExportPeriodPreset.today),
                        ),
                        _periodChip(
                          label: 'This Week',
                          isSelected: selectedPreset == ExportPeriodPreset.thisWeek,
                          isDark: isDark,
                          onTap: () => setModalState(() => selectedPreset = ExportPeriodPreset.thisWeek),
                        ),
                        _periodChip(
                          label: 'This Month',
                          isSelected: selectedPreset == ExportPeriodPreset.thisMonth,
                          isDark: isDark,
                          onTap: () => setModalState(() => selectedPreset = ExportPeriodPreset.thisMonth),
                        ),
                        _periodChip(
                          label: 'This Year',
                          isSelected: selectedPreset == ExportPeriodPreset.thisYear,
                          isDark: isDark,
                          onTap: () => setModalState(() => selectedPreset = ExportPeriodPreset.thisYear),
                        ),
                        _periodChip(
                          label: 'Custom Range',
                          isSelected: selectedPreset == ExportPeriodPreset.custom,
                          isDark: isDark,
                          onTap: () => setModalState(() => selectedPreset = ExportPeriodPreset.custom),
                        ),
                      ],
                    ),

                    // Custom Date Range Pickers
                    if (selectedPreset == ExportPeriodPreset.custom) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: dialogCtx,
                                  initialDate: customStart ?? now.startOfMonth,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() => customStart = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF283646) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('From', style: TextStyle(fontSize: 10, color: AppColors.lightTextSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormatter.format(customStart ?? now.startOfMonth),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: dialogCtx,
                                  initialDate: customEnd ?? now.endOfMonth,
                                  firstDate: customStart ?? DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() => customEnd = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF283646) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('To', style: TextStyle(fontSize: 10, color: AppColors.lightTextSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormatter.format(customEnd ?? now.endOfMonth),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Export Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 20),
                      label: const Text(
                        'Export to Excel (.xlsx)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        final start = getStartDate();
                        final end = getEndDate();
                        Navigator.pop(dialogCtx);

                        // Trigger export
                        await _performExport(
                          context,
                          filter: ExcelExportFilter(
                            startDate: start,
                            endDate: end,
                            accountId: accountId,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _periodChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF283646) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  static Future<void> _performExport(
    BuildContext context, {
    required ExcelExportFilter filter,
  }) async {
    final backupProvider = context.read<BackupProvider>();
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Generating Excel export...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final File? file = await backupProvider.exportToExcel(filter: filter);
      if (file != null && await file.exists() && context.mounted) {
        await ExportSuccessDialog.show(
          context,
          file: file,
          type: ExportFileType.excel,
        );
      } else if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Export failed: file could not be generated. Please try again.'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }
}
