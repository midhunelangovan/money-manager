import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/error/exceptions.dart';
import 'package:kals_money_manager/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:kals_money_manager/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:kals_money_manager/features/recurring/data/models/recurring_transaction_model.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final AppDatabase appDatabase;

  RecurringRepositoryImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<List<RecurringTransaction>> getAllRecurring({bool activeOnly = false}) async {
    final db = await appDatabase.database;
    final where = activeOnly ? '${DbTables.recurringTransactions}.${DbColumns.isActive} = 1' : null;

    final query = '''
      SELECT 
        ${DbTables.recurringTransactions}.*,
        acc.${DbColumns.name} as account_name,
        cat.${DbColumns.name} as category_name,
        cat.${DbColumns.icon} as category_icon,
        cat.${DbColumns.color} as category_color
      FROM ${DbTables.recurringTransactions}
      LEFT JOIN ${DbTables.accounts} as acc ON ${DbTables.recurringTransactions}.${DbColumns.accountId} = acc.${DbColumns.id}
      LEFT JOIN ${DbTables.categories} as cat ON ${DbTables.recurringTransactions}.${DbColumns.categoryId} = cat.${DbColumns.id}
      ${where != null ? 'WHERE $where' : ''}
      ORDER BY ${DbTables.recurringTransactions}.${DbColumns.nextExecutionDate} ASC
    ''';

    final maps = await db.rawQuery(query);
    return maps.map((m) => RecurringTransactionModel.fromMap(m)).toList();
  }

  @override
  Future<List<RecurringTransaction>> getDueRecurringTransactions(DateTime asOfDate) async {
    final db = await appDatabase.database;
    final dateLimit = asOfDate.millisecondsSinceEpoch;

    final query = '''
      SELECT 
        ${DbTables.recurringTransactions}.*,
        acc.${DbColumns.name} as account_name,
        cat.${DbColumns.name} as category_name,
        cat.${DbColumns.icon} as category_icon,
        cat.${DbColumns.color} as category_color
      FROM ${DbTables.recurringTransactions}
      LEFT JOIN ${DbTables.accounts} as acc ON ${DbTables.recurringTransactions}.${DbColumns.accountId} = acc.${DbColumns.id}
      LEFT JOIN ${DbTables.categories} as cat ON ${DbTables.recurringTransactions}.${DbColumns.categoryId} = cat.${DbColumns.id}
      WHERE ${DbTables.recurringTransactions}.${DbColumns.isActive} = 1
        AND ${DbTables.recurringTransactions}.${DbColumns.nextExecutionDate} <= ?
      ORDER BY ${DbTables.recurringTransactions}.${DbColumns.nextExecutionDate} ASC
    ''';

    final maps = await db.rawQuery(query, [dateLimit]);
    return maps.map((m) => RecurringTransactionModel.fromMap(m)).toList();
  }

  @override
  Future<RecurringTransaction?> getRecurringById(String id) async {
    final db = await appDatabase.database;
    final query = '''
      SELECT 
        ${DbTables.recurringTransactions}.*,
        acc.${DbColumns.name} as account_name,
        cat.${DbColumns.name} as category_name,
        cat.${DbColumns.icon} as category_icon,
        cat.${DbColumns.color} as category_color
      FROM ${DbTables.recurringTransactions}
      LEFT JOIN ${DbTables.accounts} as acc ON ${DbTables.recurringTransactions}.${DbColumns.accountId} = acc.${DbColumns.id}
      LEFT JOIN ${DbTables.categories} as cat ON ${DbTables.recurringTransactions}.${DbColumns.categoryId} = cat.${DbColumns.id}
      WHERE ${DbTables.recurringTransactions}.${DbColumns.id} = ?
      LIMIT 1
    ''';
    final maps = await db.rawQuery(query, [id]);
    if (maps.isEmpty) return null;
    return RecurringTransactionModel.fromMap(maps.first);
  }

  @override
  Future<void> createRecurring(RecurringTransaction recurring) async {
    if (recurring.amount.units <= 0) {
      throw const ValidationException('Recurring amount must be greater than zero');
    }
    final db = await appDatabase.database;
    final model = RecurringTransactionModel.fromEntity(recurring);
    await db.insert(
      DbTables.recurringTransactions,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  @override
  Future<void> updateRecurring(RecurringTransaction recurring) async {
    if (recurring.amount.units <= 0) {
      throw const ValidationException('Recurring amount must be greater than zero');
    }
    final db = await appDatabase.database;
    final model = RecurringTransactionModel.fromEntity(recurring.copyWith(updatedAt: DateTime.now()));
    final count = await db.update(
      DbTables.recurringTransactions,
      model.toMap(),
      where: '${DbColumns.id} = ?',
      whereArgs: [recurring.id],
    );
    if (count == 0) {
      throw DatabaseException('Recurring transaction not found with ID ${recurring.id}');
    }
  }

  @override
  Future<void> toggleActive(String id, bool isActive) async {
    final db = await appDatabase.database;
    await db.update(
      DbTables.recurringTransactions,
      {
        DbColumns.isActive: isActive ? 1 : 0,
        DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteRecurring(String id) async {
    final db = await appDatabase.database;
    final count = await db.delete(
      DbTables.recurringTransactions,
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw DatabaseException('Recurring transaction not found with ID $id');
    }
  }

  @override
  Future<void> updateNextExecutionDate(String id, DateTime nextDate) async {
    final db = await appDatabase.database;
    await db.update(
      DbTables.recurringTransactions,
      {
        DbColumns.nextExecutionDate: nextDate.millisecondsSinceEpoch,
        DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
    );
  }
}
