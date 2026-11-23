import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_category_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/widgets/app_category_icon.dart';
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
                    AppSnackBar.showSuccess(
                      context,
                      result.generatedTransactionsCount > 0
                          ? 'Generated ${result.generatedTransactionsCount} due transactions.'
                          : 'All recurring schedules are up to date.',
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
        backgroundColor: AppColors.floatingActionButton(isDark),
        foregroundColor: AppColors.floatingActionButtonIcon(isDark),
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
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRecurringDetailsSheet(context, item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppCategoryIcon(
                      icon: item.categoryIcon != null && item.categoryIcon!.isNotEmpty
                          ? AppCategoryIcons.getIconData(item.categoryIcon!)
                          : Icons.repeat_rounded,
                      color: color,
                      size: 44,
                      iconSize: 24,
                      borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${item.frequency.displayName} • ${item.accountName ?? "Account"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.remindMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.notifications_active_rounded, size: 11, color: AppColors.primary),
                                      const SizedBox(width: 3),
                                      Text(
                                        item.reminderLeadDays == 0 ? 'Due date' : '${item.reminderLeadDays}d before',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.amount.format(),
                      style: AppTypography.amountMedium.copyWith(
                        color: item.transactionType.displayName == 'Income'
                            ? AppColors.incomeColor(isDark)
                            : AppColors.expenseColor(isDark),
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
                          Icons.event_rounded,
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
                            AppSnackBar.showSuccess(context, 'Skipped next occurrence');
                          },
                          child: const Text('Skip Next', style: TextStyle(fontSize: 12)),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
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
                              AppSnackBar.showSuccess(
                                context,
                                item.isActive ? 'Schedule paused' : 'Schedule resumed',
                              );
                            } else if (action == 'delete') {
                              _confirmDelete(context, item);
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
        ),
      ),
    );
  }

  void _showRecurringDetailsSheet(BuildContext context, RecurringTransaction item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item.categoryColor != null ? Color(item.categoryColor!) : AppColors.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: bottomInset + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Icon, Description & Amount
              Row(
                children: [
                  AppCategoryIcon(
                    icon: item.categoryIcon != null && item.categoryIcon!.isNotEmpty
                        ? AppCategoryIcons.getIconData(item.categoryIcon!)
                        : Icons.repeat_rounded,
                    color: color,
                    size: 50,
                    iconSize: 28,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.transactionType.displayName} • ${item.categoryName ?? "General"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.amount.format(),
                        style: AppTypography.amountMedium.copyWith(
                          color: item.transactionType.displayName == 'Income'
                              ? AppColors.incomeColor(isDark)
                              : AppColors.expenseColor(isDark),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      StatusBadge(
                        text: item.isActive ? 'Active' : 'Paused',
                        color: AppColors.isMinimalMode
                            ? AppColors.textSecondary(isDark)
                            : (item.isActive ? AppColors.income : AppColors.warning),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Frequency', item.frequency.displayName, isDark),
                    const Divider(height: 16),
                    _buildDetailRow('Account', item.accountName ?? 'Default Account', isDark),
                    const Divider(height: 16),
                    _buildDetailRow('Start Date', DateFormatter.formatDate(item.startDate), isDark),
                    const Divider(height: 16),
                    _buildDetailRow('Next Execution', DateFormatter.formatDate(item.nextExecutionDate), isDark, highlight: true),
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Reminders',
                      item.remindMe
                          ? (item.reminderLeadDays == 0 ? 'On due date' : '${item.reminderLeadDays} days before')
                          : 'Disabled',
                      isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(item.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                      label: Text(item.isActive ? 'Pause' : 'Resume'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context.read<RecurringProvider>().toggleActive(item.id, !item.isActive);
                        AppSnackBar.showSuccess(
                          context,
                          item.isActive ? 'Schedule paused' : 'Schedule resumed',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEditRecurringScreen(initialRecurring: item),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                    tooltip: 'Delete Schedule',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.expense.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmDelete(context, item);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, RecurringTransaction item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recurring Schedule?'),
        content: Text(
          'Are you sure you want to delete "${item.description}"? Future scheduled payments will not be generated automatically.',
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

    if (confirmed == true && context.mounted) {
      await context.read<RecurringProvider>().deleteRecurring(item.id);
      AppSnackBar.showSuccess(context, 'Recurring schedule deleted');
    }
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}
