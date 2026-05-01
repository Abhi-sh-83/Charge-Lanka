import 'package:equatable/equatable.dart';

class ChargerEntity extends Equatable {
  final String id;
  final String hostId;
  final String title;
  final String? description;
  final String connectorType;
  final double powerOutputKw;
  final String address;
  final String city;
  final String province;
  final double latitude;
  final double longitude;
  final List<String> photos;
  final List<String> amenities;
  final bool isActive;
  final String qrCodeToken;
  final double avgRating;
  final int totalReviews;
  final double? distanceMeters;
  final List<ChargingPackageEntity> packages;

  const ChargerEntity({
    required this.id,
    required this.hostId,
    required this.title,
    this.description,
    required this.connectorType,
    required this.powerOutputKw,
    required this.address,
    required this.city,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.photos = const [],
    this.amenities = const [],
    this.isActive = true,
    required this.qrCodeToken,
    this.avgRating = 0,
    this.totalReviews = 0,
    this.distanceMeters,
    this.packages = const [],
  });

  @override
  List<Object?> get props => [id, title, latitude, longitude];
}

class ChargingPackageEntity extends Equatable {
  final String id;
  final String listingId;
  final String name;
  final String tier; // STANDARD, EXPRESS, OVERNIGHT
  final double pricePerKwh;
  final double sessionFee;
  final int? maxDurationMins;
  final String? description;
  final bool isActive;

  const ChargingPackageEntity({
    required this.id,
    required this.listingId,
    required this.name,
    required this.tier,
    required this.pricePerKwh,
    this.sessionFee = 0,
    this.maxDurationMins,
    this.description,
    this.isActive = true,
  });

  String get tierLabel {
    switch (tier) {
      case 'STANDARD':
        return 'Standard Charge';
      case 'EXPRESS':
        return 'Express Charge';
      case 'OVERNIGHT':
        return 'Overnight Park & Charge';
      default:
        return tier;
    }
  }

  @override
  List<Object?> get props => [id, name, tier, pricePerKwh];
}
