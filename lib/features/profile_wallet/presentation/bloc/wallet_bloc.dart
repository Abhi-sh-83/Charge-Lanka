import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/get_wallet_usecase.dart';
import '../../domain/usecases/top_up_usecase.dart';
import '../../domain/usecases/withdraw_usecase.dart';

// ──── Events ────
abstract class WalletEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadWallet extends WalletEvent {}

class TopUpWallet extends WalletEvent {
  final double amount;
  TopUpWallet(this.amount);
  @override
  List<Object?> get props => [amount];
}

class WithdrawFromWallet extends WalletEvent {
  final double amount;
  WithdrawFromWallet(this.amount);
  @override
  List<Object?> get props => [amount];
}

// ──── States ────
abstract class WalletState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final WalletEntity wallet;
  final List<TransactionEntity> transactions;

  WalletLoaded({required this.wallet, this.transactions = const []});

  @override
  List<Object?> get props => [wallet, transactions];
}

class WalletError extends WalletState {
  final String message;
  WalletError(this.message);
  @override
  List<Object?> get props => [message];
}

// ──── BLoC ────
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletUseCase getWallet;
  final GetTransactionsUseCase getTransactions;
  final TopUpUseCase topUp;
  final WithdrawUseCase withdraw;

  WalletBloc({
    required this.getWallet,
    required this.getTransactions,
    required this.topUp,
    required this.withdraw,
  }) : super(WalletInitial()) {
    on<LoadWallet>(_onLoad);
    on<TopUpWallet>(_onTopUp);
    on<WithdrawFromWallet>(_onWithdraw);
  }

  Future<void> _onLoad(LoadWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    try {
      final wallet = await getWallet();
      final transactions = await getTransactions();
      emit(WalletLoaded(wallet: wallet, transactions: transactions));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _onTopUp(TopUpWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    try {
      await topUp(event.amount);
      final wallet = await getWallet();
      final transactions = await getTransactions();
      emit(WalletLoaded(wallet: wallet, transactions: transactions));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _onWithdraw(
    WithdrawFromWallet event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      await withdraw(event.amount);
      final wallet = await getWallet();
      final transactions = await getTransactions();
      emit(WalletLoaded(wallet: wallet, transactions: transactions));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }
}
