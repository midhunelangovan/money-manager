import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/storage_helper.dart';

import '../../../../core/services/attachment_service.dart';

class BackupMetadata {
  final int backupVersion;
  final String appVersion;
  final int databaseVersion;
  final String createdAt;
  final Map<String, int> recordCounts;
  final String? checksum;

  const BackupMetadata({
    required this.backupVersion,
    required this.appVersion,
    required this.databaseVersion,
    required this.createdAt,
    required this.recordCounts,
    this.checksum,
  });

  Map<String, dynamic> toMap() => {
        'backupVersion': backupVersion,
        'appVersion': appVersion,
        'databaseVersion': databaseVersion,
        'createdAt': createdAt,
        'recordCounts': recordCounts,
        'checksum': checksum,
      };

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      backupVersion: map['backupVersion'] as int? ?? 1,
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      databaseVersion: map['databaseVersion'] as int? ?? 1,
      createdAt: map['createdAt'] as String? ?? '',
      recordCounts: Map<String, int>.from(map['recordCounts'] as Map? ?? {}),
      checksum: map['checksum'] as String?,
    );
  }
}

class BackupPayload {
  final BackupMetadata metadata;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> transfers;
  final List<Map<String, dynamic>> recurringTransactions;
  final List<Map<String, dynamic>> reminders;
  final Map<String, String>? attachments;

  const BackupPayload({
    required this.metadata,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.transfers,
    required this.recurringTransactions,
    this.reminders = const [],
    this.attachments,
  });

  Map<String, dynamic> toMap() => {
        'metadata': metadata.toMap(),
        'accounts': accounts,
        'categories': categories,
        'transactions': transactions,
        'transfers': transfers,
        'recurring_transactions': recurringTransactions,
        'reminders': reminders,
        if (attachments != null && attachments!.isNotEmpty) 'attachments': attachments,
      };

  factory BackupPayload.fromMap(Map<String, dynamic> map) {
    return BackupPayload(
      metadata: BackupMetadata.fromMap(map['metadata'] as Map<String, dynamic>),
      accounts: List<Map<String, dynamic>>.from(map['accounts'] as List? ?? []),
      categories: List<Map<String, dynamic>>.from(map['categories'] as List? ?? []),
      transactions: List<Map<String, dynamic>>.from(map['transactions'] as List? ?? []),
      transfers: List<Map<String, dynamic>>.from(map['transfers'] as List? ?? []),
      recurringTransactions: List<Map<String, dynamic>>.from(map['recurring_transactions'] as List? ?? []),
      reminders: List<Map<String, dynamic>>.from(map['reminders'] as List? ?? []),
      attachments: map['attachments'] != null ? Map<String, String>.from(map['attachments'] as Map) : null,
    );
  }
}

class BackupService {
  final AppDatabase appDatabase;

