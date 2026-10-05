import 'package:kals_money_manager/core/utilities/money.dart';

enum AuditOperation {
  created,
  modified,
  deleted;

  static AuditOperation fromString(String op) {
    switch (op.toUpperCase()) {
      case 'MODIFIED':
      case 'UPDATE':
      case 'UPDATED':
        return AuditOperation.modified;
      case 'DELETED':
      case 'DELETE':
        return AuditOperation.deleted;
      case 'CREATED':
      case 'CREATE':
      default:
        return AuditOperation.created;
    }
  }

  String get displayName {
    switch (this) {
      case AuditOperation.created:
        return 'Created';
      case AuditOperation.modified:
        return 'Modified';
      case AuditOperation.deleted:
        return 'Deleted';
    }
  }

  String toDbString() {
    switch (this) {
      case AuditOperation.created:
        return 'CREATED';
      case AuditOperation.modified:
        return 'MODIFIED';
      case AuditOperation.deleted:
        return 'DELETED';
    }
  }
}

class TransactionAuditLog {
  final String id;
  final String transactionId;
  final AuditOperation operation;
  final Money amount;
  final String accountId;
  final String? accountName;
  final String? categoryId;
  final String? categoryName;
  final DateTime date;
  final String description;
  final String? notes;
  final DateTime changedAt;

  const TransactionAuditLog({
    required this.id,
    required this.transactionId,
    required this.operation,
    required this.amount,
    required this.accountId,
    this.accountName,
    this.categoryId,
    this.categoryName,
    required this.date,
    required this.description,
    this.notes,
    required this.changedAt,
  });
}
