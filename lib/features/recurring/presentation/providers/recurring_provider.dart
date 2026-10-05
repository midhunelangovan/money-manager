import 'package:flutter/foundation.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../../domain/services/recurring_processor.dart';

class RecurringProvider extends ChangeNotifier {
  final RecurringRepository repository;
  final RecurringProcessor processor;

  RecurringProvider({
    required this.repository,
    required this.processor,
  });

  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRecurring() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recurringTransactions = await repository.getAllRecurring(activeOnly: false);
    } catch (e) {
      _errorMessage = 'Unable to load recurring transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RecurringProcessingResult> processDueTransactions() async {
    try {
      final result = await processor.processDueTransactions();
      if (result.generatedTransactionsCount > 0) {
        await loadRecurring();
      }
      return result;
    } catch (e) {
      _errorMessage = 'Failed to process recurring transactions: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createRecurring(RecurringTransaction recurring) async {
    try {
      await repository.createRecurring(recurring);
      await loadRecurring();
    } catch (e) {
      _errorMessage = 'Unable to create recurring transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRecurring(RecurringTransaction recurring) async {
    try {
      await repository.updateRecurring(recurring);
      await loadRecurring();
    } catch (e) {
      _errorMessage = 'Unable to update recurring transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await repository.toggleActive(id, isActive);
      await loadRecurring();
    } catch (e) {
      _errorMessage = 'Unable to toggle status: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> skipNext(RecurringTransaction recurring) async {
    try {
      final next = recurring.calculateNextDate(recurring.nextExecutionDate);
      await repository.updateNextExecutionDate(recurring.id, next);
      await loadRecurring();
    } catch (e) {
      _errorMessage = 'Unable to skip occurrence: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecurring(String id) async {
    try {
      await repository.deleteRecurring(id);
      await loadRecurring();
    } catch (e) {
      _errorMessage = 'Unable to delete recurring transaction: $e';
      notifyListeners();
      rethrow;
    }
  }
}
