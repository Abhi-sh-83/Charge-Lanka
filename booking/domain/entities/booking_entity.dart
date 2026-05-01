import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String id;
  final String userId;
  final String listingId;
  final String packageId;
  final String status;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final double totalEstimate;
  final double platformFee;
  final double hostPayout;
  final bool qrVerified;
  final DateTime createdAt;
  final String? chargerTitle;
  final String? chargerAddress;
  final String? packageName;

  const BookingEntity({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.packageId,
    required this.status,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.totalEstimate,
    required this.platformFee,
    required this.hostPayout,
    this.qrVerified = false,
    required this.createdAt,
    this.chargerTitle,
    this.chargerAddress,
    this.packageName,
  });

  @override
  List<Object?> get props => [id, status, scheduledStart];
}
