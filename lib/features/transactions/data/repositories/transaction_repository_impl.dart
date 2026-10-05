import 'package:sqflite/sqflite.dart' hide Transaction, DatabaseException;
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/error/exceptions.dart';
import 'package:kals_money_manager/core/utilities/id_generator.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/audit_log.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:kals_money_manager/features/transactions/data/models/audit_log_model.dart';
import 'package:kals_money_manager/features/transactions/data/models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase appDatabase;

  TransactionRepositoryImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    final db = await appDatabase.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      whereClauses.add('(${DbTables.transactions}.${DbColumns.description} LIKE ? OR ${DbTables.transactions}.${DbColumns.notes} LIKE ?)');
      final term = '%${filter.searchQuery!.trim()}%';
      whereArgs.addAll([term, term]);
    }
    if (filter.transactionType != null) {
      whereClauses.add('${DbTables.transactions}.${DbColumns.transactionType} = ?');
      whereArgs.add(filter.transactionType!.toDbString());
    }
    if (filter.accountId != null) {
      whereClauses.add('${DbTables.transactions}.${DbColumns.accountId} = ?');
      whereArgs.add(filter.accountId);
    }
    if (filter.categoryId != null) {
      whereClauses.add('${DbTables.transactions}.${DbColumns.categoryId} = ?');
      whereArgs.add(filter.categoryId);
    }
    if (filter.startDate != null) {
      whereClauses.add('${DbTables.transactions}.${DbColumns.date} >= ?');
      whereArgs.add(filter.startDate!.millisecondsSinceEpoch);
    }
    if (filter.endDate != null) {
      final op = filter.exclusiveEndDate ? '<' : '<=';
      whereClauses.add('${DbTables.transactions}.${DbColumns.date} $op ?');
      whereArgs.add(filter.endDate!.millisecondsSinceEpoch);
    }
    if (filter.minAmount != null) {
      whereClauses.add('${DbTables.transactions}.${DbColumns.amount} >= ?');
      whereArgs.add(filter.minAmount!.units);
    }
    if (filter.maxAmount != null) {
      whereClauses.add('${DbTables.transactions}.${DbColumns.amount} <= ?');
      whereArgs.add(filter.maxAmount!.units);
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final limitClause = filter.limit > 0 ? 'LIMIT ${filter.limit} OFFSET ${filter.offset}' : '';

    final query = '''
      SELECT 
        ${DbTables.transactions}.*,
        CASE WHEN acc.${DbColumns.isArchived} = 1 THEN acc.${DbColumns.name} || ' (Deleted)' ELSE acc.${DbColumns.name} END as account_name,
        cat.${DbColumns.name} as category_name,
        cat.${DbColumns.icon} as category_icon,
        cat.${DbColumns.color} as category_color
      FROM ${DbTables.transactions}
      LEFT JOIN ${DbTables.accounts} as acc ON ${DbTables.transactions}.${DbColumns.accountId} = acc.${DbColumns.id}
      LEFT JOIN ${DbTables.categories} as cat ON ${DbTables.transactions}.${DbColumns.categoryId} = cat.${DbColumns.id}
      ${where != null ? 'WHERE $where' : ''}
      ORDER BY ${DbTables.transactions}.${DbColumns.date} DESC
      $limitClause
    ''';

    final maps = await db.rawQuery(query, whereArgs);
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<List<LedgerItem>> getUnifiedLedger({
    LedgerItemType? typeFilter,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    bool exclusiveEndDate = false,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = await appDatabase.database;
    final txWhereClauses = <String>[];
    final txWhereArgs = <dynamic>[];
    final trWhereClauses = <String>[];
    final trWhereArgs = <dynamic>[];

    // Type filter
    if (typeFilter != null) {
      if (typeFilter == LedgerItemType.expense) {
        txWhereClauses.add("t.${DbColumns.transactionType} = 'EXPENSE'");
        trWhereClauses.add("1 = 0");
      } else if (typeFilter == LedgerItemType.income) {
        txWhereClauses.add("t.${DbColumns.transactionType} = 'INCOME'");
        trWhereClauses.add("1 = 0");
      } else if (typeFilter == LedgerItemType.transfer) {
        txWhereClauses.add("1 = 0");
      }
    }

    if (accountId != null) {
      txWhereClauses.add('t.${DbColumns.accountId} = ?');
      txWhereArgs.add(accountId);
      trWhereClauses.add('(tr.${DbColumns.fromAccountId} = ? OR tr.${DbColumns.toAccountId} = ?)');
      trWhereArgs.addAll([accountId, accountId]);
    }

    if (categoryId != null) {
      txWhereClauses.add('t.${DbColumns.categoryId} = ?');
      txWhereArgs.add(categoryId);
      trWhereClauses.add('1 = 0');
    }

    if (startDate != null) {
      final startMillis = startDate.millisecondsSinceEpoch;
      txWhereClauses.add('t.${DbColumns.date} >= ?');
      txWhereArgs.add(startMillis);
      trWhereClauses.add('tr.${DbColumns.date} >= ?');
      trWhereArgs.add(startMillis);
    }

    if (endDate != null) {
      final endMillis = endDate.millisecondsSinceEpoch;
      final op = exclusiveEndDate ? '<' : '<=';
      txWhereClauses.add('t.${DbColumns.date} $op ?');
      txWhereArgs.add(endMillis);
      trWhereClauses.add('tr.${DbColumns.date} $op ?');
      trWhereArgs.add(endMillis);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final pattern = '%${searchQuery.trim()}%';
      txWhereClauses.add('(t.${DbColumns.description} LIKE ? OR t.${DbColumns.notes} LIKE ? OR cat.${DbColumns.name} LIKE ? OR acc.${DbColumns.name} LIKE ?)');
      txWhereArgs.addAll([pattern, pattern, pattern, pattern]);
      trWhereClauses.add('(tr.${DbColumns.description} LIKE ? OR from_acc.${DbColumns.name} LIKE ? OR to_acc.${DbColumns.name} LIKE ?)');
      trWhereArgs.addAll([pattern, pattern, pattern]);
    }

    final txWhereStr = txWhereClauses.isNotEmpty ? 'WHERE ${txWhereClauses.join(' AND ')}' : '';
    final trWhereStr = trWhereClauses.isNotEmpty ? 'WHERE ${trWhereClauses.join(' AND ')}' : '';
    final limitClause = limit > 0 ? 'LIMIT $limit OFFSET $offset' : '';

    final query = '''
      SELECT 
        t.${DbColumns.id} as id,
        t.${DbColumns.transactionType} as item_type,
        t.${DbColumns.amount} as amount,
        t.${DbColumns.date} as date,
        t.${DbColumns.description} as description,
        t.${DbColumns.notes} as notes,
        t.${DbColumns.receiptPath} as receipt_path,
        t.${DbColumns.accountId} as account_id,
        CASE WHEN acc.${DbColumns.isArchived} = 1 THEN acc.${DbColumns.name} || ' (Deleted)' ELSE acc.${DbColumns.name} END as account_name,
        NULL as dest_account_id,
        NULL as dest_account_name,
        t.${DbColumns.categoryId} as category_id,
        cat.${DbColumns.name} as category_name,
        cat.${DbColumns.icon} as category_icon,
        cat.${DbColumns.color} as category_color,
        CASE WHEN t.${DbColumns.recurringTransactionId} IS NOT NULL THEN 1 ELSE 0 END as is_recurring,
        t.${DbColumns.createdAt} as created_at,
        t.${DbColumns.updatedAt} as updated_at
      FROM ${DbTables.transactions} as t
      LEFT JOIN ${DbTables.accounts} as acc ON t.${DbColumns.accountId} = acc.${DbColumns.id}
      LEFT JOIN ${DbTables.categories} as cat ON t.${DbColumns.categoryId} = cat.${DbColumns.id}
      $txWhereStr

      UNION ALL

      SELECT 
        tr.${DbColumns.id} as id,
        'TRANSFER' as item_type,
        tr.${DbColumns.amount} as amount,
        tr.${DbColumns.date} as date,
        tr.${DbColumns.description} as description,
        CASE WHEN tr.${DbColumns.description} != 'Transfer' AND tr.${DbColumns.description} != 'Imported Transfer' THEN tr.${DbColumns.description} ELSE NULL END as notes,
        tr.${DbColumns.receiptPath} as receipt_path,
        tr.${DbColumns.fromAccountId} as account_id,
        CASE WHEN from_acc.${DbColumns.isArchived} = 1 THEN from_acc.${DbColumns.name} || ' (Deleted)' ELSE from_acc.${DbColumns.name} END as account_name,
        tr.${DbColumns.toAccountId} as dest_account_id,
        CASE WHEN to_acc.${DbColumns.isArchived} = 1 THEN to_acc.${DbColumns.name} || ' (Deleted)' ELSE to_acc.${DbColumns.name} END as dest_account_name,
        NULL as category_id,
        'Transfer' as category_name,
        'swap_horiz' as category_icon,
        0xFF2563EB as category_color,
        0 as is_recurring,
        tr.${DbColumns.createdAt} as created_at,
        tr.${DbColumns.updatedAt} as updated_at
      FROM ${DbTables.transfers} as tr
      LEFT JOIN ${DbTables.accounts} as from_acc ON tr.${DbColumns.fromAccountId} = from_acc.${DbColumns.id}
      LEFT JOIN ${DbTables.accounts} as to_acc ON tr.${DbColumns.toAccountId} = to_acc.${DbColumns.id}
      $trWhereStr

      ORDER BY date DESC, created_at DESC
      $limitClause
    ''';

    final allArgs = [...txWhereArgs, ...trWhereArgs];
    final rows = await db.rawQuery(query, allArgs);

    return rows.map((r) {
      final typeStr = r['item_type'] as String;
      LedgerItemType type;
      if (typeStr == 'INCOME') {
        type = LedgerItemType.income;
      } else if (typeStr == 'EXPENSE') {
        type = LedgerItemType.expense;
      } else {
        type = LedgerItemType.transfer;
      }

      return LedgerItem(
        id: r['id'] as String,
        itemType: type,
        amount: Money(units: r['amount'] as int),
        date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
        description: r['description'] as String,
        notes: r['notes'] as String?,
        receiptPath: r['receipt_path'] as String?,
        accountId: r['account_id'] as String?,
        accountName: r['account_name'] as String?,
        destinationAccountId: r['dest_account_id'] as String?,
        destinationAccountName: r['dest_account_name'] as String?,
        categoryId: r['category_id'] as String?,
        categoryName: r['category_name'] as String?,
        categoryIcon: r['category_icon'] as String?,
        categoryColor: r['category_color'] as int?,
        isRecurring: (r['is_recurring'] as int? ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        updatedAt: r['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int) : null,
      );
    }).toList();
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final db = await appDatabase.database;
    final query = '''
      SELECT 
        ${DbTables.transactions}.*,
        acc.${DbColumns.name} as account_name,
        cat.${DbColumns.name} as category_name,
        cat.${DbColumns.icon} as category_icon,
        cat.${DbColumns.color} as category_color
      FROM ${DbTables.transactions}
      LEFT JOIN ${DbTables.accounts} as acc ON ${DbTables.transactions}.${DbColumns.accountId} = acc.${DbColumns.id}
      LEFT JOIN ${DbTables.categories} as cat ON ${DbTables.transactions}.${DbColumns.categoryId} = cat.${DbColumns.id}
      WHERE ${DbTables.transactions}.${DbColumns.id} = ?
      LIMIT 1
    ''';
    final maps = await db.rawQuery(query, [id]);
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  @override
  Future<void> createTransaction(Transaction transaction) async {
    if (transaction.amount.units <= 0) {
      throw const ValidationException('Transaction amount must be greater than zero');
    }
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      // Validate account exists
      final acc = await txn.query(
        DbTables.accounts,
        where: '${DbColumns.id} = ?',
        whereArgs: [transaction.accountId],
      );
      if (acc.isEmpty) {
        throw const ValidationException('Selected account does not exist');
      }

      // Validate category exists
      final cat = await txn.query(
        DbTables.categories,
        where: '${DbColumns.id} = ?',
        whereArgs: [transaction.categoryId],
      );
      if (cat.isEmpty) {
        throw const ValidationException('Selected category does not exist');
      }

      final model = TransactionModel.fromEntity(transaction);
      await txn.insert(
        DbTables.transactions,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      // Record audit history entry
      final now = DateTime.now();
      final auditLog = AuditLogModel(
        id: IdGenerator.generate(),
        transactionId: transaction.id,
        operation: AuditOperation.created,
        amount: transaction.amount,
        accountId: transaction.accountId,
        categoryId: transaction.categoryId,
        date: transaction.date,
        description: transaction.description,
        notes: transaction.notes,
        changedAt: now,
      );
      await txn.insert(
        DbTables.transactionAuditLogs,
        auditLog.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    if (transaction.amount.units <= 0) {
      throw const ValidationException('Transaction amount must be greater than zero');
    }
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final now = DateTime.now();
      final model = TransactionModel.fromEntity(transaction.copyWith(updatedAt: now));
      final count = await txn.update(
        DbTables.transactions,
        model.toMap(),
        where: '${DbColumns.id} = ?',
        whereArgs: [transaction.id],
      );
      if (count == 0) {
        throw DatabaseException('Transaction not found with ID ${transaction.id}');
      }

      // Record audit history entry for modification
      final auditLog = AuditLogModel(
        id: IdGenerator.generate(),
        transactionId: transaction.id,
        operation: AuditOperation.modified,
        amount: transaction.amount,
        accountId: transaction.accountId,
        categoryId: transaction.categoryId,
        date: transaction.date,
        description: transaction.description,
        notes: transaction.notes,
        changedAt: now,
      );
      await txn.insert(
        DbTables.transactionAuditLogs,
        auditLog.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final existingMaps = await txn.query(
        DbTables.transactions,
        where: '${DbColumns.id} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existingMaps.isNotEmpty) {
        final existing = TransactionModel.fromMap(existingMaps.first);
        // Record deletion in audit history
        final auditLog = AuditLogModel(
          id: IdGenerator.generate(),
          transactionId: existing.id,
          operation: AuditOperation.deleted,
          amount: existing.amount,
          accountId: existing.accountId,
          categoryId: existing.categoryId,
          date: existing.date,
          description: existing.description,
          notes: existing.notes,
          changedAt: DateTime.now(),
        );
        await txn.insert(
          DbTables.transactionAuditLogs,
          auditLog.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final count = await txn.delete(
        DbTables.transactions,
        where: '${DbColumns.id} = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw DatabaseException('Transaction not found with ID $id');
      }
    });
  }

  @override
  Future<List<TransactionAuditLog>> getAuditLogsForTransaction(String transactionId) async {
    final db = await appDatabase.database;
    final query = '''
      SELECT 
        l.*,
        acc.${DbColumns.name} as account_name,
        cat.${DbColumns.name} as category_name
      FROM ${DbTables.transactionAuditLogs} as l
      LEFT JOIN ${DbTables.accounts} as acc ON l.${DbColumns.accountId} = acc.${DbColumns.id}
      LEFT JOIN ${DbTables.categories} as cat ON l.${DbColumns.categoryId} = cat.${DbColumns.id}
      WHERE l.${DbColumns.transactionId} = ?
      ORDER BY l.${DbColumns.changedAt} ASC
    ''';

    final maps = await db.rawQuery(query, [transactionId]);
    return maps.map((m) => AuditLogModel.fromMap(m)).toList();
  }

  @override
  Future<void> recordAuditLog(TransactionAuditLog log) async {
    final db = await appDatabase.database;
    final model = AuditLogModel.fromEntity(log);
    await db.insert(
      DbTables.transactionAuditLogs,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<FinancialSummary> getSummary({
    DateTime? startDate,
    DateTime? endDate,
    bool exclusiveEndDate = false,
    String? accountId,
  }) async {
    final db = await appDatabase.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (accountId != null) {
      whereClauses.add('${DbColumns.accountId} = ?');
      whereArgs.add(accountId);
    }
    if (startDate != null) {
      whereClauses.add('${DbColumns.date} >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      final op = exclusiveEndDate ? '<' : '<=';
      whereClauses.add('${DbColumns.date} $op ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final where = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final query = '''
      SELECT
        COALESCE(SUM(CASE WHEN ${DbColumns.transactionType} = 'INCOME' THEN ${DbColumns.amount} ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN ${DbColumns.transactionType} = 'EXPENSE' THEN ${DbColumns.amount} ELSE 0 END), 0) as total_expense,
        COUNT(*) as total_count
      FROM ${DbTables.transactions}
      $where
    ''';

    final result = await db.rawQuery(query, whereArgs);
    final row = result.first;

    final incomeUnits = (row['total_income'] as num?)?.toInt() ?? 0;
    final expenseUnits = (row['total_expense'] as num?)?.toInt() ?? 0;
    final count = (row['total_count'] as num?)?.toInt() ?? 0;

    return FinancialSummary(
      totalIncome: Money(units: incomeUnits),
      totalExpense: Money(units: expenseUnits),
      netIncome: Money(units: incomeUnits - expenseUnits),
      transactionCount: count,
    );
  }
}

