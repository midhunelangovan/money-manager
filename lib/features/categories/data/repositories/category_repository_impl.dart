import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/error/exceptions.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/domain/repositories/category_repository.dart';
import 'package:kals_money_manager/features/categories/data/models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase appDatabase;

  CategoryRepositoryImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<List<Category>> getAllCategories({
    CategoryType? type,
    bool includeArchived = false,
  }) async {
    final db = await appDatabase.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (!includeArchived) {
      whereClauses.add('${DbColumns.isArchived} = 0');
    }
    if (type != null) {
      whereClauses.add('${DbColumns.type} = ?');
      whereArgs.add(type.toDbString());
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final maps = await db.query(
      DbTables.categories,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '${DbColumns.sortOrder} ASC, ${DbColumns.name} ASC',
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  @override
  Future<List<CategoryWithSubcategories>> getCategoriesWithSubcategories({
    CategoryType? type,
    bool includeArchived = false,
  }) async {
    final allCategories = await getAllCategories(type: type, includeArchived: includeArchived);
    final parents = allCategories.where((c) => c.parentId == null).toList();
    final children = allCategories.where((c) => c.parentId != null).toList();

    return parents.map((parent) {
      final subs = children.where((child) => child.parentId == parent.id).toList();
      return CategoryWithSubcategories(category: parent, subcategories: subs);
    }).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final db = await appDatabase.database;
    final maps = await db.query(
      DbTables.categories,
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  @override
  Future<void> createCategory(Category category) async {
    final db = await appDatabase.database;
    final model = CategoryModel.fromEntity(category);
    await db.insert(
      DbTables.categories,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  @override
  Future<void> updateCategory(Category category) async {
    final db = await appDatabase.database;
    final model = CategoryModel.fromEntity(category.copyWith(updatedAt: DateTime.now()));
    final count = await db.update(
      DbTables.categories,
      model.toMap(),
      where: '${DbColumns.id} = ?',
      whereArgs: [category.id],
    );
    if (count == 0) {
      throw DatabaseException('Category not found with ID ${category.id}');
    }
  }

  @override
  Future<void> archiveCategory(String id, bool isArchived) async {
    final db = await appDatabase.database;
    await db.update(
      DbTables.categories,
      {
        DbColumns.isArchived: isArchived ? 1 : 0,
        DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> reorderCategories(List<String> orderedIds) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (int i = 0; i < orderedIds.length; i++) {
        batch.update(
          DbTables.categories,
          {
            DbColumns.sortOrder: i,
            DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
          },
          where: '${DbColumns.id} = ?',
          whereArgs: [orderedIds[i]],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<int> getTransactionCountForCategory(String categoryId) async {
    final db = await appDatabase.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM ${DbTables.transactions}
      WHERE ${DbColumns.categoryId} = ?
    ''', [categoryId]);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }
}
