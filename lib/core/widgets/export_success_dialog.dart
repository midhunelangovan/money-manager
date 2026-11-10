import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import '../utilities/app_snack_bar.dart';
import '../utilities/storage_helper.dart';
import '../../features/backup/presentation/screens/export_history_screen.dart';

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

  /// Displays the success dialog ONLY after verifying that the file exists and is non-empty.
  /// If verification fails, a clear error message is reported instead of a false success.
  static Future<void> show(
    BuildContext context, {
    required File file,
    required ExportFileType type,
    int? fileSizeBytes,
  }) async {
    final isValid = await StorageHelper.verifyFileExistsAndNonEmpty(file);
    if (!isValid) {
      if (context.mounted) {
        AppSnackBar.showError(
          context,
          'Export failed: File could not be verified on device storage.',
        );
      }
      return;
    }

    final size = fileSizeBytes ?? await file.length();
    if (!context.mounted) return;

    showDialog(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;
    final fileName = p.basename(file.path);
    final isExcel = type == ExportFileType.excel;
    final title = isExcel ? 'Export Completed' : 'Backup Completed';
    final subtitle = isExcel ? 'Excel spreadsheet saved' : 'Offline backup archive saved';
    final directoryPath = file.parent.path;
    final isDownloadDir = directoryPath.toLowerCase().contains('download');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
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
                                : primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExcel ? Icons.table_chart_rounded : Icons.backup_rounded,
                            color: isExcel ? const Color(0xFF059669) : primaryAccent,
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
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Actual Storage Location Label & Value
                    Text(
                      isDownloadDir ? 'Storage Location (Downloads):' : 'Storage Location:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_rounded,
                            size: 16,
                            color: primaryAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              directoryPath,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: file.path));
                              AppSnackBar.showSuccess(context, 'Full file path copied');
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Primary Action: Open Downloads / View Files
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isDownloadDir ? Icons.download_rounded : Icons.folder_open_rounded,
                  size: 18,
                ),
                label: Text(
                  isDownloadDir ? 'Open Downloads' : 'Open Folder / View Files',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onPressed: () => _openFolderOrFiles(context),
              ),
              const SizedBox(height: 10),

              // Secondary Actions: View Exported File & Share
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text(
                        'View File',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: () => _openFile(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: Text(
                        isExcel ? 'Share' : 'Share File',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: () => _shareFile(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // View History & Done Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text(
                      'Export History',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExportHistoryScreen(
                            highlightFilePath: file.path,
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFolderOrFiles(BuildContext context) async {
    Navigator.pop(context);
    await StorageHelper.openExportFolder(context, file: file);
  }

  Future<void> _shareFile(BuildContext context) async {
    try {
      final exists = await file.exists();
      if (!exists) {
        if (context.mounted) {
          AppSnackBar.showError(context, 'File not found. Please try exporting again.');
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
        AppSnackBar.showError(context, 'Could not open system share: $e');
      }
    }
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      final exists = await file.exists();
      if (!exists) {
        if (context.mounted) {
          AppSnackBar.showError(context, 'File not found in storage.');
        }
        return;
      }

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        AppSnackBar.showInfo(
          context,
          result.type == ResultType.noAppToOpen
              ? 'No compatible app found to open this format directly. You can use Share or access it from Downloads.'
              : 'Could not open file: ${result.message}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Failed to open file: $e');
      }
    }
  }
}
