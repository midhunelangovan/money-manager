import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/audit_log.dart';

class AuditLogModel extends TransactionAuditLog {
  const AuditLogModel({
    required super.id,
    required super.transactionId,
    required super.operation,
    required super.amount,
    required super.accountId,
    super.accountName,
    super.categoryId,
    super.categoryName,
    required super.date,
    required super.description,
    super.notes,
    required super.changedAt,
  });

  factory AuditLogModel.fromEntity(TransactionAuditLog log) {
    return AuditLogModel(
      id: log.id,
      transactionId: log.transactionId,
      operation: log.operation,
      amount: log.amount,
      accountId: log.accountId,
      accountName: log.accountName,
      categoryId: log.categoryId,
      categoryName: log.categoryName,
      date: log.date,
      description: log.description,
      notes: log.notes,
      changedAt: log.changedAt,
    );
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    final amountInt = map[DbColumns.amount] as int? ?? 0;
    final opString = map[DbColumns.operation] as String? ?? 'CREATED';
    return AuditLogModel(
      id: map[DbColumns.id] as String,
      transactionId: map[DbColumns.transactionId] as String,
      operation: AuditOperation.fromString(opString),
      amount: Money(units: amountInt),
      accountId: map[DbColumns.accountId] as String,
      accountName: map['account_name'] as String?,
      categoryId: map[DbColumns.categoryId] as String?,
      categoryName: map['category_name'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.date] as int),
      description: map[DbColumns.description] as String? ?? '',
      notes: map[DbColumns.notes] as String?,
      changedAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.changedAt] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbColumns.id: id,
      DbColumns.transactionId: transactionId,
      DbColumns.operation: operation.toDbString(),
      DbColumns.amount: amount.units,
      DbColumns.accountId: accountId,
      DbColumns.categoryId: categoryId,
      DbColumns.date: date.millisecondsSinceEpoch,
      DbColumns.description: description,
      DbColumns.notes: notes,
      DbColumns.changedAt: changedAt.millisecondsSinceEpoch,
    };
  }
}
