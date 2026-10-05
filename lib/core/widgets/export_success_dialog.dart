import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../utilities/storage_helper.dart';

enum ExportFileType {
  excel,
  backup,
}

class ExportSuccessDialog extends StatelessWidget {
  final File file;
  final ExportFileType type;
  final int fileSizeBytes;

  const ExportSuccessDialog({
    super.key,
    required this.file,
    required this.type,
    required this.fileSizeBytes,
  });

  static Future<void> show(
    BuildContext context, {
    required File file,
    required ExportFileType type,
    int? fileSizeBytes,
  }) async {
    final size = fileSizeBytes ?? (await file.exists() ? await file.length() : 0);
    if (!context.mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ExportSuccessDialog(
        file: file,
        type: type,
        fileSizeBytes: size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileName = p.basename(file.path);
    final isExcel = type == ExportFileType.excel;
    final title = isExcel ? 'Export Completed' : 'Backup Completed';
    final subtitle = isExcel ? 'Excel file created' : 'Backup created';
    final parentDir = p.basename(file.parent.path);
    final locationLabel = parentDir.toLowerCase().contains('download')
        ? 'Saved to Downloads'
        : 'Saved to ${file.parent.path}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Success Badge & Title
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.income,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded, color: AppColors.income, size: 16),
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // File Details Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isExcel
                              ? const Color(0xFF059669).withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isExcel ? Icons.table_chart_rounded : Icons.backup_rounded,
                          color: isExcel ? const Color(0xFF059669) : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              StorageHelper.formatFileSize(fileSizeBytes),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locationLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share and Open File Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      isExcel ? 'Share' : 'Share Backup',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    onPressed: () => _shareFile(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text(
                      'Open File',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    onPressed: () => _openFile(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Done Button
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareFile(BuildContext context) async {
    try {
      final exists = await file.exists();
      if (!exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found. Please try exporting again.'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
        return;
      }

      final fileName = p.basename(file.path);
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: fileName,
        text: type == ExportFileType.excel
            ? 'Financial workbook export from Kal\'s Money Manager ($fileName)'
            : 'Offline backup from Kal\'s Money Manager ($fileName)',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open system share: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      final exists = await file.exists();
      if (!exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found in storage.'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
        return;
      }

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.type == ResultType.noAppToOpen
                  ? 'No compatible app found to open this format directly. You can use Share or access it from Downloads.'
                  : 'Could not open file: ${result.message}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }
}
