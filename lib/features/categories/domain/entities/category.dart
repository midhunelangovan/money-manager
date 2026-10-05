import 'package:flutter/material.dart';
import '../../../../core/constants/app_category_icons.dart';

enum CategoryType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case CategoryType.income:
        return 'Income';
      case CategoryType.expense:
        return 'Expense';
    }
  }

  static CategoryType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'INCOME':
        return CategoryType.income;
      case 'EXPENSE':
      default:
        return CategoryType.expense;
    }
  }

  String toDbString() {
    switch (this) {
      case CategoryType.income:
        return 'INCOME';
      case CategoryType.expense:
        return 'EXPENSE';
    }
  }
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final String? parentId;
  final String? icon;
  final int? color;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? parentId,
    String? icon,
    int? color,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  IconData get iconData => AppCategoryIcons.getIconData(icon);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CategoryWithSubcategories {
  final Category category;
  final List<Category> subcategories;

  const CategoryWithSubcategories({
    required this.category,
    this.subcategories = const [],
  });
}
