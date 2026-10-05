import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/storage_helper.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../recurring/domain/repositories/recurring_repository.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../transfers/domain/repositories/transfer_repository.dart';

class ExcelExportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? accountId;

  const ExcelExportFilter({
    this.startDate,
    this.endDate,
    this.accountId,
  });
}

class ExcelExportService {
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;
  final TransactionRepository transactionRepository;
  final TransferRepository transferRepository;
  final RecurringRepository recurringRepository;

  ExcelExportService({
    required this.accountRepository,
    required this.categoryRepository,
    required this.transactionRepository,
    required this.transferRepository,
    required this.recurringRepository,
  });

  Future<File> generateExcelWorkbook({ExcelExportFilter? filter}) async {
    final excel = Excel.createExcel();
    // Default sheet is usually Sheet1, rename or replace
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    // 1. Summary Sheet
    final summarySheet = excel['Summary'];
    excel.setDefaultSheet('Summary');
    if (defaultSheet != 'Summary' && excel.sheets.containsKey(defaultSheet)) {
      excel.delete(defaultSheet);
    }

    final summary = await transactionRepository.getSummary(
      startDate: filter?.startDate,
      endDate: filter?.endDate,
      accountId: filter?.accountId,
    );

    summarySheet.appendRow([
      TextCellValue("Kal's Money Manager - Financial Report"),
    ]);
    summarySheet.appendRow([
      TextCellValue('Generated on: ${DateFormatter.formatIsoDateTime(DateTime.now())}'),
    ]);
    if (filter?.startDate != null || filter?.endDate != null) {
      summarySheet.appendRow([
        TextCellValue(
          'Date Range: ${filter?.startDate != null ? DateFormatter.format(filter!.startDate!) : "All Time"} to ${filter?.endDate != null ? DateFormatter.format(filter!.endDate!) : "Present"}',
        ),
      ]);
    }
    summarySheet.appendRow([TextCellValue('')]);

    summarySheet.appendRow([
      TextCellValue('Metric'),
      TextCellValue('Amount (INR)'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Income'),
      DoubleCellValue(summary.totalIncome.toDoubleForDisplay()),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Expense'),
      DoubleCellValue(summary.totalExpense.toDoubleForDisplay()),
    ]);
    summarySheet.appendRow([
      TextCellValue('Net Savings / Change'),
      DoubleCellValue(summary.netIncome.toDoubleForDisplay()),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Transactions Count'),
      IntCellValue(summary.transactionCount),
    ]);

    // 2. Transactions Sheet (All transactions + transfers within selected duration)
    final txSheet = excel['Transactions'];
    txSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Amount'),
      TextCellValue('Currency'),
      TextCellValue('Account'),
      TextCellValue('Category'),
      TextCellValue('Comment'),
      TextCellValue('Attachment'),
    ]);

    final ledgerItems = await transactionRepository.getUnifiedLedger(
      accountId: filter?.accountId,
      startDate: filter?.startDate,
      endDate: filter?.endDate,
      limit: 100000,
    );

    for (final item in ledgerItems) {
      final accountDisplay = item.type == LedgerItemType.transfer
          ? '${item.accountName ?? item.accountId} → ${item.destinationAccountName ?? item.destinationAccountId}'
          : (item.accountName ?? item.accountId);
      final hasAttachment = item.receiptPath != null && item.receiptPath!.isNotEmpty;

      final comment = (item.notes != null && item.notes!.trim().isNotEmpty)
          ? item.notes!.trim()
          : ((item.description.isNotEmpty &&
              item.description != (item.categoryName ?? '') &&
              item.description != 'Transfer' &&
              item.description != 'Imported' &&
              item.description != 'Imported Transfer')
              ? item.description
              : '');

      txSheet.appendRow([
        TextCellValue(DateFormatter.format(item.date)),
        TextCellValue(item.type.displayName),
        DoubleCellValue(item.amount.toDoubleForDisplay()),
        TextCellValue('INR'),
        TextCellValue(accountDisplay ?? ''),
        TextCellValue(item.categoryName ?? (item.type == LedgerItemType.transfer ? 'Transfer' : '-')),
        TextCellValue(comment),
        TextCellValue(hasAttachment ? 'Yes' : 'No'),
      ]);
    }

