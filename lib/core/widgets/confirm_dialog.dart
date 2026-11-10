import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utilities/date_formatter.dart';
import '../utilities/money.dart';

class TransactionDeleteConfirmationDialog extends StatelessWidget {
  final Money amount;
  final String accountName;
  final String categoryName;
  final DateTime date;
  final String description;

  const TransactionDeleteConfirmationDialog({
    super.key,
    required this.amount,
    required this.accountName,
    required this.categoryName,
    required this.date,
    required this.description,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Money amount,
    required String accountName,
    required String categoryName,
    required DateTime date,
    required String description,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => TransactionDeleteConfirmationDialog(
        amount: amount,
        accountName: accountName,
        categoryName: categoryName,
        date: date,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 28),
          SizedBox(width: 10),
          Text(
            'Delete this transaction?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2433) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2E3D52) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Amount', amount.format(), isBold: true, valueColor: AppColors.expense),
            const Divider(height: 16),
            _buildRow('Account', accountName),
            const SizedBox(height: 8),
            _buildRow('Category', categoryName),
            const SizedBox(height: 8),
            _buildRow('Date', DateFormatter.format(date)),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRow('Description', description),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
            minimumSize: const Size(110, 42),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
/// Confirmation dialog shown when attempting to leave a transaction form with unsaved changes.
class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DiscardChangesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Discard unsaved changes?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: const Text(
        "You have entered transaction details that haven't been saved. Do you want to discard them?",
        style: TextStyle(fontSize: 14.5, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            'Keep Editing',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Discard',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
