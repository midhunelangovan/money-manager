import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/storage_helper.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import 'export_transactions_screen.dart';

enum ExportHistoryFilter {
  all,
  excel,
  backup,
}

class ExportHistoryScreen extends StatefulWidget {
  final String? highlightFilePath;

  const ExportHistoryScreen({
    super.key,
    this.highlightFilePath,
  });

  @override
  State<ExportHistoryScreen> createState() => _ExportHistoryScreenState();
}

class _ExportHistoryScreenState extends State<ExportHistoryScreen> {
  List<File> _allFiles = [];
  bool _isLoading = true;
  ExportHistoryFilter _filter = ExportHistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _loadExportedFiles();
  }

  Future<void> _loadExportedFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await StorageHelper.getExportedFiles();
      if (mounted) {
        setState(() {
          _allFiles = files;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<File> get _filteredFiles {
    switch (_filter) {
      case ExportHistoryFilter.all:
        return _allFiles;
      case ExportHistoryFilter.excel:
        return _allFiles.where((f) => p.extension(f.path).toLowerCase() == '.xlsx').toList();
      case ExportHistoryFilter.backup:
        return _allFiles.where((f) => p.extension(f.path).toLowerCase() == '.mmb').toList();
    }
  }

  Future<void> _openFile(File file) async {
    try {
      if (!await file.exists()) {
        if (mounted) {
          AppSnackBar.showError(context, 'File no longer exists at this path.');
          _loadExportedFiles();
        }
        return;
      }
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        AppSnackBar.showInfo(
          context,
          result.type == ResultType.noAppToOpen
              ? 'No compatible app found to open this format directly. You can use Share.'
              : 'Could not open file: ${result.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to open file: $e');
      }
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      if (!await file.exists()) {
        if (mounted) {
          AppSnackBar.showError(context, 'File no longer exists at this path.');
          _loadExportedFiles();
        }
        return;
      }
      final fileName = p.basename(file.path);
      final isExcel = p.extension(file.path).toLowerCase() == '.xlsx';
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: fileName,
        text: isExcel
            ? 'Financial workbook export from Kal\'s Money Manager ($fileName)'
            : 'Offline backup from Kal\'s Money Manager ($fileName)',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not open share: $e');
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    final fileName = p.basename(file.path);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Exported File?'),
        content: Text(
          'Are you sure you want to delete "$fileName"?\n\nThis will only delete this exported file from storage. Your application data and database remain completely safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
        if (mounted) {
          AppSnackBar.showSuccess(context, 'File deleted from storage.');
          _loadExportedFiles();
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to delete file: $e');
        }
      }
    }
  }

  Future<void> _openFolder() async {
    final downloadsDir = await StorageHelper.getDownloadsDirectory();
    final opened = await StorageHelper.openFolder(downloadsDir);
    if (!opened && mounted) {
      AppSnackBar.showInfo(
        context,
        'Files are stored in: ${downloadsDir.path}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark ? theme.colorScheme.primary : AppColors.primary;
    final filtered = _filteredFiles;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          AppHeader(
            title: 'Export History',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 22),
                tooltip: 'Open Downloads Folder',
                onPressed: _openFolder,
              ),
            ],
            bottom: Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  '${_allFiles.length} exported ${_allFiles.length == 1 ? 'file' : 'files'} found on device',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All (${_allFiles.length})',
                  selected: _filter == ExportHistoryFilter.all,
                  onSelected: () => setState(() => _filter = ExportHistoryFilter.all),
                  isDark: isDark,
                  primaryColor: primaryAccent,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Excel (.xlsx)',
                  selected: _filter == ExportHistoryFilter.excel,
                  onSelected: () => setState(() => _filter = ExportHistoryFilter.excel),
                  isDark: isDark,
                  primaryColor: primaryAccent,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Backups (.mmb)',
                  selected: _filter == ExportHistoryFilter.backup,
                  onSelected: () => setState(() => _filter = ExportHistoryFilter.backup),
                  isDark: isDark,
                  primaryColor: primaryAccent,
                ),
              ],
            ),
          ),

          // File List or Loading / Empty States
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState(isDark, primaryAccent)
                    : RefreshIndicator(
                        onRefresh: _loadExportedFiles,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final file = filtered[index];
                            final isHighlighted = widget.highlightFilePath != null &&
                                file.path == widget.highlightFilePath;
                            return _buildFileItem(file, isDark, primaryAccent, isHighlighted);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required bool isDark,
    required Color primaryColor,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? Colors.white
              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: primaryColor,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? primaryColor
              : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
        ),
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildFileItem(File file, bool isDark, Color primaryAccent, bool isHighlighted) {
    final fileName = p.basename(file.path);
    final ext = p.extension(file.path).toLowerCase();
    final isExcel = ext == '.xlsx';
    int fileSizeBytes = 0;
    DateTime lastModified = DateTime.now();

    try {
      fileSizeBytes = file.lengthSync();
      lastModified = file.lastModifiedSync();
    } catch (_) {}

    final formattedSize = StorageHelper.formatFileSize(fileSizeBytes);
    final formattedDate = DateFormatter.formatDateAndTime(lastModified);

    return AppCard(
      padding: const EdgeInsets.all(14),
      color: isHighlighted
          ? (isDark ? primaryAccent.withValues(alpha: 0.15) : primaryAccent.withValues(alpha: 0.08))
          : (isDark ? AppColors.darkSurfaceCard : Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isExcel
                      ? const Color(0xFF059669).withValues(alpha: 0.15)
                      : primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isExcel ? Icons.table_chart_rounded : Icons.backup_rounded,
                  color: isExcel ? const Color(0xFF059669) : primaryAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          formattedSize,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
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
            ],
          ),

          const SizedBox(height: 10),

          // Actual Storage Path Display with Copy Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_rounded,
                  size: 15,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    file.parent.path,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: file.path));
                    AppSnackBar.showSuccess(context, 'Full file path copied to clipboard');
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

          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
          const SizedBox(height: 6),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open File', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _openFile(file),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _shareFile(file),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                tooltip: 'Delete File',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _deleteFile(file),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryAccent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_zip_rounded,
                size: 48,
                color: primaryAccent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Exported Files Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spreadsheets (.xlsx) and offline backups (.mmb) created from the app will appear here with instant options to open, view storage location, or share.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download_rounded, size: 18),
              label: const Text('Export Transactions'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExportTransactionsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
