import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StatusBadgeType { success, warning, error, neutral, info }

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  const StatusBadge.type({
    super.key,
    required String label,
    required StatusBadgeType type,
    this.icon,
  })  : text = label,
        color = type == StatusBadgeType.success
            ? AppColors.income
            : (type == StatusBadgeType.warning
                ? AppColors.warning
                : (type == StatusBadgeType.error
                    ? AppColors.expense
                    : (type == StatusBadgeType.info ? AppColors.info : AppColors.lightTextSecondary)));

  factory StatusBadge.fromLabel({
    Key? key,
    required String label,
    StatusBadgeType type = StatusBadgeType.neutral,
  }) {
    return StatusBadge.type(key: key, label: label, type: type);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
