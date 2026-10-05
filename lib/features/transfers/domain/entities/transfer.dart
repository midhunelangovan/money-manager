import '../../../../core/utilities/money.dart';

class Transfer {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final Money amount;
  final DateTime date;
  final String description;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined entity info for display
  final String? fromAccountName;
  final String? toAccountName;

  const Transfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    required this.description,
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
    this.fromAccountName,
    this.toAccountName,
  });

  Transfer copyWith({
    String? id,
    String? fromAccountId,
    String? toAccountId,
    Money? amount,
    DateTime? date,
    String? description,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fromAccountName,
    String? toAccountName,
  }) {
    return Transfer(
      id: id ?? this.id,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fromAccountName: fromAccountName ?? this.fromAccountName,
      toAccountName: toAccountName ?? this.toAccountName,
    );
  }

  String get sourceAccountId => fromAccountId;
  String get destinationAccountId => toAccountId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transfer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
