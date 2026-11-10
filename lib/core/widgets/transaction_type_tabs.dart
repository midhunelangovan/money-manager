import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum LedgerTabType {
  expenses,
  income,
  transfer,
  all,
}

class TransactionTypeTabs extends StatelessWidget {
  final LedgerTabType selectedTab;
  final ValueChanged<LedgerTabType> onTabSelected;
  final bool showTransfer;
  final bool showAll;
  final bool isHeaderStyle;

  const TransactionTypeTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.showTransfer = false,
    this.showAll = false,
    this.isHeaderStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showAll)
          Expanded(
            child: _TabItem(
              label: 'ALL',
              isSelected: selectedTab == LedgerTabType.all,
              onTap: () => onTabSelected(LedgerTabType.all),
              isHeaderStyle: isHeaderStyle,
            ),
          ),
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
        ? Colors.white.withValues(alpha: 0.72)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    final underlineColor = isHeaderStyle
        ? Colors.white
        : (isDark ? theme.colorScheme.primary : AppColors.primary);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: 38,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeTextColor : inactiveTextColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.8,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Container(
              width: 56,
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? underlineColor : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}