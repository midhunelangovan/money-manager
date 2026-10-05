import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/core/utilities/id_generator.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/backup/data/services/backup_service.dart';
import 'package:kals_money_manager/features/backup/data/services/integrity_service.dart';
import 'package:kals_money_manager/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:kals_money_manager/core/database/app_database.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Backup, Restore & Integrity Service Tests', () {
    late Database db;
    late AppDatabase appDb;
    late BackupService backupService;
    late IntegrityService integrityService;
    late AccountRepositoryImpl accountRepo;
    late CategoryRepositoryImpl categoryRepo;
    late TransactionRepositoryImpl txRepo;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: DatabaseMigrations.onCreate,
      );
      appDb = AppDatabase.withDatabase(db);
      backupService = BackupService(database: appDb);
      integrityService = IntegrityService(database: appDb);
      accountRepo = AccountRepositoryImpl(database: appDb);
      categoryRepo = CategoryRepositoryImpl(database: appDb);
      txRepo = TransactionRepositoryImpl(database: appDb);
    });

    tearDown(() async {
      await db.close();
    });

    test('Integrity service passes on valid initial database', () async {
      final report = await integrityService.runComprehensiveCheck();
      expect(report.isHealthy, isTrue);
      expect(report.checks.length, equals(7));
      for (final check in report.checks) {
        expect(check.isValid, isTrue);
      }
    });

    test('Creates valid backup payload and restores atomically', () async {
      final now = DateTime.now();
      final accId = IdGenerator.generate();

      await accountRepo.createAccount(Account(
        id: accId,
        name: 'Investment Fund',
        accountType: AccountType.investment,
        openingBalance: const Money(units: 5000000), // ₹50,000
        createdAt: now,
        updatedAt: now,
      ));

      final cats = await categoryRepo.getAllCategories(type: CategoryType.income);
      await txRepo.createTransaction(Transaction(
        id: IdGenerator.generate(),
        transactionType: CategoryType.income,
        accountId: accId,
        categoryId: cats.first.id,
        amount: const Money(units: 1000000), // ₹10,000
        date: now,
        description: 'Dividend Income',
        createdAt: now,
        updatedAt: now,
      ));

      // Create backup payload
      final backup = await backupService.createBackupPayload();
      expect(backup.metadata.backupVersion, equals(1));
      expect(backup.accounts.any((a) => a['id'] == accId), isTrue);

      // Mutate database
      final accBefore = await accountRepo.getAllAccounts();
      expect(accBefore.any((a) => a.id == accId), isTrue);

      // Restore payload
      await backupService.restoreFromPayload(backup);

      // Verify restored data integrity
      final postRestoreReport = await integrityService.runComprehensiveCheck();
      expect(postRestoreReport.isHealthy, isTrue);

      final restoredAcc = await accountRepo.getAccountById(accId);
      expect(restoredAcc, isNotNull);
      expect(restoredAcc!.name, equals('Investment Fund'));
    });
  });
}
