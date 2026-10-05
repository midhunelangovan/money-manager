import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../data/services/integrity_service.dart';
import '../providers/backup_provider.dart';

class IntegrityScreen extends StatefulWidget {
  const IntegrityScreen({super.key});

  @override
  State<IntegrityScreen> createState() => _IntegrityScreenState();
}

class _IntegrityScreenState extends State<IntegrityScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupProvider>().runIntegrityCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backupProvider = context.watch<BackupProvider>();
    final report = backupProvider.latestIntegrityReport;
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
            title: 'Verify Data Integrity',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Re-run Checks',
                onPressed: () => backupProvider.runIntegrityCheck(),
              ),
            ],
          ),
          Expanded(
            child: backupProvider.isProcessing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Verifying foreign keys and ledger records...'),
                      ],
                    ),
                  )
                : report == null
                    ? const Center(child: Text('No integrity report available'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                    // Overall Health Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: report.isHealthy
                            ? AppColors.income.withValues(alpha: 0.12)
                            : AppColors.expense.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: report.isHealthy ? AppColors.income : AppColors.expense,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            report.isHealthy ? Icons.check_circle_rounded : Icons.error_rounded,
                            color: report.isHealthy ? AppColors.income : AppColors.expense,
                            size: 36,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.isHealthy
                                      ? 'Data Integrity Verified'
                                      : 'Integrity Issues Detected',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: report.isHealthy ? AppColors.income : AppColors.expense,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  report.isHealthy
                                      ? 'All ledger transactions, balances, and relational foreign keys are strictly valid.'
                                      : 'Please review the warnings below.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Last checked: ${DateFormatter.formatIsoDateTime(report.timestamp)}',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),

                    const SizedBox(height: 20),
                    const Text('Audit Checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),

                    ...report.checks.map((item) => _buildCheckTile(context, item)),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckTile(BuildContext context, IntegrityCheckItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF202C3F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isValid ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            color: item.isValid ? AppColors.income : AppColors.expense,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                if (item.details != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.details!,
                    style: const TextStyle(fontSize: 11, color: AppColors.expense),
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
