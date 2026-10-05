import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/utilities/id_generator.dart';
import '../repositories/recurring_repository.dart';

class RecurringProcessingResult {
  final int processedCount;
  final int generatedTransactionsCount;
  final List<String> generatedTransactionIds;

  const RecurringProcessingResult({
    required this.processedCount,
    required this.generatedTransactionsCount,
    required this.generatedTransactionIds,
  });
}

class RecurringProcessor {
  final AppDatabase appDatabase;
  final RecurringRepository recurringRepository;

  RecurringProcessor({
    AppDatabase? database,
    required this.recurringRepository,
  }) : appDatabase = database ?? AppDatabase.instance;

  /// Processes all active recurring transactions that are due on or before [asOfDate].
  /// Guarantees idempotency: will never produce duplicate transactions if invoked multiple times.
  Future<RecurringProcessingResult> processDueTransactions({DateTime? asOfDate}) async {
    final targetDate = asOfDate ?? DateTime.now();
    final dueSchedules = await recurringRepository.getDueRecurringTransactions(targetDate);

    if (dueSchedules.isEmpty) {
      return const RecurringProcessingResult(
        processedCount: 0,
        generatedTransactionsCount: 0,
        generatedTransactionIds: [],
      );
    }

    final db = await appDatabase.database;
    final generatedIds = <String>[];

    await db.transaction((txn) async {
      for (final schedule in dueSchedules) {
        var curDate = schedule.nextExecutionDate;

        // Process all overdue instances up to targetDate (or max 12 iterations safety guard)
        int iterations = 0;
        while (curDate.isBefore(targetDate) || curDate.isAtSameMomentAs(targetDate)) {
          iterations++;
          if (iterations > 36) {
            // Safety guard against infinite loops in corrupt data
            break;
          }

          if (schedule.endDate != null && curDate.isAfter(schedule.endDate!)) {
            // Reached expiration
            await txn.update(
              DbTables.recurringTransactions,
              {
                DbColumns.isActive: 0,
                DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
              },
              where: '${DbColumns.id} = ?',
              whereArgs: [schedule.id],
            );
            break;
          }

          // Check if a transaction for this exact date and recurring schedule already exists (Idempotent guard)
          final existing = await txn.query(
            DbTables.transactions,
            where: '${DbColumns.recurringTransactionId} = ? AND ${DbColumns.date} = ?',
            whereArgs: [schedule.id, curDate.millisecondsSinceEpoch],
            limit: 1,
          );

          if (existing.isEmpty) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final txId = IdGenerator.generate();

            await txn.insert(DbTables.transactions, {
              DbColumns.id: txId,
              DbColumns.transactionType: schedule.transactionType.toDbString(),
              DbColumns.accountId: schedule.accountId,
              DbColumns.categoryId: schedule.categoryId,
              DbColumns.amount: schedule.amount.units,
              DbColumns.date: curDate.millisecondsSinceEpoch,
              DbColumns.description: schedule.description,
              DbColumns.notes: 'Auto-generated recurring transaction',
              DbColumns.recurringTransactionId: schedule.id,
              DbColumns.createdAt: now,
              DbColumns.updatedAt: now,
            });

            generatedIds.add(txId);
          }

          // Advance to next execution date
          final nextDate = schedule.calculateNextDate(curDate);
          curDate = nextDate;

          final isExpired = schedule.endDate != null && nextDate.isAfter(schedule.endDate!);

          await txn.update(
            DbTables.recurringTransactions,
            {
              DbColumns.nextExecutionDate: nextDate.millisecondsSinceEpoch,
              DbColumns.isActive: isExpired ? 0 : 1,
              DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
            },
            where: '${DbColumns.id} = ?',
            whereArgs: [schedule.id],
          );
        }
      }
    });

    return RecurringProcessingResult(
      processedCount: dueSchedules.length,
      generatedTransactionsCount: generatedIds.length,
      generatedTransactionIds: generatedIds,
    );
  }
}
