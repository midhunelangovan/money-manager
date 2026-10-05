import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/tables.dart';
import 'package:kals_money_manager/core/error/exceptions.dart';
import 'package:kals_money_manager/features/transfers/domain/entities/transfer.dart';
import 'package:kals_money_manager/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:kals_money_manager/features/transfers/data/models/transfer_model.dart';

class TransferRepositoryImpl implements TransferRepository {
  final AppDatabase appDatabase;

  TransferRepositoryImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<List<Transfer>> getAllTransfers({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await appDatabase.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (accountId != null) {
      whereClauses.add('(${DbTables.transfers}.${DbColumns.fromAccountId} = ? OR ${DbTables.transfers}.${DbColumns.toAccountId} = ?)');
      whereArgs.addAll([accountId, accountId]);
    }
    if (startDate != null) {
      whereClauses.add('${DbTables.transfers}.${DbColumns.date} >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClauses.add('${DbTables.transfers}.${DbColumns.date} <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final query = '''
      SELECT 
        ${DbTables.transfers}.*,
        from_acc.${DbColumns.name} as from_account_name,
        to_acc.${DbColumns.name} as to_account_name
      FROM ${DbTables.transfers}
      LEFT JOIN ${DbTables.accounts} as from_acc ON ${DbTables.transfers}.${DbColumns.fromAccountId} = from_acc.${DbColumns.id}
      LEFT JOIN ${DbTables.accounts} as to_acc ON ${DbTables.transfers}.${DbColumns.toAccountId} = to_acc.${DbColumns.id}
      ${where != null ? 'WHERE $where' : ''}
      ORDER BY ${DbTables.transfers}.${DbColumns.date} DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';

    final maps = await db.rawQuery(query, whereArgs);
    return maps.map((m) => TransferModel.fromMap(m)).toList();
  }

  @override
  Future<Transfer?> getTransferById(String id) async {
    final db = await appDatabase.database;
    final query = '''
      SELECT 
        ${DbTables.transfers}.*,
        from_acc.${DbColumns.name} as from_account_name,
        to_acc.${DbColumns.name} as to_account_name
      FROM ${DbTables.transfers}
      LEFT JOIN ${DbTables.accounts} as from_acc ON ${DbTables.transfers}.${DbColumns.fromAccountId} = from_acc.${DbColumns.id}
      LEFT JOIN ${DbTables.accounts} as to_acc ON ${DbTables.transfers}.${DbColumns.toAccountId} = to_acc.${DbColumns.id}
      WHERE ${DbTables.transfers}.${DbColumns.id} = ?
      LIMIT 1
    ''';
    final maps = await db.rawQuery(query, [id]);
    if (maps.isEmpty) return null;
    return TransferModel.fromMap(maps.first);
  }

  @override
  Future<void> createTransfer(Transfer transfer) async {
    if (transfer.fromAccountId == transfer.toAccountId) {
      throw const ValidationException('Source and destination accounts cannot be the same');
    }
    if (transfer.amount.units <= 0) {
      throw const ValidationException('Transfer amount must be greater than zero');
    }

    final db = await appDatabase.database;
    await db.transaction((txn) async {
      // Validate accounts exist
      final fromAcc = await txn.query(
        DbTables.accounts,
        where: '${DbColumns.id} = ?',
        whereArgs: [transfer.fromAccountId],
      );
      final toAcc = await txn.query(
        DbTables.accounts,
        where: '${DbColumns.id} = ?',
        whereArgs: [transfer.toAccountId],
      );

      if (fromAcc.isEmpty || toAcc.isEmpty) {
        throw const ValidationException('One or both transfer accounts do not exist');
      }

      final model = TransferModel.fromEntity(transfer);
      await txn.insert(
        DbTables.transfers,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    });
  }

  @override
  Future<void> updateTransfer(Transfer transfer) async {
    if (transfer.fromAccountId == transfer.toAccountId) {
      throw const ValidationException('Source and destination accounts cannot be the same');
    }
    if (transfer.amount.units <= 0) {
      throw const ValidationException('Transfer amount must be greater than zero');
    }

    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final model = TransferModel.fromEntity(transfer.copyWith(updatedAt: DateTime.now()));
      final count = await txn.update(
        DbTables.transfers,
        model.toMap(),
        where: '${DbColumns.id} = ?',
        whereArgs: [transfer.id],
      );
      if (count == 0) {
        throw DatabaseException('Transfer not found with ID ${transfer.id}');
      }
    });
  }

  @override
  Future<void> deleteTransfer(String id) async {
    final db = await appDatabase.database;
    final count = await db.delete(
      DbTables.transfers,
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw DatabaseException('Transfer not found with ID $id');
    }
  }
}
