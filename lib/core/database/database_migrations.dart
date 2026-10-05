import 'package:sqflite/sqflite.dart';
import '../utilities/id_generator.dart';
import 'tables.dart';

class DatabaseMigrations {
  static Future<void> onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Accounts Table
    batch.execute('''
      CREATE TABLE ${DbTables.accounts} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.name} TEXT NOT NULL,
        ${DbColumns.accountType} TEXT NOT NULL,
        ${DbColumns.openingBalance} INTEGER NOT NULL DEFAULT 0,
        ${DbColumns.currency} TEXT NOT NULL DEFAULT 'INR',
        ${DbColumns.icon} TEXT,
        ${DbColumns.color} INTEGER,
        ${DbColumns.isArchived} INTEGER NOT NULL DEFAULT 0,
        ${DbColumns.createdAt} INTEGER NOT NULL,
        ${DbColumns.updatedAt} INTEGER NOT NULL
      )
    ''');

    // 2. Categories Table
    batch.execute('''
      CREATE TABLE ${DbTables.categories} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.name} TEXT NOT NULL,
        ${DbColumns.type} TEXT NOT NULL,
        ${DbColumns.parentId} TEXT,
        ${DbColumns.icon} TEXT,
        ${DbColumns.color} INTEGER,
        ${DbColumns.sortOrder} INTEGER NOT NULL DEFAULT 0,
        ${DbColumns.isArchived} INTEGER NOT NULL DEFAULT 0,
        ${DbColumns.createdAt} INTEGER NOT NULL,
        ${DbColumns.updatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbColumns.parentId}) REFERENCES ${DbTables.categories} (${DbColumns.id}) ON DELETE SET NULL
      )
    ''');

    // 3. Recurring Transactions Table
    batch.execute('''
      CREATE TABLE ${DbTables.recurringTransactions} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.transactionType} TEXT NOT NULL,
        ${DbColumns.accountId} TEXT NOT NULL,
        ${DbColumns.categoryId} TEXT NOT NULL,
        ${DbColumns.amount} INTEGER NOT NULL,
        ${DbColumns.description} TEXT NOT NULL,
        ${DbColumns.frequency} TEXT NOT NULL,
        ${DbColumns.interval} INTEGER NOT NULL DEFAULT 1,
        ${DbColumns.startDate} INTEGER NOT NULL,
        ${DbColumns.endDate} INTEGER,
        ${DbColumns.nextExecutionDate} INTEGER NOT NULL,
        ${DbColumns.isActive} INTEGER NOT NULL DEFAULT 1,
        ${DbColumns.createdAt} INTEGER NOT NULL,
        ${DbColumns.updatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbColumns.accountId}) REFERENCES ${DbTables.accounts} (${DbColumns.id}) ON DELETE RESTRICT,
        FOREIGN KEY (${DbColumns.categoryId}) REFERENCES ${DbTables.categories} (${DbColumns.id}) ON DELETE RESTRICT
      )
    ''');

    // 4. Transactions Table
    batch.execute('''
      CREATE TABLE ${DbTables.transactions} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.transactionType} TEXT NOT NULL,
        ${DbColumns.accountId} TEXT NOT NULL,
        ${DbColumns.categoryId} TEXT NOT NULL,
        ${DbColumns.amount} INTEGER NOT NULL,
        ${DbColumns.date} INTEGER NOT NULL,
        ${DbColumns.description} TEXT NOT NULL,
        ${DbColumns.notes} TEXT,
        ${DbColumns.receiptPath} TEXT,
        ${DbColumns.recurringTransactionId} TEXT,
        ${DbColumns.createdAt} INTEGER NOT NULL,
        ${DbColumns.updatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbColumns.accountId}) REFERENCES ${DbTables.accounts} (${DbColumns.id}) ON DELETE RESTRICT,
        FOREIGN KEY (${DbColumns.categoryId}) REFERENCES ${DbTables.categories} (${DbColumns.id}) ON DELETE RESTRICT,
        FOREIGN KEY (${DbColumns.recurringTransactionId}) REFERENCES ${DbTables.recurringTransactions} (${DbColumns.id}) ON DELETE SET NULL
      )
    ''');

