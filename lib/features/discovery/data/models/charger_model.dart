import '../../domain/entities/charger_entity.dart';

class ChargerModel extends ChargerEntity {
  const ChargerModel({
    required super.id,
    required super.hostId,
    required super.title,
    super.description,
    required super.connectorType,
    required super.powerOutputKw,
    required super.address,
    required super.city,
    required super.province,
    required super.latitude,
    required super.longitude,
    super.photos,
    super.amenities,
    super.isActive,
    required super.qrCodeToken,
    super.avgRating,
    super.totalReviews,
    super.distanceMeters,
    super.packages,
  });

  factory ChargerModel.fromJson(Map<String, dynamic> json) {
    return ChargerModel(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      connectorType: json['connector_type'] as String,
      powerOutputKw: (json['power_output_kw'] as num).toDouble(),
      address: json['address'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photos: List<String>.from(json['photos'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      isActive: json['is_active'] as bool? ?? true,
      qrCodeToken: json['qr_code_token'] as String,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      packages:
          (json['charging_packages'] as List<dynamic>?)
              ?.map(
                (p) => ChargingPackageModel.fromJson(p as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'title': title,
      'description': description,
      'connector_type': connectorType,
      'power_output_kw': powerOutputKw,
      'address': address,
      'city': city,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'photos': photos,
      'amenities': amenities,
      'is_active': isActive,
      'qr_code_token': qrCodeToken,
      'avg_rating': avgRating,
      'total_reviews': totalReviews,
    };
  }
}

class ChargingPackageModel extends ChargingPackageEntity {
  const ChargingPackageModel({
    required super.id,
    required super.listingId,
    required super.name,
    required super.tier,
    required super.pricePerKwh,
    super.sessionFee,
    super.maxDurationMins,
    super.description,
    super.isActive,
  });

  factory ChargingPackageModel.fromJson(Map<String, dynamic> json) {
    return ChargingPackageModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      name: json['name'] as String,
      tier: json['tier'] as String,
      pricePerKwh: (json['price_per_kwh'] as num).toDouble(),
      sessionFee: (json['session_fee'] as num?)?.toDouble() ?? 0,
      maxDurationMins: json['max_duration_mins'] as int?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
