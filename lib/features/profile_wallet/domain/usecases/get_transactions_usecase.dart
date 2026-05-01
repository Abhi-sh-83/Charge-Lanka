import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetTransactionsUseCase {
  final WalletRepository repository;
  GetTransactionsUseCase(this.repository);

  Future<List<TransactionEntity>> call() => repository.getTransactions();
}
