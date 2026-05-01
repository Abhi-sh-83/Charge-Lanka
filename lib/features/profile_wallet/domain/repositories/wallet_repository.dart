import '../entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<WalletEntity> getWallet();
  Future<WalletEntity> topUp(double amount);
  Future<WalletEntity> withdraw(double amount);
  Future<List<TransactionEntity>> getTransactions();
  Future<void> saveBankDetails({
    required String bankName,
    required String accountHolder,
    required String accountNumber,
    required String branch,
  });
}
