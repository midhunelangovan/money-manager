import '../entities/transfer.dart';

abstract class TransferRepository {
  Future<List<Transfer>> getAllTransfers({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });
  Future<Transfer?> getTransferById(String id);
  Future<void> createTransfer(Transfer transfer);
  Future<void> updateTransfer(Transfer transfer);
  Future<void> deleteTransfer(String id);
}
