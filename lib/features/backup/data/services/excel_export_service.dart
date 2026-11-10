import 'dart:io';
import 'package:excel/excel.dart';
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
  final bool exclusiveEndDate;
  final String? accountId;
  final LedgerItemType? typeFilter;
  final String? customFileName;

  const ExcelExportFilter({
    this.startDate,
    this.endDate,
    this.exclusiveEndDate = false,
    this.accountId,
    this.typeFilter,
    this.customFileName,
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

    // 1. Fetch matching transactions first so summary and transactions match exactly
    final ledgerItems = await transactionRepository.getUnifiedLedger(
      accountId: filter?.accountId,
      startDate: filter?.startDate,
      endDate: filter?.endDate,
      exclusiveEndDate: filter?.exclusiveEndDate ?? false,
      typeFilter: filter?.typeFilter,
      limit: 100000,
    );

    var totalIncome = 0.0;
    var totalExpense = 0.0;
    for (final item in ledgerItems) {
      if (item.itemType == LedgerItemType.income) {
        totalIncome += item.amount.toDoubleForDisplay();
      } else if (item.itemType == LedgerItemType.expense) {
        totalExpense += item.amount.toDoubleForDisplay();
      }
    }
    final netIncome = totalIncome - totalExpense;

    // 2. Summary Sheet
    final summarySheet = excel['Summary'];
    excel.setDefaultSheet('Summary');
    if (defaultSheet != 'Summary' && excel.sheets.containsKey(defaultSheet)) {
      excel.delete(defaultSheet);
    }

    summarySheet.appendRow([
      TextCellValue("${AppConstants.appName} - Financial Report"),
    ]);
    summarySheet.appendRow([
      TextCellValue('Generated on: ${DateFormatter.formatIsoDateTime(DateTime.now())}'),
    ]);
    if (filter?.startDate != null || filter?.endDate != null) {
      final endLabel = filter?.endDate != null
          ? DateFormatter.format(filter!.exclusiveEndDate
              ? filter.endDate!.subtract(const Duration(milliseconds: 1))
              : filter.endDate!)
          : 'Present';
      summarySheet.appendRow([
        TextCellValue(
          'Date Range: ${filter?.startDate != null ? DateFormatter.format(filter!.startDate!) : "All Time"} to $endLabel',
        ),
      ]);
    }
    if (filter?.typeFilter != null) {
      summarySheet.appendRow([
        TextCellValue('Transaction Type: ${filter!.typeFilter!.displayName}'),
      ]);
    }
    summarySheet.appendRow([TextCellValue('')]);

    summarySheet.appendRow([
      TextCellValue('Metric'),
      TextCellValue('Amount (INR)'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Income'),
      DoubleCellValue(totalIncome),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Expense'),
      DoubleCellValue(totalExpense),
    ]);
    summarySheet.appendRow([
      TextCellValue('Net Savings / Change'),
      DoubleCellValue(netIncome),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Transactions Count'),
      IntCellValue(ledgerItems.length),
    ]);

    // 3. Transactions Sheet (matching transactions within selected scope)
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

    // 5. Transfers Sheet (Included only if typeFilter is null or transfer)
    if (filter?.typeFilter == null || filter?.typeFilter == LedgerItemType.transfer) {
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
    final String fileName;
    if (filter?.customFileName != null && filter!.customFileName!.trim().isNotEmpty) {
      fileName = filter.customFileName!.endsWith(AppConstants.excelFileExtension)
          ? filter.customFileName!
          : '${filter.customFileName}${AppConstants.excelFileExtension}';
    } else if (filter?.startDate != null && filter?.endDate != null) {
      final s = filter!.startDate!;
      final e = filter.exclusiveEndDate ? filter.endDate!.subtract(const Duration(milliseconds: 1)) : filter.endDate!;
      final sStr = '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
      final eStr = '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
      if (sStr == eStr) {
        fileName = 'Kals_V2_Transactions_$sStr${AppConstants.excelFileExtension}';
      } else {
        fileName = 'Kals_V2_Transactions_${sStr}_to_$eStr${AppConstants.excelFileExtension}';
      }
    } else {
      fileName = 'Kals_V2_Transactions_${DateFormatter.formatBackupStamp(now)}${AppConstants.excelFileExtension}';
    }

    final file = await StorageHelper.saveToPublicDownloads(
      bytes: fileBytes,
      fileName: fileName,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    return file;
  }
}
