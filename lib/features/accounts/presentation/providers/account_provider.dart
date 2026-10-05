import 'package:flutter/foundation.dart';
import '../../../../core/utilities/money.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

class AccountProvider extends ChangeNotifier {
  final AccountRepository repository;

  AccountProvider({required this.repository});

  List<AccountWithBalance> _accountsWithBalances = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AccountWithBalance> get accountsWithBalances => _accountsWithBalances;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Money get totalBalance {
    int totalUnits = 0;
    for (final acc in _accountsWithBalances) {
      if (!acc.account.isArchived) {
        totalUnits += acc.calculatedBalance.units;
      }
    }
    return Money(units: totalUnits);
  }

  Future<void> loadAccounts({bool includeArchived = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _accountsWithBalances = await repository.getAccountsWithBalances(
        includeArchived: includeArchived,
      );
    } catch (e) {
      _errorMessage = 'Unable to load accounts. Please check your data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createAccount(Account account) async {
    try {
      await repository.createAccount(account);
      await loadAccounts();
    } catch (e) {
      _errorMessage = 'Unable to create account: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await repository.updateAccount(account);
      await loadAccounts();
    } catch (e) {
      _errorMessage = 'Unable to update account: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleArchive(String accountId, bool isArchived) async {
    try {
      await repository.archiveAccount(accountId, isArchived);
      await loadAccounts(includeArchived: true);
    } catch (e) {
      _errorMessage = 'Unable to update archive status: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<AccountWithBalance?> getAccountWithBalance(String accountId) async {
    return repository.getAccountWithBalance(accountId);
  }

  /// Soft deletes / deactivates account.
  /// Preserves all historical transactions and transfers.
  Future<void> deleteAccount(String accountId) async {
    try {
      await repository.archiveAccount(accountId, true);
      await loadAccounts();
    } catch (e) {
      _errorMessage = 'Unable to delete account: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Adjust account balance directly at the account level.
  /// Does NOT create any Income, Expense, or Transfer transaction.
  /// Income, Expense, Transfer totals and transaction history remain completely unchanged.
  Future<void> adjustAccountBalance({
    required String accountId,
    required Money newBalance,
  }) async {
    try {
      final currentWithBal = await repository.getAccountWithBalance(accountId);
      if (currentWithBal == null) return;

      final currentUnits = currentWithBal.calculatedBalance.units;
      final newUnits = newBalance.units;
      final diffUnits = newUnits - currentUnits;

      if (diffUnits == 0) return; // No adjustment needed

      final account = currentWithBal.account;
      final newOpeningUnits = account.openingBalance.units + diffUnits;
      final updatedAccount = account.copyWith(
        openingBalance: Money(units: newOpeningUnits, currencyCode: account.currency),
        updatedAt: DateTime.now(),
      );

      await repository.updateAccount(updatedAccount);
      await loadAccounts();
    } catch (e) {
      _errorMessage = 'Unable to adjust balance: $e';
      notifyListeners();
      rethrow;
    }
  }
}
