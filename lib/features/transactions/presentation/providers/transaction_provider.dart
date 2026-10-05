import 'package:flutter/foundation.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository repository;

  TransactionProvider({required this.repository});

  List<LedgerItem> _ledgerItems = [];
  List<LedgerItem> _allLedgerItems = [];
  TransactionFilter _filter = const TransactionFilter();
  FinancialSummary _monthlySummary = const FinancialSummary.zero();
  FinancialSummary _globalSummary = const FinancialSummary.zero();
  bool _isLoading = false;
  String? _errorMessage;

  List<LedgerItem> get ledgerItems => _ledgerItems;
  List<LedgerItem> get allLedgerItems => _allLedgerItems;
  TransactionFilter get filter => _filter;
  FinancialSummary get monthlySummary => _monthlySummary;
  FinancialSummary get globalSummary => _globalSummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateFilter(TransactionFilter newFilter) {
    _filter = newFilter;
    loadLedger();
  }

  void resetFilter() {
    _filter = const TransactionFilter();
    loadLedger();
  }

  Future<void> loadLedger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      DateTime? effectiveStart;
      DateTime? effectiveEnd;
      bool effectiveExclusive = false;

      if (_filter.dateMode == DateFilterMode.singleDate && _filter.selectedDate != null) {
        final d = _filter.selectedDate!;
        effectiveStart = DateTime(d.year, d.month, d.day, 0, 0, 0);
        effectiveEnd = DateTime(d.year, d.month, d.day + 1, 0, 0, 0);
        effectiveExclusive = true;
      } else if (_filter.dateMode == DateFilterMode.dateRange) {
        effectiveStart = _filter.startDate;
        effectiveEnd = _filter.endDate;
        effectiveExclusive = _filter.exclusiveEndDate;
      }

      // 1. Fetch filtered items for transactions list
      _ledgerItems = await repository.getUnifiedLedger(
        typeFilter: _filter.typeFilter,
        accountId: _filter.accountId,
        categoryId: _filter.categoryId,
        startDate: effectiveStart,
        endDate: effectiveEnd,
        exclusiveEndDate: effectiveExclusive,
        searchQuery: _filter.searchQuery,
        limit: _filter.limit,
        offset: _filter.offset,
      );

      // 2. Fetch comprehensive items for dashboard period filtering & calculations
      _allLedgerItems = await repository.getUnifiedLedger(
        limit: -1, // Retrieve all items without truncation
        offset: 0,
      );

      final now = DateTime.now();
      _monthlySummary = await repository.getSummary(
        startDate: now.startOfMonth,
        endDate: now.endOfMonth,
      );

      _globalSummary = await repository.getSummary();
    } catch (e) {
      _errorMessage = 'Unable to load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<LedgerItem>> getItemsForRange({
    DateTime? startDate,
    DateTime? endDate,
    bool exclusiveEndDate = false,
    String? accountId,
  }) async {
    return await repository.getUnifiedLedger(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      exclusiveEndDate: exclusiveEndDate,
      limit: -1, // No limit cutoff
      offset: 0,
    );
  }

  Future<FinancialSummary> getSummaryForRange({
    DateTime? startDate,
    DateTime? endDate,
    bool exclusiveEndDate = false,
    String? accountId,
  }) async {
    return await repository.getSummary(
      startDate: startDate,
      endDate: endDate,
      exclusiveEndDate: exclusiveEndDate,
      accountId: accountId,
    );
  }

  Future<void> createTransaction(Transaction transaction) async {
    try {
      await repository.createTransaction(transaction);
      await loadLedger();
    } catch (e) {
      _errorMessage = 'Unable to save transaction. Your existing data has not been changed.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await repository.updateTransaction(transaction);
      await loadLedger();
    } catch (e) {
      _errorMessage = 'Unable to update transaction. Your existing data has not been changed.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await repository.deleteTransaction(id);
      await loadLedger();
    } catch (e) {
      _errorMessage = 'Unable to delete transaction: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<List<TransactionAuditLog>> getAuditLogs(String transactionId) async {
    try {
      return await repository.getAuditLogsForTransaction(transactionId);
    } catch (e) {
      return [];
    }
  }
}
