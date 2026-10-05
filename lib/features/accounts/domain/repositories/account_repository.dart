import '../entities/account.dart';

abstract class AccountRepository {
  Future<List<Account>> getAllAccounts({bool includeArchived = false});
  Future<Account?> getAccountById(String id);
  Future<List<AccountWithBalance>> getAccountsWithBalances({bool includeArchived = false});
  Future<AccountWithBalance?> getAccountWithBalance(String id);
  Future<void> createAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> archiveAccount(String id, bool isArchived);
  Future<int> getTransactionCountForAccount(String accountId);
}
