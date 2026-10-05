import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/error/exceptions.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/domain/repositories/account_repository.dart';
import 'package:kals_money_manager/features/accounts/data/models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase appDatabase;

  AccountRepositoryImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<List<Account>> getAllAccounts({bool includeArchived = false}) async {
    final db = await appDatabase.database;
    final where = includeArchived ? null : '${DbColumns.isArchived} = 0';
    final maps = await db.query(
      DbTables.accounts,
      where: where,
      orderBy: '${DbColumns.name} ASC',
    );
    return maps.map((m) => AccountModel.fromMap(m)).toList();
  }

  @override
  Future<Account?> getAccountById(String id) async {
    final db = await appDatabase.database;
    final maps = await db.query(
      DbTables.accounts,
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AccountModel.fromMap(maps.first);
  }

  @override
  Future<List<AccountWithBalance>> getAccountsWithBalances({bool includeArchived = false}) async {
    final accounts = await getAllAccounts(includeArchived: includeArchived);
    final results = <AccountWithBalance>[];

    for (final account in accounts) {
      final withBal = await getAccountWithBalance(account.id);
      if (withBal != null) {
        results.add(withBal);
      }
    }
    return results;
  }

  @override
  Future<AccountWithBalance?> getAccountWithBalance(String id) async {
    final db = await appDatabase.database;
    final account = await getAccountById(id);
    if (account == null) return null;

    // 1. Calculate Income
    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DbColumns.amount}), 0) as total
      FROM ${DbTables.transactions}
      WHERE ${DbColumns.accountId} = ? AND ${DbColumns.transactionType} = 'INCOME'
    ''', [id]);
    final incomeUnits = (incomeResult.first['total'] as num?)?.toInt() ?? 0;

    // 2. Calculate Expense
    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DbColumns.amount}), 0) as total
      FROM ${DbTables.transactions}
      WHERE ${DbColumns.accountId} = ? AND ${DbColumns.transactionType} = 'EXPENSE'
    ''', [id]);
    final expenseUnits = (expenseResult.first['total'] as num?)?.toInt() ?? 0;

    // 3. Calculate Transfers In
    final transfersInResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DbColumns.amount}), 0) as total
      FROM ${DbTables.transfers}
      WHERE ${DbColumns.toAccountId} = ?
    ''', [id]);
    final transfersInUnits = (transfersInResult.first['total'] as num?)?.toInt() ?? 0;

    // 4. Calculate Transfers Out
    final transfersOutResult = await db.rawQuery('''
      SELECT COALESCE(SUM(${DbColumns.amount}), 0) as total
      FROM ${DbTables.transfers}
      WHERE ${DbColumns.fromAccountId} = ?
    ''', [id]);
    final transfersOutUnits = (transfersOutResult.first['total'] as num?)?.toInt() ?? 0;

    // 5. Total Transactions Count
    final countResult = await db.rawQuery('''
      SELECT (
        (SELECT COUNT(*) FROM ${DbTables.transactions} WHERE ${DbColumns.accountId} = ?) +
        (SELECT COUNT(*) FROM ${DbTables.transfers} WHERE ${DbColumns.fromAccountId} = ? OR ${DbColumns.toAccountId} = ?)
      ) as total
    ''', [id, id, id]);
    final txCount = (countResult.first['total'] as num?)?.toInt() ?? 0;

    final balanceUnits = account.openingBalance.units +
        incomeUnits -
        expenseUnits +
        transfersInUnits -
        transfersOutUnits;

    final currency = account.currency;

    return AccountWithBalance(
      account: account,
      calculatedBalance: Money(units: balanceUnits, currencyCode: currency),
      totalIncome: Money(units: incomeUnits, currencyCode: currency),
      totalExpense: Money(units: expenseUnits, currencyCode: currency),
      totalTransfersIn: Money(units: transfersInUnits, currencyCode: currency),
      totalTransfersOut: Money(units: transfersOutUnits, currencyCode: currency),
      transactionCount: txCount,
    );
  }

  @override
  Future<void> createAccount(Account account) async {
    final db = await appDatabase.database;
    final model = AccountModel.fromEntity(account);
    await db.insert(
      DbTables.accounts,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  @override
  Future<void> updateAccount(Account account) async {
    final db = await appDatabase.database;
    final model = AccountModel.fromEntity(account.copyWith(updatedAt: DateTime.now()));
    final count = await db.update(
      DbTables.accounts,
      model.toMap(),
      where: '${DbColumns.id} = ?',
      whereArgs: [account.id],
    );
    if (count == 0) {
      throw DatabaseException('Account not found with ID ${account.id}');
    }
  }

  @override
  Future<void> archiveAccount(String id, bool isArchived) async {
    final db = await appDatabase.database;
    await db.update(
      DbTables.accounts,
      {
        DbColumns.isArchived: isArchived ? 1 : 0,
        DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> getTransactionCountForAccount(String accountId) async {
    final db = await appDatabase.database;
    final result = await db.rawQuery('''
      SELECT (
        (SELECT COUNT(*) FROM ${DbTables.transactions} WHERE ${DbColumns.accountId} = ?) +
        (SELECT COUNT(*) FROM ${DbTables.transfers} WHERE ${DbColumns.fromAccountId} = ? OR ${DbColumns.toAccountId} = ?)
      ) as total
    ''', [accountId, accountId, accountId]);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }
}
