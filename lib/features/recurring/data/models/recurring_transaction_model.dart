import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/recurring/domain/entities/recurring_transaction.dart';

class RecurringTransactionModel extends RecurringTransaction {
  const RecurringTransactionModel({
    required super.id,
    required super.transactionType,
    required super.accountId,
    required super.categoryId,
    required super.amount,
    required super.description,
    required super.frequency,
    super.interval = 1,
    required super.startDate,
    super.endDate,
    required super.nextExecutionDate,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.accountName,
    super.categoryName,
    super.categoryIcon,
    super.categoryColor,
  });

  factory RecurringTransactionModel.fromEntity(RecurringTransaction entity) {
    return RecurringTransactionModel(
      id: entity.id,
      transactionType: entity.transactionType,
      accountId: entity.accountId,
      categoryId: entity.categoryId,
      amount: entity.amount,
      description: entity.description,
      frequency: entity.frequency,
      interval: entity.interval,
      startDate: entity.startDate,
      endDate: entity.endDate,
      nextExecutionDate: entity.nextExecutionDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      accountName: entity.accountName,
      categoryName: entity.categoryName,
      categoryIcon: entity.categoryIcon,
      categoryColor: entity.categoryColor,
    );
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    final amountInt = map[DbColumns.amount] as int? ?? 0;
    final endDateInt = map[DbColumns.endDate] as int?;

    return RecurringTransactionModel(
      id: map[DbColumns.id] as String,
      transactionType: CategoryType.fromString(map[DbColumns.transactionType] as String),
      accountId: map[DbColumns.accountId] as String,
      categoryId: map[DbColumns.categoryId] as String,
      amount: Money(units: amountInt),
      description: map[DbColumns.description] as String,
      frequency: RecurringFrequency.fromString(map[DbColumns.frequency] as String),
      interval: map[DbColumns.interval] as int? ?? 1,
      startDate: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.startDate] as int),
      endDate: endDateInt != null ? DateTime.fromMillisecondsSinceEpoch(endDateInt) : null,
      nextExecutionDate: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.nextExecutionDate] as int),
      isActive: (map[DbColumns.isActive] as int? ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.createdAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.updatedAt] as int),
      accountName: map['account_name'] as String?,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbColumns.id: id,
      DbColumns.transactionType: transactionType.toDbString(),
      DbColumns.accountId: accountId,
      DbColumns.categoryId: categoryId,
      DbColumns.amount: amount.units,
      DbColumns.description: description,
      DbColumns.frequency: frequency.toDbString(),
      DbColumns.interval: interval,
      DbColumns.startDate: startDate.millisecondsSinceEpoch,
      DbColumns.endDate: endDate?.millisecondsSinceEpoch,
      DbColumns.nextExecutionDate: nextExecutionDate.millisecondsSinceEpoch,
      DbColumns.isActive: isActive ? 1 : 0,
      DbColumns.createdAt: createdAt.millisecondsSinceEpoch,
      DbColumns.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }
}
