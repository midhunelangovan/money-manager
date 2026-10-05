import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum LedgerTabType {
  expenses,
  income,
  transfer,
}

class TransactionTypeTabs extends StatelessWidget {
  final LedgerTabType selectedTab;
  final ValueChanged<LedgerTabType> onTabSelected;
  final bool showTransfer;
  final bool isHeaderStyle;

  const TransactionTypeTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.showTransfer = false,
    this.isHeaderStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabItem(
            label: 'EXPENSES',
            isSelected: selectedTab == LedgerTabType.expenses,
            onTap: () => onTabSelected(LedgerTabType.expenses),
            isHeaderStyle: isHeaderStyle,
          ),
        ),
        Expanded(
          child: _TabItem(
            label: 'INCOME',
            isSelected: selectedTab == LedgerTabType.income,
            onTap: () => onTabSelected(LedgerTabType.income),
            isHeaderStyle: isHeaderStyle,
          ),
        ),
        if (showTransfer)
          Expanded(
            child: _TabItem(
              label: 'TRANSFER',
              isSelected: selectedTab == LedgerTabType.transfer,
              onTap: () => onTabSelected(LedgerTabType.transfer),
              isHeaderStyle: isHeaderStyle,
            ),
          ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isHeaderStyle;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isHeaderStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeTextColor = isHeaderStyle
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : theme.colorScheme.primary);
    final inactiveTextColor = isHeaderStyle
        ? Colors.white.withValues(alpha: 0.6)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    final underlineColor = isHeaderStyle
        ? Colors.white
        : (isDark ? theme.colorScheme.primary : AppColors.primary);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? activeTextColor : inactiveTextColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? underlineColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
