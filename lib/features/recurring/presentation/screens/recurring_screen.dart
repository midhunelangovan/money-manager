import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../providers/recurring_provider.dart';
import 'add_edit_recurring_screen.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final recProvider = context.watch<RecurringProvider>();
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
            title: 'Recurring Payments',
            actions: [
              IconButton(
                icon: const Icon(Icons.sync_rounded, color: Colors.white),
                tooltip: 'Process Due Schedules',
                onPressed: () async {
                  final result = await recProvider.processDueTransactions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.generatedTransactionsCount > 0
                              ? 'Generated ${result.generatedTransactionsCount} due transactions.'
                              : 'All recurring schedules are up to date.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          Expanded(
            child: recProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : recProvider.recurringTransactions.isEmpty
                    ? EmptyState(
                        icon: Icons.repeat_rounded,
                        title: 'No Recurring Schedules',
                        subtitle: 'Automate salary, monthly rent, SIP, or insurance payments without duplicate entries.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => recProvider.loadRecurring(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: recProvider.recurringTransactions.length,
                          itemBuilder: (context, index) {
                            final item = recProvider.recurringTransactions[index];
                            return _buildRecurringCard(context, item);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditRecurringScreen()),
          );
        },
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }

  Widget _buildRecurringCard(BuildContext context, RecurringTransaction item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item.categoryColor != null ? Color(item.categoryColor!) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.repeat_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            text: item.isActive ? 'Active' : 'Paused',
                            color: item.isActive ? AppColors.income : AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.frequency.displayName} • ${item.accountName ?? "Account"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.amount.format(),
                  style: AppTypography.amountMedium.copyWith(
                    color: item.transactionType.displayName == 'Income'
                        ? AppColors.income
                        : (isDark ? const Color(0xFFFB7185) : AppColors.expense),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next: ${DateFormatter.format(item.nextExecutionDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(50, 32),
                      ),
                      onPressed: () {
                        context.read<RecurringProvider>().skipNext(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Skipped next occurrence')),
                        );
                      },
                      child: const Text('Skip Next', style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (action) {
                        if (action == 'edit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditRecurringScreen(initialRecurring: item),
                            ),
                          );
                        } else if (action == 'toggle') {
                          context.read<RecurringProvider>().toggleActive(item.id, !item.isActive);
                        } else if (action == 'delete') {
                          context.read<RecurringProvider>().deleteRecurring(item.id);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit Schedule')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(item.isActive ? 'Pause Schedule' : 'Resume Schedule'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Schedule', style: TextStyle(color: AppColors.expense)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
