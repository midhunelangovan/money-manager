import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_category_colors.dart';
import '../../../../core/constants/app_category_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? initialCategory;
  final CategoryType defaultType;
  final CategoryType? initialType;

  const AddEditCategoryScreen({
    super.key,
    this.initialCategory,
    this.defaultType = CategoryType.expense,
    this.initialType,
  });

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  late TextEditingController _nameController;
  late TextEditingController _searchController;
  late CategoryType _type;
  late int _selectedColor;
  String _selectedIconName = 'fastfood_rounded';
  bool _isSaving = false;
  String _searchQuery = '';
  final Set<String> _expandedGroups = AppCategoryIcons.groups.map((g) => g.title).toSet();

  // Curated 8 primary color shades for quick selection
  static final List<Color> _primaryQuickColors = [
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFEAB308), // Yellow
    const Color(0xFF10B981), // Green
    const Color(0xFF14B8A6), // Teal
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.initialCategory;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _searchController = TextEditingController();
    _type = cat?.type ?? (widget.initialType ?? widget.defaultType);
    _selectedColor = cat?.color ?? _primaryQuickColors[3].toARGB32(); // Default Green
    _selectedIconName = cat?.icon ?? (_type == CategoryType.income ? 'account_balance_wallet_rounded' : 'fastfood_rounded');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    final provider = context.read<CategoryProvider>();
    final isDuplicate = provider.categories.any((c) =>
        c.id != widget.initialCategory?.id &&
        c.type == _type &&
        c.name.trim().toLowerCase() == name.toLowerCase());

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A category named "$name" already exists for ${_type.displayName}.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final category = Category(
        id: widget.initialCategory?.id ?? IdGenerator.uuid(),
        name: name,
        type: _type,
        icon: _selectedIconName,
        color: _selectedColor,
        createdAt: widget.initialCategory?.createdAt ?? now,
        updatedAt: now,
      );

      final provider = context.read<CategoryProvider>();
      if (widget.initialCategory != null) {
        await provider.updateCategory(category);
      } else {
        await provider.createCategory(category);
      }

      if (mounted) {
        Navigator.pop(context, _type);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving category: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openFullColorPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Category Colors (100+ Shades)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Divider(color: isDark ? AppColors.darkBorderSubtle : null),
                Expanded(
                  child: ListView(
                    children: AppCategoryColors.shadeFamilies.map((family) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              family.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: family.shades.map((shade) {
                                final isSelected = _selectedColor == shade.toARGB32();
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedColor = shade.toARGB32());
                                    Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: shade,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: shade.withValues(alpha: 0.5),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = Color(_selectedColor);
    final activeIconData = AppCategoryIcons.getIconData(_selectedIconName);

    // Filtered icons for search
    final isSearching = _searchQuery.trim().isNotEmpty;
    final searchResults = <CategoryIconItem>[];
    if (isSearching) {
      final query = _searchQuery.trim().toLowerCase();
      for (final group in AppCategoryIcons.groups) {
        for (final item in group.icons) {
          if (item.label.toLowerCase().contains(query) ||
              item.id.toLowerCase().contains(query) ||
              item.searchKeywords.any((k) => k.toLowerCase().contains(query))) {
            searchResults.add(item);
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Header
          AppHeader(
            title: widget.initialCategory != null ? 'Edit Category' : 'Create Category',
          ),

          // Main Scrollable Customizer Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
              children: [
                // 1. Name Input with Live Circular Preview
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: activeColor, width: 2),
                        ),
                        child: Icon(activeIconData, color: activeColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'CATEGORY NAME',
                          controller: _nameController,
                          autofocus: widget.initialCategory == null,
                          textCapitalization: TextCapitalization.words,
                          hintText: 'e.g. Food, Groceries, Salary',
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Type Selector (Expense / Income)
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Text(
                        'Type',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      SegmentedButton<CategoryType>(
                        segments: const [
                          ButtonSegment(
                            value: CategoryType.expense,
                            label: Text('Expense'),
                            icon: Icon(Icons.arrow_downward_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: CategoryType.income,
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_upward_rounded, size: 16),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (set) {
                          if (set.isNotEmpty) {
                            setState(() {
                              _type = set.first;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Category Icons Browser with Search
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Icons',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),

                      // Search Field
                      AppTextField(
                        controller: _searchController,
                        hintText: 'Search icons (e.g. car, food, money)...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),

                      const SizedBox(height: 12),

                      // Search Results or Categorized Expandable Groups
                      if (isSearching) ...[
                        if (searchResults.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'No matching icons found',
                                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: searchResults.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (ctx, idx) => _buildIconTile(searchResults[idx], activeColor, isDark),
                          ),
                      ] else ...[
                        ...AppCategoryIcons.groups.map((group) {
                          final isExpanded = _expandedGroups.contains(group.title);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: isDark ? Border.all(color: AppColors.darkBorderSubtle) : null,
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedGroups.remove(group.title);
                                      } else {
                                        _expandedGroups.add(group.title);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(group.groupIcon, size: 18, color: isDark ? Theme.of(context).colorScheme.primary : AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          group.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${group.icons.length})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                          size: 20,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: group.icons.length,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 5,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 0.9,
                                      ),
                                      itemBuilder: (ctx, idx) => _buildIconTile(group.icons[idx], activeColor, isDark),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Color Selection (8-10 Curated Colors + [ More Colors ])
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Icon Color',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: activeColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _primaryQuickColors.map((color) {
                          final isSelected = _selectedColor == color.toARGB32();
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color.toARGB32()),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: const Icon(Icons.palette_outlined, size: 16),
                          label: const Text('More Colors (100+ Shades)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: () => _openFullColorPicker(context, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Fixed Save Button with Safe Area
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
          border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorderSubtle)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  widget.initialCategory != null ? 'Save Changes' : 'Create Category',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildIconTile(CategoryIconItem item, Color activeColor, bool isDark) {
    final isSelected = _selectedIconName == item.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedIconName = item.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.2)
                  : (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? activeColor : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? activeColor
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  size: 26,
                ),
                if (isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
