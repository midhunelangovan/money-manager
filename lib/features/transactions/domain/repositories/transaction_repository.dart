import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/audit_log.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';

enum DateFilterMode {
  allDates,
  singleDate,
  dateRange,
}

class TransactionFilter {
  final String? searchQuery;
  final LedgerItemType? typeFilter;
  final String? accountId;
  final String? categoryId;
  final DateTime? selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool exclusiveEndDate;
  final DateFilterMode dateMode;
  final Money? minAmount;
  final Money? maxAmount;
  final int limit;
  final int offset;

  const TransactionFilter({
    this.searchQuery,
    LedgerItemType? typeFilter,
    CategoryType? transactionType,
    this.accountId,
    this.categoryId,
    this.selectedDate,
    this.startDate,
    this.endDate,
    this.exclusiveEndDate = false,
    this.dateMode = DateFilterMode.allDates,
    this.minAmount,
    this.maxAmount,
    this.limit = 50,
    this.offset = 0,
  }) : typeFilter = typeFilter ??
            (transactionType == CategoryType.expense
                ? LedgerItemType.expense
                : transactionType == CategoryType.income
                    ? LedgerItemType.income
                    : null);

  CategoryType? get transactionType {
    if (typeFilter == LedgerItemType.expense) return CategoryType.expense;
    if (typeFilter == LedgerItemType.income) return CategoryType.income;
    return null;
  }

  bool get hasActiveFilters =>
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      typeFilter != null ||
      accountId != null ||
      categoryId != null ||
      dateMode != DateFilterMode.allDates ||
      minAmount != null ||
      maxAmount != null;

  TransactionFilter copyWith({
    String? searchQuery,
    LedgerItemType? typeFilter,
    CategoryType? transactionType,
    String? accountId,
    String? categoryId,
    DateTime? selectedDate,
    DateTime? startDate,
    DateTime? endDate,
    bool? exclusiveEndDate,
    DateFilterMode? dateMode,
    Money? minAmount,
    Money? maxAmount,
    int? limit,
    int? offset,
    bool clearSearchQuery = false,
    bool clearAccountId = false,
    bool clearCategoryId = false,
    bool clearTypeFilter = false,
    bool clearDates = false,
  }) {
    return TransactionFilter(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      typeFilter: clearTypeFilter
          ? null
          : (typeFilter ??
              (transactionType != null
                  ? (transactionType == CategoryType.expense
                      ? LedgerItemType.expense
                      : LedgerItemType.income)
                  : this.typeFilter)),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      selectedDate: clearDates ? null : (selectedDate ?? this.selectedDate),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      exclusiveEndDate: exclusiveEndDate ?? this.exclusiveEndDate,
      dateMode: clearDates ? DateFilterMode.allDates : (dateMode ?? this.dateMode),
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

class FinancialSummary {
  final Money totalIncome;
  final Money totalExpense;
  final Money netIncome;
  final int transactionCount;

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netIncome,
    required this.transactionCount,
  });

  const FinancialSummary.zero()
      : totalIncome = const Money.zero(),
        totalExpense = const Money.zero(),
        netIncome = const Money.zero(),
        transactionCount = 0;
}

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions(TransactionFilter filter);
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
  });
  Future<Transaction?> getTransactionById(String id);
  Future<void> createTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<FinancialSummary> getSummary({
    DateTime? startDate,
    DateTime? endDate,
    bool exclusiveEndDate = false,
    String? accountId,
  });
  Future<List<TransactionAuditLog>> getAuditLogsForTransaction(String transactionId);
  Future<void> recordAuditLog(TransactionAuditLog log);
}

