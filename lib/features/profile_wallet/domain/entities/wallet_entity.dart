import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final String currency;

  const WalletEntity({
    required this.id,
    required this.userId,
    required this.balance,
    this.currency = 'LKR',
  });

  @override
  List<Object?> get props => [id, balance];
}

class TransactionEntity extends Equatable {
  final String id;
  final String type; // TOP_UP, CHARGE_PAYMENT, HOST_PAYOUT, REFUND, COMMISSION
  final double amount;
  final double platformFee;
  final String status;
  final String? description;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    this.platformFee = 0,
    required this.status,
    this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, amount];
}
