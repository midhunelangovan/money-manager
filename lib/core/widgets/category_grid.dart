import 'package:flutter/material.dart';
import '../../features/categories/domain/entities/category.dart';
import '../theme/app_colors.dart';
import 'app_category_icon.dart';

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
        childAspectRatio: 0.70,
      ),
      itemBuilder: (context, index) {
        if (index == visibleCategories.length) {
          // "More" category item
          return _CategoryTile(
            icon: Icons.add_rounded,
            label: 'More',
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            isSelected: false,
            onTap: onMoreTap,
          );
        }

        final category = visibleCategories[index];
        final isSelected = category.id == selectedCategoryId;
        final color = category.color != null ? Color(category.color!) : const Color(0xFF475569);

        return _CategoryTile(
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

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.color,
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
          AppCategoryIcon(
            icon: icon,
            color: color,
            size: 48,
            iconSize: 26,
            isSelected: isSelected,
          ),
          const SizedBox(height: 6),
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
