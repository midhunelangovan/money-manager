import '../../../../core/database/tables.dart';
import '../../../../core/utilities/money.dart';
import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.accountType,
    required super.openingBalance,
    super.currency = 'INR',
    super.icon,
    super.color,
    super.isArchived = false,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AccountModel.fromEntity(Account account) {
    return AccountModel(
      id: account.id,
      name: account.name,
      accountType: account.accountType,
      openingBalance: account.openingBalance,
      currency: account.currency,
      icon: account.icon,
      color: account.color,
      isArchived: account.isArchived,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
    );
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    final currency = map[DbColumns.currency] as String? ?? 'INR';
    final openingBalanceInt = map[DbColumns.openingBalance] as int? ?? 0;

    return AccountModel(
      id: map[DbColumns.id] as String,
      name: map[DbColumns.name] as String,
      accountType: AccountType.fromString(map[DbColumns.accountType] as String),
      openingBalance: Money(units: openingBalanceInt, currencyCode: currency),
      currency: currency,
      icon: map[DbColumns.icon] as String?,
      color: map[DbColumns.color] as int?,
      isArchived: (map[DbColumns.isArchived] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.createdAt] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[DbColumns.updatedAt] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbColumns.id: id,
      DbColumns.name: name,
      DbColumns.accountType: accountType.toDbString(),
      DbColumns.openingBalance: openingBalance.units,
      DbColumns.currency: currency,
      DbColumns.icon: icon,
      DbColumns.color: color,
      DbColumns.isArchived: isArchived ? 1 : 0,
      DbColumns.createdAt: createdAt.millisecondsSinceEpoch,
      DbColumns.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }
}
