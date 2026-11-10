import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_category_colors.dart';
import '../../../../core/constants/app_category_icons.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/widgets/app_bottom_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
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
  late CategoryType _type;
  late int _selectedColor;
  late String _selectedIconName;
  bool _isSaving = false;
  String? _errorMessage;
  double? _plannedOutlay;

  // 15 Reference Grid Icons + 1 "More" action
  static const List<_GridIconData> _referenceGridIcons = [
    _GridIconData(id: 'receipt_long_rounded', label: 'Receipt', icon: Icons.receipt_long_rounded),
    _GridIconData(id: 'flight_rounded', label: 'Plane', icon: Icons.flight_rounded),
    _GridIconData(id: 'sell_rounded', label: 'Tag', icon: Icons.sell_rounded),
    _GridIconData(id: 'pets_rounded', label: 'Paw', icon: Icons.pets_rounded),
    _GridIconData(id: 'devices', label: 'Devices', icon: Icons.devices_rounded),
    _GridIconData(id: 'soup_kitchen_rounded', label: 'Cooking', icon: Icons.soup_kitchen_rounded),
    _GridIconData(id: 'paint', label: 'Paint', icon: Icons.brush_rounded),
    _GridIconData(id: 'dry_cleaning_rounded', label: 'Laundry', icon: Icons.local_laundry_service_rounded),
    _GridIconData(id: 'forest_rounded', label: 'Camping', icon: Icons.forest_rounded),
    _GridIconData(id: 'sports_esports_rounded', label: 'Gaming', icon: Icons.sports_esports_rounded),
    _GridIconData(id: 'directions_car_rounded', label: 'Car', icon: Icons.directions_car_rounded),
    _GridIconData(id: 'medical_services_rounded', label: 'Medical', icon: Icons.medical_services_rounded),
    _GridIconData(id: 'menu_book_rounded', label: 'Book', icon: Icons.menu_book_rounded),
    _GridIconData(id: 'checkroom_rounded', label: 'Shirt', icon: Icons.checkroom_rounded),
    _GridIconData(id: 'shoe', label: 'Shoe', icon: Icons.roller_skating_rounded),
    _GridIconData(id: 'more', label: 'More', icon: Icons.more_horiz_rounded, isMoreAction: true),
  ];

  // Curated matte colors matching reference
  static const List<Color> _curatedColors = [
    Color(0xFF23818D), // Kals Brand Teal
    Color(0xFF03323A), // Kals Petrol
    Color(0xFF109B73), // Matte Emerald
    Color(0xFF2563EB), // Matte Blue
    Color(0xFF7C3AED), // Matte Violet
    Color(0xFFEA580C), // Matte Orange
    Color(0xFFDC2626), // Matte Red
    Color(0xFFD5A328), // Matte Amber Gold
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.initialCategory;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _type = cat?.type ?? (widget.initialType ?? widget.defaultType);
    _selectedColor = cat?.color ?? _curatedColors[0].toARGB32();
    _selectedIconName = cat?.icon ?? (_type == CategoryType.income ? 'account_balance_wallet_rounded' : 'receipt_long_rounded');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a category name');
      return;
    }

    final provider = context.read<CategoryProvider>();
    final isDuplicate = provider.categories.any((c) =>
        c.id != widget.initialCategory?.id &&
        c.type == _type &&
        c.name.trim().toLowerCase() == name.toLowerCase());

    if (isDuplicate) {
      setState(() => _errorMessage = 'A category named "$name" already exists for ${_type.displayName}.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

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

      if (widget.initialCategory != null) {
        await provider.updateCategory(category);
      } else {
        await provider.createCategory(category);
      }

      if (mounted) {
        final isEdit = widget.initialCategory != null;
        Navigator.pop(context, _type);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final rootContext = MainNavigationService.navigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            AppSnackBar.showSuccess(
              rootContext,
              isEdit ? 'Category updated successfully.' : 'Category created successfully.',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error saving category: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openPlannedOutlayDialog() async {
    final currencyCode = context.read<SettingsProvider>().currencyCode;
    final controller = TextEditingController(
      text: _plannedOutlay != null ? _plannedOutlay!.toStringAsFixed(0) : '',
    );

    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Planned Outlay ($currencyCode / month)',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter amount (e.g. 5000)',
              prefixText: '$currencyCode ',
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, -1.0), // -1 means Clear
              child: const Text('Clear', style: TextStyle(color: AppColors.expense)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final val = double.tryParse(controller.text.trim());
                Navigator.pop(ctx, val);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _plannedOutlay = result < 0 ? null : result;
      });
    }
  }

  void _openFullIconSelector(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final activeColor = Color(_selectedColor);
            final filteredGroups = <CategoryIconGroup>[];
            for (final group in AppCategoryIcons.groups) {
              if (query.trim().isEmpty) {
                filteredGroups.add(group);
              } else {
                final q = query.trim().toLowerCase();
                final matching = group.icons.where((item) =>
                    item.label.toLowerCase().contains(q) ||
                    item.id.toLowerCase().contains(q) ||
                    item.searchKeywords.any((k) => k.toLowerCase().contains(q))).toList();
                if (matching.isNotEmpty) {
                  filteredGroups.add(CategoryIconGroup(
                    title: group.title,
                    groupIcon: group.groupIcon,
                    icons: matching,
                  ));
                }
              }
            }

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.80,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Category Icon',
                          style: TextStyle(
                            fontSize: 17,
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
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search icons (e.g. food, car, shopping)...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setModalState(() => query = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredGroups.isEmpty
                          ? Center(
                              child: Text(
                                'No matching icons found',
                                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredGroups.length,
                              itemBuilder: (ctx, gIdx) {
                                final group = filteredGroups[gIdx];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        group.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: group.icons.length,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 5,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 0.85,
                                      ),
                                      itemBuilder: (ctx, iIdx) {
                                        final item = group.icons[iIdx];
                                        final isSel = _selectedIconName == item.id;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() => _selectedIconName = item.id);
                                            Navigator.pop(ctx);
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Stack(
                                                clipBehavior: Clip.none,
                                                alignment: Alignment.center,
                                                children: [
                                                  Container(
                                                    width: 46,
                                                    height: 46,
                                                    decoration: BoxDecoration(
                                                      color: isSel ? activeColor : (isDark ? const Color(0xFF22303A) : const Color(0xFFE2E8F0)),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isSel ? activeColor : Colors.transparent,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        item.icon,
                                                        size: 24,
                                                        color: isSel ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSel)
                                                    Positioned(
                                                      top: -2,
                                                      right: -2,
                                                      child: Container(
                                                        width: 15,
                                                        height: 15,
                                                        decoration: BoxDecoration(
                                                          color: activeColor,
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.check_rounded,
                                                            size: 10,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                item.label,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyCode = context.watch<SettingsProvider>().currencyCode;
    final activeColor = Color(_selectedColor);
    final activeIconData = AppCategoryIcons.getIconData(_selectedIconName);

    final circleBg = isDark ? const Color(0xFF1E2832) : const Color(0xFF33414E);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Reusable Branded Curved Header matching reference
          AppHeader(
            title: widget.initialCategory != null ? 'Edit Category' : 'Create Category',
            centerTitle: false,
          ),

          // Scrollable Form Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              children: [
                // 1. Category Name Row with Circular Icon Preview
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Category Icon Preview Circle
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          activeIconData,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Underline Category Name Input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            autofocus: widget.initialCategory == null,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Category Name',
                              hintStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.only(bottom: 8),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              } else {
                                setState(() {});
                              }
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.expense,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Expense / Income Radio Selector
                Row(
                  children: [
                    _buildRadioOption(
                      label: 'Expenses',
                      selected: _type == CategoryType.expense,
                      onTap: () => setState(() => _type = CategoryType.expense),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 32),
                    _buildRadioOption(
                      label: 'Income',
                      selected: _type == CategoryType.income,
                      onTap: () => setState(() => _type = CategoryType.income),
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Planned Outlay Section
                Text(
                  'Planned outlay',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openPlannedOutlayDialog,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          _plannedOutlay != null
                              ? _plannedOutlay!.toStringAsFixed(0)
                              : '[ Not selected ]',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _plannedOutlay != null
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$currencyCode per month',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Icons Section Label
                Text(
                  'Icons',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // 4-Column Icon Grid (16 items)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _referenceGridIcons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (ctx, idx) {
                    final item = _referenceGridIcons[idx];
                    final isMore = item.isMoreAction;
                    final isSelected = !isMore && _selectedIconName == item.id;

                    return GestureDetector(
                      onTap: () {
                        if (isMore) {
                          _openFullIconSelector(context, isDark);
                        } else {
                          setState(() => _selectedIconName = item.id);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isMore
                                      ? (isDark ? const Color(0xFF1B3B38) : const Color(0xFFD6E8E6))
                                      : (isSelected ? activeColor : circleBg),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                          width: 2.5,
                                        )
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    item.icon,
                                    size: 26,
                                    color: isMore
                                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 17,
                                    height: 17,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBackground : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 5. Color Section Label
                Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Row of Color Swatches + (+) Action
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._curatedColors.map((color) {
                        final isSelected = _selectedColor == color.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color.toARGB32()),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.transparent,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }),

                      // (+) Custom Color Button
                      GestureDetector(
                        onTap: () => _openFullColorPicker(context, isDark),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // 6. Bottom Add Button (Warm yellow wide pill button)
          AppBottomButton(
            label: widget.initialCategory != null ? 'Save' : 'Add',
            onPressed: _nameController.text.trim().isEmpty ? null : _save,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveBorder = isDark ? AppColors.darkBorder : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? activeColor : inactiveBorder,
                  width: 2.0,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridIconData {
  final String id;
  final String label;
  final IconData icon;
  final bool isMoreAction;

  const _GridIconData({
    required this.id,
    required this.label,
    required this.icon,
    this.isMoreAction = false,
  });
}
