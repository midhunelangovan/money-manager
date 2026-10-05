import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';

class Transaction {
  final String id;
  final CategoryType transactionType; // INCOME or EXPENSE
  final String accountId;
  final String categoryId;
  final Money amount;
  final DateTime date;
  final String description;
  final String? notes;
  final String? receiptPath;
  final String? recurringTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined display attributes
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;

  const Transaction({
    required this.id,
    required this.transactionType,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.date,
    required this.description,
    this.notes,
    this.receiptPath,
    this.recurringTransactionId,
    required this.createdAt,
    required this.updatedAt,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  Transaction copyWith({
    String? id,
    CategoryType? transactionType,
    String? accountId,
    String? categoryId,
    Money? amount,
    DateTime? date,
    String? description,
    String? notes,
    String? receiptPath,
    String? recurringTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountName,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionType: transactionType ?? this.transactionType,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
      recurringTransactionId: recurringTransactionId ?? this.recurringTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Unified timeline item representing either a standard Transaction or a Transfer
enum LedgerItemType {
  income,
  expense,
  transfer;

  String get displayName {
    switch (this) {
      case LedgerItemType.income:
        return 'Income';
      case LedgerItemType.expense:
        return 'Expense';
      case LedgerItemType.transfer:
        return 'Transfer';
    }
  }
}

class LedgerItem {
  final String id;
  final LedgerItemType itemType;
  final Money amount;
  final DateTime date;
  final String description;
  final String? notes;
  final String? receiptPath;
  final String? accountId;
  final String? accountName;
  final String? destinationAccountId;
  final String? destinationAccountName;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LedgerItem({
    required this.id,
    required this.itemType,
    required this.amount,
    required this.date,
    required this.description,
    this.notes,
    this.receiptPath,
    this.accountId,
    this.accountName,
    this.destinationAccountId,
    this.destinationAccountName,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.isRecurring = false,
    required this.createdAt,
    this.updatedAt,
  });

  int get amountUnits => amount.units;
  LedgerItemType get type => itemType;

  /// True if modified after creation
  bool get isModified =>
      updatedAt != null &&
      updatedAt!.millisecondsSinceEpoch > createdAt.millisecondsSinceEpoch + 1000;
}
