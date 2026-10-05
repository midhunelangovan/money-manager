import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/transaction_type_tabs.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final bool isPickerMode;
  final ValueChanged<Category>? onCategorySelected;
  final CategoryType? initialType;

  const CategoriesScreen({
    super.key,
    this.isPickerMode = false,
    this.onCategorySelected,
    this.initialType,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late LedgerTabType _selectedTab;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = (widget.initialType == CategoryType.income)
        ? LedgerTabType.income
        : LedgerTabType.expenses;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryProvider>().loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    final isExpense = _selectedTab == LedgerTabType.expenses;
    final targetType = isExpense ? CategoryType.expense : CategoryType.income;

    final categories = catProvider.categories.where((c) {
      if (c.type != targetType) return false;
      if (_searchQuery.isNotEmpty) {
        return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: widget.isPickerMode ? null : const AppDrawer(),
      body: Column(
        children: [
          // Header with Title, Search Toggle, and EXPENSES/INCOME tabs
          AppHeader(
            showBackButton: false,
            leading: IconButton(
              icon: Icon(
                canPop ? Icons.arrow_back_rounded : Icons.menu_rounded,
                color: Colors.white,
                size: 26,
              ),
              tooltip: canPop ? 'Back' : 'Navigation Menu',
              onPressed: () {
                if (canPop) {
                  Navigator.pop(context);
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
            ),
            title: widget.isPickerMode ? 'Select Category' : 'Categories',
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.white,
                ),
                tooltip: _isSearching ? 'Close Search' : 'Search Categories',
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
            ],
            bottom: TransactionTypeTabs(
              selectedTab: _selectedTab,
              onTabSelected: (tab) => setState(() => _selectedTab = tab),
              isHeaderStyle: true,
            ),
          ),

          // Search Field when search icon is toggled
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AppTextField(
                controller: _searchController,
                autofocus: true,
                hintText: 'Search categories...',
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
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),

          // 4-Column Category Grid Body
          Expanded(
            child: catProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => catProvider.loadCategories(includeArchived: true),
                    child: categories.isEmpty
                        ? EmptyState(
                            icon: Icons.category_rounded,
                            title: _searchQuery.isEmpty ? 'No Categories Found' : 'No Matching Categories',
                            subtitle: _searchQuery.isEmpty
                                ? 'Tap the Create button below to add custom categories.'
                                : 'Try searching for a different keyword.',
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.70,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final color = cat.color != null ? Color(cat.color!) : AppColors.primary;

                              return GestureDetector(
                                onTap: () async {
                                  if (widget.isPickerMode && widget.onCategorySelected != null) {
                                    widget.onCategorySelected!(cat);
                                    Navigator.pop(context, cat);
                                  } else {
                                    final catProv = context.read<CategoryProvider>();
                                    final updated = await Navigator.of(context).push<dynamic>(
                                      MaterialPageRoute(
                                        builder: (_) => AddEditCategoryScreen(initialCategory: cat),
                                      ),
                                    );
                                    if (updated != null && mounted) {
                                      catProv.loadCategories();
                                    }
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.4),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(cat.iconData, color: color, size: 26),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 30,
                                      child: Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                            },
                          ),
                  ),
          ),

          // Bottom "+ Create" Category Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                final catProv = context.read<CategoryProvider>();
                final result = await Navigator.of(context).push<CategoryType>(
                  MaterialPageRoute(
                    builder: (_) => AddEditCategoryScreen(
                      initialType: targetType,
                    ),
                  ),
                );
                if (result != null && mounted) {
                  setState(() {
                    _selectedTab = result == CategoryType.income ? LedgerTabType.income : LedgerTabType.expenses;
                  });
                  catProv.loadCategories();
                }
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              label: const Text(
                'Create',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

