class DbTables {
  static const String accounts = 'accounts';
  static const String categories = 'categories';
  static const String transactions = 'transactions';
  static const String transfers = 'transfers';
  static const String recurringTransactions = 'recurring_transactions';
  static const String transactionAuditLogs = 'transaction_audit_logs';
  static const String reminders = 'reminders';
}

class DbColumns {
  // Common
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isArchived = 'is_archived';
  static const String name = 'name';
  static const String icon = 'icon';
  static const String color = 'color';
  static const String amount = 'amount';
  static const String date = 'date';
  static const String description = 'description';

  // Accounts
  static const String accountType = 'account_type';
  static const String openingBalance = 'opening_balance';
  static const String currency = 'currency';

  // Categories
  static const String type = 'type';
  static const String parentId = 'parent_id';
  static const String sortOrder = 'sort_order';

  // Transactions
  static const String transactionType = 'transaction_type';
  static const String accountId = 'account_id';
  static const String categoryId = 'category_id';
  static const String notes = 'notes';
  static const String recurringTransactionId = 'recurring_transaction_id';

  // Transactions & Transfers
  static const String receiptPath = 'receipt_path';

  // Transfers
  static const String fromAccountId = 'from_account_id';
  static const String toAccountId = 'to_account_id';

  // Recurring Transactions
  static const String frequency = 'frequency';
  static const String interval = 'interval';
  static const String startDate = 'start_date';
  static const String endDate = 'end_date';
  static const String nextExecutionDate = 'next_execution_date';
  static const String isActive = 'is_active';

  // Audit Logs
  static const String transactionId = 'transaction_id';
  static const String operation = 'operation';
  static const String changedAt = 'changed_at';

  // Reminders
  static const String time = 'time';
  static const String comment = 'comment';
  static const String isEnabled = 'is_enabled';
}
