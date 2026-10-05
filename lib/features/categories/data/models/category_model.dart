import '../../../../core/database/tables.dart';
import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.type,
    super.parentId,
    super.icon,
    super.color,
    super.sortOrder = 0,
    super.isArchived = false,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
      parentId: category.parentId,
      icon: category.icon,
      color: category.color,
      sortOrder: category.sortOrder,
      isArchived: category.isArchived,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map[DbColumns.id] as String,
      name: map[DbColumns.name] as String,
      type: CategoryType.fromString(map[DbColumns.type] as String),
      parentId: map[DbColumns.parentId] as String?,
      icon: map[DbColumns.icon] as String?,
      color: map[DbColumns.color] as int?,
      sortOrder: map[DbColumns.sortOrder] as int? ?? 0,
      isArchived: (map[DbColumns.isArchived] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.createdAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.updatedAt] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbColumns.id: id,
      DbColumns.name: name,
      DbColumns.type: type.toDbString(),
      DbColumns.parentId: parentId,
      DbColumns.icon: icon,
      DbColumns.color: color,
      DbColumns.sortOrder: sortOrder,
      DbColumns.isArchived: isArchived ? 1 : 0,
      DbColumns.createdAt: createdAt.millisecondsSinceEpoch,
      DbColumns.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }
}
