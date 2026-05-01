import '../repositories/wallet_repository.dart';

class SaveBankDetailsUseCase {
  final WalletRepository repository;
  SaveBankDetailsUseCase(this.repository);

  Future<void> call({
    required String bankName,
    required String accountHolder,
    required String accountNumber,
    required String branch,
  }) {
    return repository.saveBankDetails(
      bankName: bankName,
      accountHolder: accountHolder,
      accountNumber: accountNumber,
      branch: branch,
    );
  }
}