    // 5. Transfers Table
    batch.execute('''
      CREATE TABLE ${DbTables.transfers} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.fromAccountId} TEXT NOT NULL,
        ${DbColumns.toAccountId} TEXT NOT NULL,
        ${DbColumns.amount} INTEGER NOT NULL,
        ${DbColumns.date} INTEGER NOT NULL,
        ${DbColumns.description} TEXT NOT NULL,
        ${DbColumns.receiptPath} TEXT,
        ${DbColumns.createdAt} INTEGER NOT NULL,
        ${DbColumns.updatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbColumns.fromAccountId}) REFERENCES ${DbTables.accounts} (${DbColumns.id}) ON DELETE RESTRICT,
        FOREIGN KEY (${DbColumns.toAccountId}) REFERENCES ${DbTables.accounts} (${DbColumns.id}) ON DELETE RESTRICT
      )
    ''');

    // 6. Transaction Audit Logs Table (Modification history tracking)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.transactionAuditLogs} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.transactionId} TEXT NOT NULL,
        ${DbColumns.operation} TEXT NOT NULL,
        ${DbColumns.amount} INTEGER NOT NULL,
        ${DbColumns.accountId} TEXT NOT NULL,
        ${DbColumns.categoryId} TEXT,
        ${DbColumns.date} INTEGER NOT NULL,
        ${DbColumns.description} TEXT NOT NULL,
        ${DbColumns.notes} TEXT,
        ${DbColumns.changedAt} INTEGER NOT NULL
      )
    ''');

    // 7. Reminders Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.reminders} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.name} TEXT NOT NULL,
        ${DbColumns.frequency} TEXT NOT NULL,
        ${DbColumns.date} TEXT NOT NULL,
        ${DbColumns.time} TEXT NOT NULL,
        ${DbColumns.comment} TEXT,
        ${DbColumns.isEnabled} INTEGER NOT NULL DEFAULT 1,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL
      )
    ''');

    // 8. App Settings Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Performance Indexes
    batch.execute('CREATE INDEX idx_transactions_date ON ${DbTables.transactions} (${DbColumns.date} DESC)');
    batch.execute('CREATE INDEX idx_transactions_account ON ${DbTables.transactions} (${DbColumns.accountId})');
    batch.execute('CREATE INDEX idx_transactions_category ON ${DbTables.transactions} (${DbColumns.categoryId})');
    batch.execute('CREATE INDEX idx_transactions_type ON ${DbTables.transactions} (${DbColumns.transactionType})');
    batch.execute('CREATE INDEX idx_transfers_date ON ${DbTables.transfers} (${DbColumns.date} DESC)');
    batch.execute('CREATE INDEX idx_transfers_from_account ON ${DbTables.transfers} (${DbColumns.fromAccountId})');
    batch.execute('CREATE INDEX idx_transfers_to_account ON ${DbTables.transfers} (${DbColumns.toAccountId})');
    batch.execute('CREATE INDEX idx_recurring_next_date ON ${DbTables.recurringTransactions} (${DbColumns.nextExecutionDate}, ${DbColumns.isActive})');
    batch.execute('CREATE INDEX idx_categories_parent ON ${DbTables.categories} (${DbColumns.parentId})');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_audit_logs_tx ON ${DbTables.transactionAuditLogs} (${DbColumns.transactionId}, ${DbColumns.changedAt} ASC)');

    await batch.commit(noResult: true);

    // Seed default initial categories and accounts
    await _seedInitialData(db);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic for future schema versions
    // Strictly preserve user data
  }

  /// Safe reconciliation for legacy transactions/recurring records with missing/orphaned category entities
  static Future<void> reconcileLegacyCategories(Database db) async {
    try {
      final orphanedTx = await db.rawQuery('''
        SELECT t.${DbColumns.id}, t.${DbColumns.categoryId}, t.${DbColumns.transactionType}, t.${DbColumns.description}, t.${DbColumns.notes}
        FROM ${DbTables.transactions} t
        LEFT JOIN ${DbTables.categories} c ON t.${DbColumns.categoryId} = c.${DbColumns.id}
        WHERE c.${DbColumns.id} IS NULL
      ''');

      final orphanedRec = await db.rawQuery('''
        SELECT r.${DbColumns.id}, r.${DbColumns.categoryId}, r.${DbColumns.transactionType}, r.${DbColumns.description}
        FROM ${DbTables.recurringTransactions} r
        LEFT JOIN ${DbTables.categories} c ON r.${DbColumns.categoryId} = c.${DbColumns.id}
        WHERE c.${DbColumns.id} IS NULL
      ''');

      if (orphanedTx.isEmpty && orphanedRec.isEmpty) return;

      final now = DateTime.now().millisecondsSinceEpoch;

      final existingCategories = await db.query(DbTables.categories);
      final categoryMap = <String, String>{};
      for (final cat in existingCategories) {
        final name = (cat[DbColumns.name] as String).trim().toLowerCase();
        final type = (cat[DbColumns.type] as String).trim().toUpperCase();
        categoryMap['$name|$type'] = cat[DbColumns.id] as String;
      }

      final batch = db.batch();

      for (final tx in orphanedTx) {
        final txId = tx[DbColumns.id] as String;
        final rawCatId = tx[DbColumns.categoryId] as String?;
        final rawType = tx[DbColumns.transactionType] as String? ?? 'EXPENSE';
        final typeStr = rawType.toUpperCase() == 'INCOME' ? 'INCOME' : 'EXPENSE';

        String catName = 'Other';
        final desc = (tx[DbColumns.description] as String? ?? '').trim();
        final notes = (tx[DbColumns.notes] as String? ?? '').trim();

        if (desc.isNotEmpty && desc.toLowerCase() != 'imported' && desc.toLowerCase() != 'transaction') {
          catName = desc;
        } else if (notes.isNotEmpty) {
          catName = notes;
        } else {
          catName = typeStr == 'INCOME' ? 'Other Income' : 'Other Expense';
        }

        final key = '${catName.toLowerCase()}|$typeStr';
        String targetCatId;

        if (categoryMap.containsKey(key)) {
          targetCatId = categoryMap[key]!;
        } else {
          targetCatId = (rawCatId != null && rawCatId.trim().isNotEmpty) ? rawCatId.trim() : IdGenerator.generate();
          categoryMap[key] = targetCatId;

          batch.insert(DbTables.categories, {
            DbColumns.id: targetCatId,
            DbColumns.name: catName,
            DbColumns.type: typeStr,
            DbColumns.parentId: null,
            DbColumns.icon: typeStr == 'INCOME' ? 'payments_outlined' : 'category_outlined',
            DbColumns.color: typeStr == 'INCOME' ? 0xFF059669 : 0xFF2563EB,
            DbColumns.sortOrder: 99,
            DbColumns.isArchived: 0,
            DbColumns.createdAt: now,
            DbColumns.updatedAt: now,
          });
        }

        batch.update(
          DbTables.transactions,
          {DbColumns.categoryId: targetCatId},
          where: '${DbColumns.id} = ?',
          whereArgs: [txId],
        );
      }

      for (final rec in orphanedRec) {
        final recId = rec[DbColumns.id] as String;
        final rawCatId = rec[DbColumns.categoryId] as String?;
        final rawType = rec[DbColumns.transactionType] as String? ?? 'EXPENSE';
        final typeStr = rawType.toUpperCase() == 'INCOME' ? 'INCOME' : 'EXPENSE';
        final desc = (rec[DbColumns.description] as String? ?? '').trim();
        final catName = desc.isNotEmpty ? desc : (typeStr == 'INCOME' ? 'Other Income' : 'Other Expense');
        final key = '${catName.toLowerCase()}|$typeStr';
        String targetCatId;
        if (categoryMap.containsKey(key)) {
          targetCatId = categoryMap[key]!;
        } else {
          targetCatId = (rawCatId != null && rawCatId.trim().isNotEmpty) ? rawCatId.trim() : IdGenerator.generate();
          categoryMap[key] = targetCatId;
          batch.insert(DbTables.categories, {
            DbColumns.id: targetCatId,
            DbColumns.name: catName,
            DbColumns.type: typeStr,
            DbColumns.parentId: null,
            DbColumns.icon: typeStr == 'INCOME' ? 'payments_rounded' : 'category_rounded',
            DbColumns.color: typeStr == 'INCOME' ? 0xFF059669 : 0xFF2563EB,
            DbColumns.sortOrder: 99,
            DbColumns.isArchived: 0,
            DbColumns.createdAt: now,
            DbColumns.updatedAt: now,
          });
        }
        batch.update(
          DbTables.recurringTransactions,
          {DbColumns.categoryId: targetCatId},
          where: '${DbColumns.id} = ?',
          whereArgs: [recId],
        );
      }

      // Reconcile default category icons if using outdated default names without overriding user customization
      batch.update(
        DbTables.categories,
        {DbColumns.icon: 'restaurant_rounded'},
        where: 'LOWER(${DbColumns.name}) = ? AND (${DbColumns.icon} = ? OR ${DbColumns.icon} = ? OR ${DbColumns.icon} = ?)',
        whereArgs: ['food & dining', 'restaurant_outlined', 'fastfood_rounded', 'food'],
      );
      batch.update(
        DbTables.categories,
        {DbColumns.icon: 'shopping_basket_rounded'},
        where: 'LOWER(${DbColumns.name}) = ? AND (${DbColumns.icon} = ? OR ${DbColumns.icon} = ? OR ${DbColumns.icon} = ?)',
        whereArgs: ['groceries', 'shopping_cart_outlined', 'shopping_cart_rounded', 'shopping_cart'],
      );
      batch.update(
        DbTables.categories,
        {DbColumns.icon: 'directions_car_rounded'},
        where: 'LOWER(${DbColumns.name}) = ? AND (${DbColumns.icon} = ? OR ${DbColumns.icon} = ?)',
        whereArgs: ['transportation', 'directions_car_outlined', 'car'],
      );
      batch.update(
        DbTables.categories,
        {DbColumns.icon: 'receipt_long_rounded'},
        where: 'LOWER(${DbColumns.name}) = ? AND (${DbColumns.icon} = ? OR ${DbColumns.icon} = ?)',
        whereArgs: ['bills & utilities', 'receipt_long_outlined', 'receipt_rounded'],
      );
      batch.update(
        DbTables.categories,
        {DbColumns.icon: 'medical_services_rounded'},
        where: 'LOWER(${DbColumns.name}) = ? AND (${DbColumns.icon} = ? OR ${DbColumns.icon} = ?)',
        whereArgs: ['healthcare', 'medical_services_outlined', 'health'],
      );

      await batch.commit(noResult: true);
    } catch (_) {}
  }

  static Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();

    // Default Expense Categories with semantically relatable vector icons
    final defaultExpenseCategories = [
      {'name': 'Food & Dining', 'icon': 'restaurant_rounded', 'color': 0xFFEA580C},
      {'name': 'Groceries', 'icon': 'shopping_basket_rounded', 'color': 0xFF059669},
      {'name': 'Transportation', 'icon': 'directions_car_rounded', 'color': 0xFF0284C7},
      {'name': 'Housing & Rent', 'icon': 'home_rounded', 'color': 0xFF7C3AED},
      {'name': 'Bills & Utilities', 'icon': 'receipt_long_rounded', 'color': 0xFFD97706},
      {'name': 'Healthcare', 'icon': 'medical_services_rounded', 'color': 0xFFE11D48},
      {'name': 'Entertainment', 'icon': 'movie_rounded', 'color': 0xFFDB2777},
      {'name': 'Shopping', 'icon': 'shopping_bag_rounded', 'color': 0xFF4F46E5},
      {'name': 'Education', 'icon': 'school_rounded', 'color': 0xFF0891B2},
      {'name': 'Other Expense', 'icon': 'category_rounded', 'color': 0xFF475569},
    ];

    int order = 0;
    for (final cat in defaultExpenseCategories) {
      batch.insert(DbTables.categories, {
        DbColumns.id: IdGenerator.generate(),
        DbColumns.name: cat['name'] as String,
        DbColumns.type: 'EXPENSE',
        DbColumns.parentId: null,
        DbColumns.icon: cat['icon'] as String,
        DbColumns.color: cat['color'] as int,
        DbColumns.sortOrder: order++,
        DbColumns.isArchived: 0,
        DbColumns.createdAt: now,
        DbColumns.updatedAt: now,
      });
    }

    // Default Income Categories with semantically relatable vector icons
    final defaultIncomeCategories = [
      {'name': 'Salary', 'icon': 'payments_rounded', 'color': 0xFF059669},
      {'name': 'Business / Freelance', 'icon': 'business_center_rounded', 'color': 0xFF0F766E},
      {'name': 'Investment & Dividends', 'icon': 'trending_up_rounded', 'color': 0xFF2563EB},
      {'name': 'Gifts / Grants', 'icon': 'card_giftcard_rounded', 'color': 0xFFDB2777},
      {'name': 'Other Income', 'icon': 'savings_rounded', 'color': 0xFF475569},
    ];

    order = 0;
    for (final cat in defaultIncomeCategories) {
      batch.insert(DbTables.categories, {
        DbColumns.id: IdGenerator.generate(),
        DbColumns.name: cat['name'] as String,
        DbColumns.type: 'INCOME',
        DbColumns.parentId: null,
        DbColumns.icon: cat['icon'] as String,
        DbColumns.color: cat['color'] as int,
        DbColumns.sortOrder: order++,
        DbColumns.isArchived: 0,
        DbColumns.createdAt: now,
        DbColumns.updatedAt: now,
      });
    }

    await batch.commit(noResult: true);
  }
}
