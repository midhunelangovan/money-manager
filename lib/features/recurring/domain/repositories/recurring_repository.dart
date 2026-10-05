import '../entities/recurring_transaction.dart';

abstract class RecurringRepository {
  Future<List<RecurringTransaction>> getAllRecurring({bool activeOnly = false});
  Future<List<RecurringTransaction>> getDueRecurringTransactions(DateTime asOfDate);
  Future<RecurringTransaction?> getRecurringById(String id);
  Future<void> createRecurring(RecurringTransaction recurring);
  Future<void> updateRecurring(RecurringTransaction recurring);
  Future<void> toggleActive(String id, bool isActive);
  Future<void> deleteRecurring(String id);
  Future<void> updateNextExecutionDate(String id, DateTime nextDate);
}
