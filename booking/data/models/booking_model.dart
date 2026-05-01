import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.listingId,
    required super.packageId,
    required super.status,
    required super.scheduledStart,
    required super.scheduledEnd,
    required super.totalEstimate,
    required super.platformFee,
    required super.hostPayout,
    super.qrVerified,
    required super.createdAt,
    super.chargerTitle,
    super.chargerAddress,
    super.packageName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      listingId: json['listing_id'] as String,
      packageId: json['package_id'] as String,
      status: json['status'] as String,
      scheduledStart: DateTime.parse(json['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
      totalEstimate: (json['total_estimate'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      hostPayout: (json['host_payout'] as num).toDouble(),
      qrVerified: json['qr_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      chargerTitle: json['listing']?['title'] as String?,
      chargerAddress: json['listing']?['address'] as String?,
      packageName: json['package']?['name'] as String?,
    );
  }
}
