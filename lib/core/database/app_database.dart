import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import 'database_migrations.dart';
import 'tables.dart';

class AppDatabase {
  static AppDatabase? _instance;
  Database? _customDb;

  AppDatabase._();

  AppDatabase.withDatabase(Database db) {
    _customDb = db;
  }

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  static void setTestInstance(AppDatabase? testInstance) {
    _instance = testInstance;
  }

  /// Initialize sqflite for mobile / desktop
  static void initializeFfiIfRequired() {}

  static Database? _database;

  Future<Database> get database async {
    if (_customDb != null && _customDb!.isOpen) {
      return _customDb!;
    }
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      initializeFfiIfRequired();
      String dbPath;
      if (Platform.isAndroid || Platform.isIOS) {
        dbPath = await getDatabasesPath();
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        dbPath = docDir.path;
      }

      final fullPath = p.join(dbPath, AppConstants.databaseName);

      return await openDatabase(
        fullPath,
        version: AppConstants.databaseVersion,
        onConfigure: (db) async {
          // Strictly enforce foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: DatabaseMigrations.onCreate,
        onUpgrade: DatabaseMigrations.onUpgrade,
        onOpen: (db) async {
          // Ensure audit log table and indexes exist on existing app databases safely
          await db.execute('''
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
          await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_logs_tx ON ${DbTables.transactionAuditLogs} (${DbColumns.transactionId}, ${DbColumns.changedAt} ASC)');

          // Safely ensure receipt_path column exists in transactions and transfers
          try {
            await db.execute('ALTER TABLE ${DbTables.transactions} ADD COLUMN ${DbColumns.receiptPath} TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE ${DbTables.transfers} ADD COLUMN ${DbColumns.receiptPath} TEXT');
          } catch (_) {}

          // Safely ensure reminders table exists
          await db.execute('''
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

          // Reconcile and safely link any legacy unlinked category strings
          await DatabaseMigrations.reconcileLegacyCategories(db);
        },
      );
    } catch (e, stack) {
      throw DatabaseException('Failed to initialize database: $e', stack);
    }
  }

  /// Close and reset the database instance (e.g. before restore)
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// Get absolute path to the database file
  Future<String> getDatabasePath() async {
    initializeFfiIfRequired();
    if (Platform.isAndroid || Platform.isIOS) {
      final dbDir = await getDatabasesPath();
      return p.join(dbDir, AppConstants.databaseName);
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      return p.join(docDir.path, AppConstants.databaseName);
    }
  }

  /// Get persistent setting by key
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final res = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
      if (res.isNotEmpty) {
        return res.first['value'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Set persistent setting by key
  Future<void> setSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }
}

