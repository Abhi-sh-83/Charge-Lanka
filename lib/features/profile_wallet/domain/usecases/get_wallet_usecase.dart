import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletUseCase {
  final WalletRepository repository;
  GetWalletUseCase(this.repository);
  Future<WalletEntity> call() => repository.getWallet();
}
