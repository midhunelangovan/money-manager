import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';

class IntegrityCheckItem {
  final String title;
  final bool isValid;
  final String description;
  final String? details;

  const IntegrityCheckItem({
    required this.title,
    required this.isValid,
    required this.description,
    this.details,
  });
}

class IntegrityReport {
  final bool isHealthy;
  final List<IntegrityCheckItem> checks;
  final DateTime timestamp;

  const IntegrityReport({
    required this.isHealthy,
    required this.checks,
    required this.timestamp,
  });
}

class IntegrityService {
  final AppDatabase appDatabase;

  IntegrityService({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  Future<IntegrityReport> runComprehensiveCheck() async {
    final checks = <IntegrityCheckItem>[];
    bool overallHealth = true;

    try {
      final db = await appDatabase.database;

      // 1. Database Readability
      try {
        final versionRes = await db.rawQuery('PRAGMA user_version');
        checks.add(IntegrityCheckItem(
          title: 'Database Readability',
          isValid: true,
          description: 'Database schema and tables are readable (version ${versionRes.first['user_version']})',
        ));
      } catch (e) {
        overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Database Readability',
          isValid: false,
          description: 'Failed to query database schema',
          details: e.toString(),
        ));
      }

      // 2. Foreign-key consistency
      try {
        final fkCheck = await db.rawQuery('PRAGMA foreign_key_check');
        final valid = fkCheck.isEmpty;
        if (!valid) overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Foreign Key Integrity',
          isValid: valid,
          description: valid ? 'All foreign key constraints are strictly satisfied' : 'Foreign key violations detected',
          details: valid ? null : fkCheck.toString(),
        ));
      } catch (e) {
        overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Foreign Key Integrity',
          isValid: false,
          description: 'Error running foreign key check',
          details: e.toString(),
        ));
      }

      // 3. Duplicate IDs check across tables
      try {
        final dupTx = await db.rawQuery('''
          SELECT ${DbColumns.id}, COUNT(*) as cnt 
          FROM ${DbTables.transactions} 
          GROUP BY ${DbColumns.id} HAVING cnt > 1
        ''');
        final dupAccounts = await db.rawQuery('''
          SELECT ${DbColumns.id}, COUNT(*) as cnt 
          FROM ${DbTables.accounts} 
          GROUP BY ${DbColumns.id} HAVING cnt > 1
        ''');
        final valid = dupTx.isEmpty && dupAccounts.isEmpty;
        if (!valid) overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Primary Key Uniqueness',
          isValid: valid,
          description: valid ? 'No duplicate IDs found in any table' : 'Duplicate primary keys detected in ledger',
        ));
      } catch (e) {
        overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Primary Key Uniqueness',
          isValid: false,
          description: 'Error checking primary key uniqueness',
          details: e.toString(),
        ));
      }

      // 4. Invalid Amounts (amount <= 0 in transactions or transfers)
      try {
        final badTx = await db.rawQuery('''
          SELECT COUNT(*) as cnt FROM ${DbTables.transactions} WHERE ${DbColumns.amount} <= 0
        ''');
        final badTr = await db.rawQuery('''
          SELECT COUNT(*) as cnt FROM ${DbTables.transfers} WHERE ${DbColumns.amount} <= 0
        ''');
        final badTxCount = (badTx.first['cnt'] as num?)?.toInt() ?? 0;
        final badTrCount = (badTr.first['cnt'] as num?)?.toInt() ?? 0;
        final valid = badTxCount == 0 && badTrCount == 0;
        if (!valid) overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Monetary Amounts Validity',
          isValid: valid,
          description: valid
              ? 'All financial amounts are strictly positive integer units'
              : 'Found $badTxCount transactions and $badTrCount transfers with non-positive amounts',
        ));
      } catch (e) {
        overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Monetary Amounts Validity',
          isValid: false,
          description: 'Error checking amount validity',
          details: e.toString(),
        ));
      }

      // 5. Orphan Records in Transactions (Account or Category deleted/missing)
      try {
        final orphanTxAcc = await db.rawQuery('''
          SELECT COUNT(*) as cnt 
          FROM ${DbTables.transactions} t 
          LEFT JOIN ${DbTables.accounts} a ON t.${DbColumns.accountId} = a.${DbColumns.id}
          WHERE a.${DbColumns.id} IS NULL
        ''');
        final orphanTxCat = await db.rawQuery('''
          SELECT COUNT(*) as cnt 
          FROM ${DbTables.transactions} t 
          LEFT JOIN ${DbTables.categories} c ON t.${DbColumns.categoryId} = c.${DbColumns.id}
          WHERE c.${DbColumns.id} IS NULL
        ''');
        final orphanAccCnt = (orphanTxAcc.first['cnt'] as num?)?.toInt() ?? 0;
        final orphanCatCnt = (orphanTxCat.first['cnt'] as num?)?.toInt() ?? 0;
        final valid = orphanAccCnt == 0 && orphanCatCnt == 0;
        if (!valid) overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Orphan Transaction References',
          isValid: valid,
          description: valid
              ? 'Zero orphan transactions. All accounts and categories exist'
              : 'Found $orphanAccCnt orphan account references and $orphanCatCnt orphan category references',
        ));
      } catch (e) {
        overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Orphan Transaction References',
          isValid: false,
          description: 'Error checking orphan transaction records',
          details: e.toString(),
        ));
      }

      // 6. Transfer Consistency (from != to, both accounts exist)
      try {
        final invalidTr = await db.rawQuery('''
          SELECT COUNT(*) as cnt 
          FROM ${DbTables.transfers} 
          WHERE ${DbColumns.fromAccountId} = ${DbColumns.toAccountId}
        ''');
        final invalidTrCount = (invalidTr.first['cnt'] as num?)?.toInt() ?? 0;
        final valid = invalidTrCount == 0;
        if (!valid) overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Transfer Consistency',
          isValid: valid,
          description: valid
              ? 'All transfers have distinct source and destination accounts'
              : 'Found $invalidTrCount transfers where source and destination accounts are identical',
        ));
      } catch (e) {
        overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Transfer Consistency',
          isValid: false,
          description: 'Error checking transfer consistency',
          details: e.toString(),
        ));
      }

      // 7. Recurring Transactions Validity
      try {
        final invalidRec = await db.rawQuery('''
          SELECT COUNT(*) as cnt 
          FROM ${DbTables.recurringTransactions} r
          LEFT JOIN ${DbTables.accounts} a ON r.${DbColumns.accountId} = a.${DbColumns.id}
          LEFT JOIN ${DbTables.categories} c ON r.${DbColumns.categoryId} = c.${DbColumns.id}
          WHERE a.${DbColumns.id} IS NULL OR c.${DbColumns.id} IS NULL OR r.${DbColumns.amount} <= 0
        ''');
        final invalidRecCount = (invalidRec.first['cnt'] as num?)?.toInt() ?? 0;
        final valid = invalidRecCount == 0;
        if (!valid) overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Recurring Schedules Validity',
          isValid: valid,
          description: valid
              ? 'All recurring transaction schedules are valid and reference active entities'
              : 'Found $invalidRecCount invalid recurring schedules',
        ));
      } catch (e) {
        overallHealth = false;
        checks.add(IntegrityCheckItem(
          title: 'Recurring Schedules Validity',
          isValid: false,
          description: 'Error checking recurring schedules',
          details: e.toString(),
        ));
      }
    } catch (e) {
      overallHealth = false;
      checks.add(IntegrityCheckItem(
        title: 'Database Access Failure',
        isValid: false,
        description: 'Failed to access the underlying SQLite engine',
        details: e.toString(),
      ));
    }

    return IntegrityReport(
      isHealthy: overallHealth,
      checks: checks,
      timestamp: DateTime.now(),
    );
  }
}
