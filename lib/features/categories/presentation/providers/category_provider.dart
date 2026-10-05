import 'package:flutter/foundation.dart' hide Category;
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/domain/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository repository;

  CategoryProvider({required this.repository});

  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];
  List<CategoryWithSubcategories> _categoriesWithSubcategories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get expenseCategories => _expenseCategories;
  List<Category> get incomeCategories => _incomeCategories;
  List<Category> get categories => [..._expenseCategories, ..._incomeCategories];
  List<CategoryWithSubcategories> get categoriesWithSubcategories => _categoriesWithSubcategories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories({bool includeArchived = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenseCategories = await repository.getAllCategories(
        type: CategoryType.expense,
        includeArchived: includeArchived,
      );
      _incomeCategories = await repository.getAllCategories(
        type: CategoryType.income,
        includeArchived: includeArchived,
      );
      _categoriesWithSubcategories = await repository.getCategoriesWithSubcategories(
        includeArchived: includeArchived,
      );
    } catch (e) {
      _errorMessage = 'Unable to load categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCategory(Category category) async {
    try {
      await repository.createCategory(category);
      await loadCategories();
    } catch (e) {
      _errorMessage = 'Unable to create category: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await repository.updateCategory(category);
      await loadCategories();
    } catch (e) {
      _errorMessage = 'Unable to update category: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleArchive(String categoryId, bool isArchived) async {
    try {
      await repository.archiveCategory(categoryId, isArchived);
      await loadCategories(includeArchived: true);
    } catch (e) {
      _errorMessage = 'Unable to update category archive state: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reorderCategories(List<String> orderedIds) async {
    try {
      await repository.reorderCategories(orderedIds);
      await loadCategories();
    } catch (e) {
      _errorMessage = 'Unable to reorder categories: $e';
      notifyListeners();
      rethrow;
    }
  }
}
