import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.transactionType,
    required super.accountId,
    required super.categoryId,
    required super.amount,
    required super.date,
    required super.description,
    super.notes,
    super.receiptPath,
    super.recurringTransactionId,
    required super.createdAt,
    required super.updatedAt,
    super.accountName,
    super.categoryName,
    super.categoryIcon,
    super.categoryColor,
  });

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      transactionType: transaction.transactionType,
      accountId: transaction.accountId,
      categoryId: transaction.categoryId,
      amount: transaction.amount,
      date: transaction.date,
      description: transaction.description,
      notes: transaction.notes,
      receiptPath: transaction.receiptPath,
      recurringTransactionId: transaction.recurringTransactionId,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      accountName: transaction.accountName,
      categoryName: transaction.categoryName,
      categoryIcon: transaction.categoryIcon,
      categoryColor: transaction.categoryColor,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final amountInt = map[DbColumns.amount] as int? ?? 0;
    return TransactionModel(
      id: map[DbColumns.id] as String,
      transactionType: CategoryType.fromString(map[DbColumns.transactionType] as String),
      accountId: map[DbColumns.accountId] as String,
      categoryId: map[DbColumns.categoryId] as String,
      amount: Money(units: amountInt),
      date: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.date] as int),
      description: map[DbColumns.description] as String,
      notes: map[DbColumns.notes] as String?,
      receiptPath: map[DbColumns.receiptPath] as String?,
      recurringTransactionId: map[DbColumns.recurringTransactionId] as String?,
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
      DbColumns.date: date.millisecondsSinceEpoch,
      DbColumns.description: description,
      DbColumns.notes: notes,
      DbColumns.receiptPath: receiptPath,
      DbColumns.recurringTransactionId: recurringTransactionId,
      DbColumns.createdAt: createdAt.millisecondsSinceEpoch,
      DbColumns.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }
}
