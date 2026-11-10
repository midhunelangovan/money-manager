import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/storage_helper.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../data/services/automatic_export_service.dart';
import '../providers/backup_provider.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  File? _lastExportFile;
  File? _lastBackupFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BackupProvider>().loadAutoExportConfig();
      }
    });
  }

  Future<void> _createBackup() async {
    final provider = context.read<BackupProvider>();
    final config = provider.autoExportConfig;
    final file = await provider.createBackupFile(notify: config.notifyOnComplete);
    if (file != null && mounted) {
      setState(() => _lastBackupFile = file);
      AppSnackBar.showSuccess(
        context,
        'Backup validated & created: ${file.path.split(Platform.pathSeparator).last}',
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () => _openFile(file),
        ),
      );
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

        final success = await context.read<BackupProvider>().restoreFromFile(file);
        if (success) {
          await accProvider.loadAccounts();
          await txProvider.loadLedger();
          if (mounted) {
            AppSnackBar.showSuccess(context, 'Data restored successfully!');
          }
        }
      }
    }
  }

  Future<void> _exportExcel() async {
    final provider = context.read<BackupProvider>();
    final config = provider.autoExportConfig;
    final file = await provider.exportToExcel(notify: config.notifyOnComplete);
    if (file != null && mounted) {
      setState(() => _lastExportFile = file);
      AppSnackBar.showSuccess(
        context,
        'Excel workbook exported: ${file.path.split(Platform.pathSeparator).last}',
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () => _openFile(file),
        ),
      );
    }
  }

  Future<void> _openFile(File file) async {
    try {
      if (await file.exists()) {
        await OpenFilex.open(file.path);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'File not found in storage');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not open file: $e');
      }
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      if (await file.exists()) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: "Kal's Money Manager Export: ${file.path.split(Platform.pathSeparator).last}",
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not share file: $e');
      }
    }
  }

  Future<void> _selectPreferredTime(BuildContext parentContext, AutoExportConfig config) async {
    final picked = await showTimePicker(
      context: parentContext,
      initialTime: config.preferredTime,
    );
    if (picked != null && mounted) {
      if (!parentContext.mounted) return;
      parentContext.read<BackupProvider>().updateAutoExportConfig(
        config.copyWith(preferredTime: picked),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupProvider = context.watch<BackupProvider>();
    final config = backupProvider.autoExportConfig;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    // Calculate next run estimate
    String nextScheduledText = 'Disabled';
    if (config.isEnabled && backupProvider.automaticExportService != null) {
      final nextRun = backupProvider.automaticExportService!.calculateNextRun(config);
      nextScheduledText = '${DateFormatter.format(nextRun)} at ${config.preferredTime.format(context)} (est.)';
    }

    final hasRecentBackup = config.lastBackupTime != null;
    final hasRecentExcel = config.lastExcelTime != null;
    final isHealthy = hasRecentBackup || hasRecentExcel;

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
                // SECTION 1: Backup Health Status Card
                AppCard(
                  padding: const EdgeInsets.all(18),
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isHealthy ? AppColors.income : AppColors.warning).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isHealthy ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                              color: isHealthy ? AppColors.income : AppColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Backup Health',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  isHealthy ? 'All local backups verified and healthy' : 'No local backup recorded yet',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isHealthy ? AppColors.income : AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
                      const SizedBox(height: 10),
                      _buildHealthRow(
                        title: 'Last Native Backup',
                        timestamp: config.lastBackupTime,
                        filePath: config.lastBackupPath,
                        fileSize: config.lastBackupSize,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildHealthRow(
                        title: 'Last Excel Export',
                        timestamp: config.lastExcelTime,
                        filePath: config.lastExcelPath,
                        fileSize: config.lastExcelSize,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Scheduled:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nextScheduledText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: config.isEnabled
                                    ? (isDark ? Colors.white : AppColors.primary)
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (config.lastRunStatus == 'failed' && config.lastError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Previous run failed: ${config.lastError}. Older backups preserved.',
                                  style: const TextStyle(fontSize: 11, color: AppColors.expense),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SECTION 2: Automatic Local Export Configuration Card
                AppCard(
                  padding: const EdgeInsets.all(18),
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automatic Local Export',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Offline scheduled exports to local storage',
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: config.isEnabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              backupProvider.updateAutoExportConfig(config.copyWith(isEnabled: val));
                            },
                          ),
                        ],
                      ),

                      if (config.isEnabled) ...[
                        const SizedBox(height: 16),
                        Divider(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
                        const SizedBox(height: 12),

                        // Frequency Selector
                        Text(
                          'Export Frequency',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: AutoExportFrequency.values.map((freq) {
                            final isSel = config.frequency == freq;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: ChoiceChip(
                                  label: Center(
                                    child: Text(
                                      freq.displayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        color: isSel ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ),
                                  selected: isSel,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightInputSurface,
                                  onSelected: (_) {
                                    backupProvider.updateAutoExportConfig(config.copyWith(frequency: freq));
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Day of week / Day of month conditional selectors
                        if (config.frequency == AutoExportFrequency.weekly) ...[
                          Text(
                            'Day of the Week',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (int d = 1; d <= 7; d++) ...[
                                  ChoiceChip(
                                    label: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1]),
                                    selected: config.dayOfWeek == d,
                                    selectedColor: AppColors.primary,
                                    onSelected: (_) {
                                      backupProvider.updateAutoExportConfig(config.copyWith(dayOfWeek: d));
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ] else if (config.frequency == AutoExportFrequency.monthly) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Day of the Month (1 - 31)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              DropdownButton<int>(
                                value: config.dayOfMonth,
                                dropdownColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                items: [for (int i = 1; i <= 31; i++) i].map((d) {
                                  return DropdownMenuItem<int>(
                                    value: d,
                                    child: Text('Day $d'),
                                  );
                                }).toList(),
                                onChanged: (newDay) {
                                  if (newDay != null) {
                                    backupProvider.updateAutoExportConfig(config.copyWith(dayOfMonth: newDay));
                                  }
                                },
                              ),
                            ],
                          ),
                          Text(
                            'Shorter months safely clamp to the last calendar day (e.g. Feb 28/29, Apr 30).',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Preferred Time Picker
                        InkWell(
                          onTap: () => _selectPreferredTime(context, config),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightInputSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Preferred Execution Time',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  config.preferredTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Export Format & Scope
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Format',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<AutoExportFormat>(
                                    initialValue: config.format,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    dropdownColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                    items: AutoExportFormat.values.map((fmt) {
                                      return DropdownMenuItem(
                                        value: fmt,
                                        child: Text(fmt == AutoExportFormat.excel ? 'Excel (.xlsx)' : 'Backup (.mmb)', style: const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                    onChanged: (fmt) {
                                      if (fmt != null) {
                                        backupProvider.updateAutoExportConfig(config.copyWith(format: fmt));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scope',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<AutoExportScope>(
                                    initialValue: config.scope,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    dropdownColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                    items: AutoExportScope.values.map((sc) {
                                      return DropdownMenuItem(
                                        value: sc,
                                        child: Text(sc == AutoExportScope.allTransactions ? 'All Time' : 'Current Month', style: const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                    onChanged: (sc) {
                                      if (sc != null) {
                                        backupProvider.updateAutoExportConfig(config.copyWith(scope: sc));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Retention & Notification Preferences
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Retention Policy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            DropdownButton<int>(
                              value: config.retentionCount,
                              dropdownColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
                              items: const [5, 10, 30].map((count) {
                                return DropdownMenuItem<int>(
                                  value: count,
                                  child: Text('Keep latest $count files'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  backupProvider.updateAutoExportConfig(config.copyWith(retentionCount: val));
                                }
                              },
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Export Completion Notifications',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            Switch(
                              value: config.notifyOnComplete,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) {
                                backupProvider.updateAutoExportConfig(config.copyWith(notifyOnComplete: val));
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Instant Manual Run Action
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            foregroundColor: AppColors.primary,
                          ),
                          onPressed: backupProvider.isProcessing
                              ? null
                              : () async {
                                  final res = await backupProvider.runAutoExportNow();
                                  if (res != null && res.success && mounted && context.mounted) {
                                    AppSnackBar.showSuccess(
                                      context,
                                      'Auto-export generated: ${p.basename(res.file!.path)}',
                                      action: SnackBarAction(
                                        label: 'Open',
                                        textColor: Colors.white,
                                        onPressed: () => _openFile(res.file!),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Run Export Now'),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SECTION 3: Manual Native Application Backup (.mmb) Card
                AppCard(
                  padding: const EdgeInsets.all(18),
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Backup (.mmb)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Secure, versioned archive preserving all financial data',
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Captures accounts, balances, transactions, transfers, categories, recurring payments, reminders, and photos with SHA-256 integrity validation.',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              onPressed: backupProvider.isProcessing ? null : _createBackup,
                              icon: const Icon(Icons.backup_rounded, size: 18),
                              label: const Text('Create Backup'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                              ),
                              onPressed: backupProvider.isProcessing ? null : _restoreBackup,
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Restore Data'),
                            ),
                          ),
                        ],
                      ),
                      if (_lastBackupFile != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Saved: ${p.basename(_lastBackupFile!.path)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              tooltip: 'Open',
                              onPressed: () => _openFile(_lastBackupFile!),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, size: 18),
                              tooltip: 'Share',
                              onPressed: () => _shareFile(_lastBackupFile!),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SECTION 4: Excel Export (.xlsx) Card
                AppCard(
                  padding: const EdgeInsets.all(18),
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.table_chart_rounded, color: AppColors.income, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Excel Export (.xlsx)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Multi-sheet spreadsheet for analysis and reporting',
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Exports Summary, Transactions, Accounts, Categories, Transfers, and Recurring rules with separate transfer accounting.',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.income,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: backupProvider.isProcessing ? null : _exportExcel,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export Excel Workbook'),
                      ),
                      if (_lastExportFile != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Saved: ${p.basename(_lastExportFile!.path)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              tooltip: 'Open',
                              onPressed: () => _openFile(_lastExportFile!),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, size: 18),
                              tooltip: 'Share',
                              onPressed: () => _shareFile(_lastExportFile!),
                            ),
                          ],
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

  Widget _buildHealthRow({
    required String title,
    required DateTime? timestamp,
    required String? filePath,
    required int? fileSize,
    required bool isDark,
  }) {
    if (timestamp == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            'None recorded',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ],
      );
    }

    final dateStr = DateFormatter.format(timestamp);
    final sizeStr = fileSize != null ? StorageHelper.formatFileSize(fileSize) : '';
    final nameStr = filePath != null ? p.basename(filePath) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Verified • $dateStr',
                  style: const TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        if (nameStr.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '$nameStr ${sizeStr.isNotEmpty ? "($sizeStr)" : ""}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
