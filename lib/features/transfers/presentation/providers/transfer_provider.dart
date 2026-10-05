import 'package:flutter/foundation.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';

class TransferProvider extends ChangeNotifier {
  final TransferRepository repository;

  TransferProvider({required this.repository});

  List<Transfer> _transfers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Transfer> get transfers => _transfers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTransfers({String? accountId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transfers = await repository.getAllTransfers(accountId: accountId);
    } catch (e) {
      _errorMessage = 'Unable to load transfers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTransfer(Transfer transfer) async {
    try {
      await repository.createTransfer(transfer);
      await loadTransfers();
    } catch (e) {
      _errorMessage = 'Unable to create transfer: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransfer(Transfer transfer) async {
    try {
      await repository.updateTransfer(transfer);
      await loadTransfers();
    } catch (e) {
      _errorMessage = 'Unable to update transfer: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransfer(String id) async {
    try {
      await repository.deleteTransfer(id);
      await loadTransfers();
    } catch (e) {
      _errorMessage = 'Unable to delete transfer: $e';
      notifyListeners();
      rethrow;
    }
  }
}
