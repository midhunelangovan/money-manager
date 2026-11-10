import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_category_icons.dart';
import '../theme/app_colors.dart';
import '../utilities/money.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../../features/transactions/domain/entities/transaction.dart';
import 'app_category_icon.dart';
import 'confirm_dialog.dart';

/// Reusable chronological date-wise transaction timeline component.
///
/// Groups transactions by local calendar day (newest day first),
/// renders clear date headings with daily totals, and displays compact,
/// readable transaction rows underneath with graceful comment truncation
/// and neutral professional financial amount typography.
class DateGroupedTransactionTimeline extends StatelessWidget {
  final List<LedgerItem> transactions;
  final String? emptyMessage;
  final ValueChanged<LedgerItem>? onItemTap;
  final Future<void> Function(LedgerItem item)? onItemDelete;
  final bool showAccountName;
  final bool isLoading;

  const DateGroupedTransactionTimeline({
    super.key,
    required this.transactions,
    this.emptyMessage,
    this.onItemTap,
    this.onItemDelete,
    this.showAccountName = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Theme.of(context).colorScheme.primary : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Loading transactions...',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 36,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 10),
              Text(
                emptyMessage ?? 'No transactions in this period',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 1. Group transactions by local calendar day
    final Map<DateTime, List<LedgerItem>> groups = {};
    for (final tx in transactions) {
      final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      (groups[dayKey] ??= []).add(tx);
    }

    // 2. Sort dates in reverse chronological order (newest date first)
    final sortedDates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    // 3. Sort items within each day: newest time first, stable secondary order
    for (final dayKey in sortedDates) {
      groups[dayKey]!.sort((a, b) {
        final timeComp = b.date.compareTo(a.date);
        if (timeComp != 0) return timeComp;
        final createdComp = b.createdAt.compareTo(a.createdAt);
        if (createdComp != 0) return createdComp;
        return b.id.compareTo(a.id);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedDates.map((date) {
        final dayItems = groups[date]!;
        final dayTotalUnits = dayItems.fold<int>(0, (sum, i) {
          // Transfers do not count towards income/expense totals
          if (i.type == LedgerItemType.transfer) return sum;
          return sum + i.amountUnits;
        });

        return _buildDateSection(
          context: context,
          date: date,
          items: dayItems,
          dayTotalUnits: dayTotalUnits,
          settings: settings,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildDateSection({
    required BuildContext context,
    required DateTime date,
    required List<LedgerItem> items,
    required int dayTotalUnits,
    required SettingsProvider settings,
    required bool isDark,
  }) {
    final dateHeading = _formatDateHeader(date);
    final formattedDayTotal = dayTotalUnits > 0
        ? Money.fromUnits(dayTotalUnits).format(currency: settings.currency)
        : null;

    final dividerColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Heading: [Date] ... [Day Total]
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dateHeading,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (formattedDayTotal != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    formattedDayTotal,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Direct list of transaction rows without unnecessary card container
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTransactionRow(
                  context: context,
                  item: item,
                  settings: settings,
                  isDark: isDark,
                ),
                if (index < items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 54,
                    endIndent: 8,
                    color: dividerColor,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionRow({
    required BuildContext context,
    required LedgerItem item,
    required SettingsProvider settings,
    required bool isDark,
  }) {
    // Resolve icon and colors
    IconData itemIcon;
    Color categoryColor;

    if (item.type == LedgerItemType.transfer) {
      itemIcon = Icons.swap_horiz_rounded;
      categoryColor = AppColors.transfer;
    } else {
      itemIcon = item.categoryIcon != null && item.categoryIcon!.isNotEmpty
          ? AppCategoryIcons.getIconData(item.categoryIcon!)
          : (item.type == LedgerItemType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);

      categoryColor = item.categoryColor != null
          ? Color(item.categoryColor!)
          : (item.type == LedgerItemType.income ? AppColors.income : AppColors.expense);
    }

    // Resolve Title
    final String title;
    if (item.type == LedgerItemType.transfer) {
      title = 'Transfer';
    } else {
      title = item.categoryName ?? (item.type == LedgerItemType.income ? 'Income' : 'Expense');
    }

    // Resolve Subtitle / Comment
    String? subtitle;
    if (item.type == LedgerItemType.transfer) {
      if (item.accountName != null && item.destinationAccountName != null) {
        subtitle = '${item.accountName} → ${item.destinationAccountName}';
      } else if (item.description.isNotEmpty && item.description != 'Transfer') {
        subtitle = item.description;
      }
    } else {
      if (item.description.isNotEmpty && item.description != title) {
        subtitle = item.description;
      } else if (item.notes != null && item.notes!.isNotEmpty) {
        subtitle = item.notes;
      } else if (showAccountName && item.accountName != null) {
        subtitle = item.accountName;
      }
    }

    final formattedAmount = item.amount.format(currency: settings.currency);

    // Keep transaction amount neutral and professional as required
    final amountColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    Widget rowContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemTap?.call(item),
        onLongPress: () async {
          if (onItemDelete == null && onItemTap == null) return;
          final action = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (onItemTap != null)
                    ListTile(
                      leading: const Icon(Icons.edit_rounded),
                      title: const Text('Edit Transaction'),
                      onTap: () => Navigator.pop(ctx, 'edit'),
                    ),
                  if (onItemDelete != null)
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                      title: const Text('Delete Transaction', style: TextStyle(color: AppColors.expense)),
                      onTap: () => Navigator.pop(ctx, 'delete'),
                    ),
                ],
              ),
            ),
          );

          if (action == 'edit' && onItemTap != null) {
            onItemTap?.call(item);
          } else if (action == 'delete' && onItemDelete != null && context.mounted) {
            final confirmed = await TransactionDeleteConfirmationDialog.show(
              context,
              amount: item.amount,
              accountName: item.accountName ?? 'Account',
              categoryName: item.categoryName ?? (item.type == LedgerItemType.transfer ? 'Transfer' : item.type.displayName),
              date: item.date,
              description: item.description,
            );
            if (confirmed == true && onItemDelete != null) {
              await onItemDelete!(item);
            }
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Category Icon
              AppCategoryIcon(
                icon: itemIcon,
                color: categoryColor,
                size: 38,
                iconSize: 22,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle / Comment
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isRecurring) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.repeat_rounded,
                            size: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Transaction Amount
              Text(
                formattedAmount,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return rowContent;
  }

  String _formatDateHeader(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final baseFormatted = '$weekday, ${date.day} $month ${date.year}';
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today • $baseFormatted';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday • $baseFormatted';
    }
    return baseFormatted;
  }
}
