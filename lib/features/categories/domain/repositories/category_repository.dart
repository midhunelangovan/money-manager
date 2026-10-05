import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAllCategories({CategoryType? type, bool includeArchived = false});
  Future<List<CategoryWithSubcategories>> getCategoriesWithSubcategories({CategoryType? type, bool includeArchived = false});
  Future<Category?> getCategoryById(String id);
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> archiveCategory(String id, bool isArchived);
  Future<void> reorderCategories(List<String> orderedIds);
  Future<int> getTransactionCountForCategory(String categoryId);
}
