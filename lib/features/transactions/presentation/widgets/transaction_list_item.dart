import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_category_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/photo_preview_dialog.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/transaction.dart';

class TransactionListItem extends StatelessWidget {
  final LedgerItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Neutral professional text color for all transaction amounts
    final amountColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    IconData itemIcon = Icons.arrow_upward_rounded;
    Color iconColor = AppColors.expense;

    switch (item.type) {
      case LedgerItemType.income:
        itemIcon = Icons.arrow_downward_rounded;
        iconColor = AppColors.income;
        break;
      case LedgerItemType.expense:
        itemIcon = Icons.arrow_upward_rounded;
        iconColor = AppColors.expense;
        break;
      case LedgerItemType.transfer:
        itemIcon = Icons.swap_horiz_rounded;
        iconColor = AppColors.transfer;
        break;
    }

    // Resolve category icon or transfer icon
    if (item.type == LedgerItemType.transfer) {
      itemIcon = Icons.swap_horiz_rounded;
    } else if (item.categoryIcon != null && item.categoryIcon!.isNotEmpty) {
      itemIcon = AppCategoryIcons.getIconData(item.categoryIcon);
    }

    final categoryColor = item.categoryColor != null ? Color(item.categoryColor!) : iconColor;
    final formattedAmount = item.amount.format(currency: settings.currency);
    final hasAttachment = item.receiptPath != null && item.receiptPath!.isNotEmpty;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirmed = await TransactionDeleteConfirmationDialog.show(
          context,
          amount: item.amount,
          accountName: item.accountName ?? 'Account',
          categoryName: item.categoryName ?? item.itemType.displayName,
          date: item.date,
          description: item.description,
        );
        if (confirmed == true && onDelete != null) {
          onDelete!();
        }
        return confirmed;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              // Circular Category Icon (48×48 container, 26dp icon)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: Icon(
                  itemIcon,
                  color: categoryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle (Expanded to take remaining space safely)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.categoryName ?? (item.type == LedgerItemType.transfer ? 'Transfer' : item.description),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isRecurring) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.repeat_rounded,
                            size: 14,
                            color: AppColors.primaryLight,
                          ),
                        ],
                        if (hasAttachment) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => PhotoPreviewDialog.show(
                              context,
                              imagePath: item.receiptPath!,
                              title: item.categoryName ?? item.description,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_outlined, size: 12, color: AppColors.primary),
                                  SizedBox(width: 2),
                                  Text(
                                    'Photo',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.type == LedgerItemType.transfer
                          ? (item.description.isNotEmpty && item.description != 'Transfer' && item.description != 'Imported Transfer'
                              ? '${item.description} • ${item.accountName ?? ""} → ${item.destinationAccountName ?? ""}'
                              : '${item.accountName ?? ""} → ${item.destinationAccountName ?? ""}')
                          : () {
                              final comment = (item.notes != null && item.notes!.trim().isNotEmpty)
                                  ? item.notes!.trim()
                                  : ((item.description.isNotEmpty &&
                                      item.description != (item.categoryName ?? '') &&
                                      item.description != 'Transfer' &&
                                      item.description != 'Imported' &&
                                      item.description != 'Imported Transfer')
                                      ? item.description
                                      : '');
                              return comment.isNotEmpty
                                  ? '$comment • ${item.accountName ?? ""}'
                                  : (item.accountName ?? '');
                            }(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.isModified) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Modified • ${DateFormatter.formatDate(item.updatedAt!)} ${DateFormatter.formatTime(item.updatedAt!)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Guaranteed Width Amount and Time
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedAmount,
                      style: AppTypography.amountMedium.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatTime(item.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
