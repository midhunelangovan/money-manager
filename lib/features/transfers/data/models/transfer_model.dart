import '../../../../core/database/tables.dart';
import '../../../../core/utilities/money.dart';
import '../../domain/entities/transfer.dart';

class TransferModel extends Transfer {
  const TransferModel({
    required super.id,
    required super.fromAccountId,
    required super.toAccountId,
    required super.amount,
    required super.date,
    required super.description,
    super.receiptPath,
    required super.createdAt,
    required super.updatedAt,
    super.fromAccountName,
    super.toAccountName,
  });

  factory TransferModel.fromEntity(Transfer transfer) {
    return TransferModel(
      id: transfer.id,
      fromAccountId: transfer.fromAccountId,
      toAccountId: transfer.toAccountId,
      amount: transfer.amount,
      date: transfer.date,
      description: transfer.description,
      receiptPath: transfer.receiptPath,
      createdAt: transfer.createdAt,
      updatedAt: transfer.updatedAt,
      fromAccountName: transfer.fromAccountName,
      toAccountName: transfer.toAccountName,
    );
  }

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    final amountInt = map[DbColumns.amount] as int? ?? 0;
    return TransferModel(
      id: map[DbColumns.id] as String,
      fromAccountId: map[DbColumns.fromAccountId] as String,
      toAccountId: map[DbColumns.toAccountId] as String,
      amount: Money(units: amountInt),
      date: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.date] as int),
      description: map[DbColumns.description] as String,
      receiptPath: map[DbColumns.receiptPath] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.createdAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.updatedAt] as int),
      fromAccountName: map['from_account_name'] as String?,
      toAccountName: map['to_account_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbColumns.id: id,
      DbColumns.fromAccountId: fromAccountId,
      DbColumns.toAccountId: toAccountId,
      DbColumns.amount: amount.units,
      DbColumns.date: date.millisecondsSinceEpoch,
      DbColumns.description: description,
      DbColumns.receiptPath: receiptPath,
      DbColumns.createdAt: createdAt.millisecondsSinceEpoch,
      DbColumns.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }
}
