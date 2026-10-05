import 'package:flutter/material.dart';
import '../../../../core/utilities/money.dart';

enum AccountType {
  cash,
  bank,
  creditCard,
  wallet,
  investment,
  other;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.wallet:
        return 'Digital Wallet';
      case AccountType.investment:
        return 'Investment';
      case AccountType.other:
        return 'Other';
    }
  }

  static AccountType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'CASH':
        return AccountType.cash;
      case 'BANK':
        return AccountType.bank;
      case 'CREDIT_CARD':
      case 'CREDITCARD':
        return AccountType.creditCard;
      case 'WALLET':
        return AccountType.wallet;
      case 'INVESTMENT':
        return AccountType.investment;
      default:
        return AccountType.other;
    }
  }

  String toDbString() {
    switch (this) {
      case AccountType.cash:
        return 'CASH';
      case AccountType.bank:
        return 'BANK';
      case AccountType.creditCard:
        return 'CREDIT_CARD';
      case AccountType.wallet:
        return 'WALLET';
      case AccountType.investment:
        return 'INVESTMENT';
      case AccountType.other:
        return 'OTHER';
    }
  }
}

class Account {
  final String id;
  final String name;
  final AccountType accountType;
  final Money openingBalance;
  final String currency;
  final String? icon;
  final int? color;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.accountType,
    required this.openingBalance,
    this.currency = 'INR',
    this.icon,
    this.color,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? accountType,
    Money? openingBalance,
    String? currency,
    String? icon,
    int? color,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  IconData get iconData {
    switch (accountType) {
      case AccountType.cash:
        return Icons.money_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.wallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.investment:
        return Icons.trending_up_rounded;
      case AccountType.other:
        return Icons.savings_rounded;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AccountWithBalance {
  final Account account;
  final Money calculatedBalance;
  final Money totalIncome;
  final Money totalExpense;
  final Money totalTransfersIn;
  final Money totalTransfersOut;
  final int transactionCount;

  const AccountWithBalance({
    required this.account,
    required this.calculatedBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalTransfersIn,
    required this.totalTransfersOut,
    required this.transactionCount,
  });

  int get balanceUnits => calculatedBalance.units;
  Money get balance => calculatedBalance;
}