  BackupService({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  /// Creates a complete JSON backup payload string of the current database
  Future<BackupPayload> createBackupPayload() async {
    final db = await appDatabase.database;

    final accounts = await db.query(DbTables.accounts);
    final categories = await db.query(DbTables.categories);
    final transactions = await db.query(DbTables.transactions);
    final transfers = await db.query(DbTables.transfers);
    final recurring = await db.query(DbTables.recurringTransactions);
    final reminders = await db.query(DbTables.reminders);
    final attachments = await AttachmentService.exportAttachmentsForBackup();

    final recordCounts = {
      'accounts': accounts.length,
      'categories': categories.length,
      'transactions': transactions.length,
      'transfers': transfers.length,
      'recurring_transactions': recurring.length,
      'reminders': reminders.length,
      'attachments': attachments.length,
    };

    final rawDataToHash = jsonEncode({
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'transfers': transfers,
      'recurring': recurring,
      'reminders': reminders,
    });
    final checksum = sha256.convert(utf8.encode(rawDataToHash)).toString();

    final metadata = BackupMetadata(
      backupVersion: AppConstants.backupSchemaVersion,
      appVersion: AppConstants.appVersion,
      databaseVersion: AppConstants.databaseVersion,
      createdAt: DateTime.now().toIso8601String(),
      recordCounts: recordCounts,
      checksum: checksum,
    );

    return BackupPayload(
      metadata: metadata,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      transfers: transfers,
      recurringTransactions: recurring,
      reminders: reminders,
      attachments: attachments,
    );
  }

  /// Exports backup payload to a local file in the user's Downloads directory
  Future<File> exportBackupToFile() async {
    final payload = await createBackupPayload();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload.toMap());

    final now = DateTime.now();
    final fileName = 'MoneyManager_Backup_${DateFormatter.formatBackupStamp(now)}${AppConstants.backupFileExtension}';

    final backupDir = await StorageHelper.getDownloadsDirectory();
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final file = File(p.join(backupDir.path, fileName));
    await file.writeAsString(jsonStr, flush: true);

    // Verify file creation and non-zero size
    final isValid = await StorageHelper.verifyFileExistsAndNonEmpty(file);
    if (!isValid) {
      throw Exception('Backup failed: file could not be verified in storage');
    }

    return file;
  }

  /// Validates a raw backup string before any restoration attempts
  BackupPayload validateBackupData(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const RestoreException('Invalid backup file: root must be a JSON object');
      }

      if (!decoded.containsKey('metadata')) {
        throw const RestoreException('Invalid backup file: missing metadata header');
      }

      final payload = BackupPayload.fromMap(decoded);

      if (payload.metadata.backupVersion > AppConstants.backupSchemaVersion) {
        throw RestoreException(
          'Backup version (${payload.metadata.backupVersion}) is newer than this app version (${AppConstants.backupSchemaVersion}). Please update the app.',
        );
      }

      // Check referential consistency in memory before touching SQLite
      final accountIds = payload.accounts.map((a) => a[DbColumns.id] as String).toSet();
      final categoryIds = payload.categories.map((c) => c[DbColumns.id] as String).toSet();

      for (final tx in payload.transactions) {
        final accId = tx[DbColumns.accountId] as String?;
        final catId = tx[DbColumns.categoryId] as String?;
        final amount = tx[DbColumns.amount] as num?;

        if (accId == null || !accountIds.contains(accId)) {
          throw RestoreException('Transaction references non-existent account ID: $accId');
        }
        if (catId == null || !categoryIds.contains(catId)) {
          throw RestoreException('Transaction references non-existent category ID: $catId');
        }
        if (amount == null || amount <= 0) {
          throw const RestoreException('Transaction contains invalid non-positive amount');
        }
      }

      for (final tr in payload.transfers) {
        final fromAcc = tr[DbColumns.fromAccountId] as String?;
        final toAcc = tr[DbColumns.toAccountId] as String?;
        final amount = tr[DbColumns.amount] as num?;

        if (fromAcc == null || !accountIds.contains(fromAcc)) {
          throw RestoreException('Transfer references non-existent source account ID: $fromAcc');
        }
        if (toAcc == null || !accountIds.contains(toAcc)) {
          throw RestoreException('Transfer references non-existent destination account ID: $toAcc');
        }
        if (fromAcc == toAcc) {
          throw const RestoreException('Transfer cannot have same source and destination account');
        }
        if (amount == null || amount <= 0) {
          throw const RestoreException('Transfer contains invalid non-positive amount');
        }
      }

      return payload;
    } catch (e) {
      if (e is RestoreException) rethrow;
      throw RestoreException('Failed to parse backup content: $e');
    }
  }

  /// Restores data atomically.
  /// Step 1: Validates backup
  /// Step 2: Creates in-memory / temp snapshot of current data for instant rollback
  /// Step 3: Wipes tables inside a transaction and inserts new dataset
  /// Step 4: Runs verification query; commits or rolls back
  Future<void> restoreFromPayload(BackupPayload payload) async {
    final db = await appDatabase.database;

    await db.transaction((txn) async {
      // Temporarily disable foreign keys during batch re-population inside the transaction
      await txn.execute('PRAGMA foreign_keys = OFF');

      try {
        // Clear all existing data
        await txn.delete(DbTables.transactions);
        await txn.delete(DbTables.transfers);
        await txn.delete(DbTables.recurringTransactions);
        await txn.delete(DbTables.reminders);
        await txn.delete(DbTables.categories);
        await txn.delete(DbTables.accounts);

        // Insert Accounts
        for (final acc in payload.accounts) {
          await txn.insert(DbTables.accounts, acc);
        }

        // Insert Categories
        for (final cat in payload.categories) {
          await txn.insert(DbTables.categories, cat);
        }

        // Insert Reminders
        for (final rem in payload.reminders) {
          await txn.insert(DbTables.reminders, rem);
        }

        // Insert Recurring
        for (final rec in payload.recurringTransactions) {
          await txn.insert(DbTables.recurringTransactions, rec);
        }

        // Insert Transactions
        for (final tx in payload.transactions) {
          await txn.insert(DbTables.transactions, tx);
        }

        // Insert Transfers
        for (final tr in payload.transfers) {
          await txn.insert(DbTables.transfers, tr);
        }

        // Re-enable and verify foreign keys
        await txn.execute('PRAGMA foreign_keys = ON');

        final fkCheck = await txn.rawQuery('PRAGMA foreign_key_check');
        if (fkCheck.isNotEmpty) {
          throw RestoreException('Foreign key constraint failed after restore: $fkCheck');
        }
      } catch (e) {
        await txn.execute('PRAGMA foreign_keys = ON');
        rethrow;
      }
    });

    // Restore photo attachments if present in payload
    if (payload.attachments != null && payload.attachments!.isNotEmpty) {
      await AttachmentService.restoreAttachmentsFromBackup(payload.attachments!);
    }
  }

  /// Restores from a file with safety validation
  Future<void> restoreFromFile(File file) async {
    if (!await file.exists()) {
      throw const RestoreException('Backup file does not exist');
    }

    final content = await file.readAsString();
    final payload = validateBackupData(content);
    await restoreFromPayload(payload);
  }
}