    // 3. Accounts Sheet
    final accSheet = excel['Accounts'];
    accSheet.appendRow([
      TextCellValue('Account Name'),
      TextCellValue('Account Type'),
      TextCellValue('Opening Balance (INR)'),
      TextCellValue('Current Balance (INR)'),
      TextCellValue('Total Income'),
      TextCellValue('Total Expense'),
      TextCellValue('Status'),
    ]);
    final accountsWithBalance = await accountRepository.getAccountsWithBalances(includeArchived: true);
    for (final acc in accountsWithBalance) {
      accSheet.appendRow([
        TextCellValue(acc.account.name),
        TextCellValue(acc.account.accountType.displayName),
        DoubleCellValue(acc.account.openingBalance.toDoubleForDisplay()),
        DoubleCellValue(acc.calculatedBalance.toDoubleForDisplay()),
        DoubleCellValue(acc.totalIncome.toDoubleForDisplay()),
        DoubleCellValue(acc.totalExpense.toDoubleForDisplay()),
        TextCellValue(acc.account.isArchived ? 'Archived' : 'Active'),
      ]);
    }

    // 4. Categories Sheet
    final catSheet = excel['Categories'];
    catSheet.appendRow([
      TextCellValue('Category Name'),
      TextCellValue('Type'),
      TextCellValue('Status'),
      TextCellValue('Order'),
    ]);
    final categories = await categoryRepository.getAllCategories(includeArchived: true);
    for (final cat in categories) {
      catSheet.appendRow([
        TextCellValue(cat.name),
        TextCellValue(cat.type.displayName),
        TextCellValue(cat.isArchived ? 'Archived' : 'Active'),
        IntCellValue(cat.sortOrder),
      ]);
    }

    // 5. Transfers Sheet
    final trSheet = excel['Transfers'];
    trSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('From Account'),
      TextCellValue('To Account'),
      TextCellValue('Amount (INR)'),
      TextCellValue('Description'),
      TextCellValue('Created At'),
    ]);
    final transfers = await transferRepository.getAllTransfers(
      startDate: filter?.startDate,
      endDate: filter?.endDate,
      accountId: filter?.accountId,
      limit: 50000,
    );
    for (final tr in transfers) {
      trSheet.appendRow([
        TextCellValue(DateFormatter.format(tr.date)),
        TextCellValue(tr.fromAccountName ?? tr.fromAccountId),
        TextCellValue(tr.toAccountName ?? tr.toAccountId),
        DoubleCellValue(tr.amount.toDoubleForDisplay()),
        TextCellValue(tr.description),
        TextCellValue(DateFormatter.formatIsoDateTime(tr.createdAt)),
      ]);
    }

    // 6. Recurring Transactions Sheet
    final recSheet = excel['Recurring'];
    recSheet.appendRow([
      TextCellValue('Description'),
      TextCellValue('Type'),
      TextCellValue('Account'),
      TextCellValue('Category'),
      TextCellValue('Amount (INR)'),
      TextCellValue('Frequency'),
      TextCellValue('Next Execution'),
      TextCellValue('Status'),
    ]);
    final recurring = await recurringRepository.getAllRecurring(activeOnly: false);
    for (final rec in recurring) {
      recSheet.appendRow([
        TextCellValue(rec.description),
        TextCellValue(rec.transactionType.displayName),
        TextCellValue(rec.accountName ?? rec.accountId),
        TextCellValue(rec.categoryName ?? rec.categoryId),
        DoubleCellValue(rec.amount.toDoubleForDisplay()),
        TextCellValue('${rec.frequency.displayName} (Interval: ${rec.interval})'),
        TextCellValue(DateFormatter.format(rec.nextExecutionDate)),
        TextCellValue(rec.isActive ? 'Active' : 'Paused/Ended'),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel bytes');
    }

    final now = DateTime.now();
    final fileName = 'MoneyManager_Export_${DateFormatter.formatBackupStamp(now)}${AppConstants.excelFileExtension}';

    final exportDir = await StorageHelper.getDownloadsDirectory();
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final file = File(p.join(exportDir.path, fileName));
    await file.writeAsBytes(fileBytes, flush: true);

    // Verify file creation and non-zero size
    final isValid = await StorageHelper.verifyFileExistsAndNonEmpty(file);
    if (!isValid) {
      throw Exception('Export failed: file could not be verified in storage');
    }

    return file;
  }
}
