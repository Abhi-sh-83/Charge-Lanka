import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class TopUpUseCase {
  final WalletRepository repository;
  TopUpUseCase(this.repository);
  Future<WalletEntity> call(double amount) => repository.topUp(amount);
}
