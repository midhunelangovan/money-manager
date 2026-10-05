import 'package:flutter/material.dart';
import '../../features/categories/domain/entities/category.dart';
import '../theme/app_colors.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<Category> onCategorySelected;
  final VoidCallback onMoreTap;
  final int maxVisible;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onMoreTap,
    this.maxVisible = 7, // 7 items + 1 "More" item = 8 items (2 rows of 4)
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleCategories = categories.take(maxVisible).toList();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: visibleCategories.length + 1, // +1 for More
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 10,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, index) {
        if (index == visibleCategories.length) {
          // "More" category item
          return _CategoryItem(
            icon: Icons.add_rounded,
            label: 'More',
            color: isDark ? const Color(0xFF283646) : const Color(0xFFE2E8F0),
            iconColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            isSelected: false,
            onTap: onMoreTap,
          );
        }

        final category = visibleCategories[index];
        final isSelected = category.id == selectedCategoryId;
        final color = category.color != null ? Color(category.color!) : AppColors.primary;

        return _CategoryItem(
          icon: category.iconData,
          label: category.name,
          color: color,
          isSelected: isSelected,
          onTap: () => onCategorySelected(category),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : (isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : (isDark ? const Color(0xFF2C3A4E) : const Color(0xFFE2E8F0)),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? color : (iconColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                ),
                if (isSelected)
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF16202C) : Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.check, size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 28,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                height: 1.15,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
