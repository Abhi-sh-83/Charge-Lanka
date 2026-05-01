import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDatasource _remoteDatasource;
  WalletRepositoryImpl(this._remoteDatasource);

  @override
  Future<WalletEntity> getWallet() => _remoteDatasource.getWallet();

  @override
  Future<WalletEntity> topUp(double amount) => _remoteDatasource.topUp(amount);

  @override
  Future<WalletEntity> withdraw(double amount) =>
      _remoteDatasource.withdraw(amount);

  @override
  Future<List<TransactionEntity>> getTransactions() =>
      _remoteDatasource.getTransactions();

  @override
  Future<void> saveBankDetails({
    required String bankName,
    required String accountHolder,
    required String accountNumber,
    required String branch,
  }) {
    return _remoteDatasource.saveBankDetails(
      bankName: bankName,
      accountHolder: accountHolder,
      accountNumber: accountNumber,
      branch: branch,
    );
  }
}
