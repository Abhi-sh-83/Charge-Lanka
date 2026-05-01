import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/charger_model.dart';

class DiscoveryRemoteDatasource {
  final FirebaseFirestore _firestore;

  DiscoveryRemoteDatasource(this._firestore);

  Future<List<ChargerModel>> getNearbyChargers({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String? connectorType,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('chargers')
        .where('is_active', isEqualTo: true);

    if (connectorType != null) {
      query = query.where('connector_type', isEqualTo: connectorType);
    }

    final snapshot = await query.get();
    final chargers = <ChargerModel>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final distance = _distanceMeters(
        latitude,
        longitude,
        (data['latitude'] as num?)?.toDouble() ?? 0,
        (data['longitude'] as num?)?.toDouble() ?? 0,
      );

      if (distance > radiusMeters) continue;

      final charger = await _buildChargerFromDoc(doc, distanceMeters: distance);
      chargers.add(charger);
    }
    
    // Inject DUMMY Chargers for testing and showcase.
    if (!chargers.any((c) => c.id == 'dummy-1')) {
      chargers.addAll([
        ChargerModel(
          id: 'dummy-1',
          hostId: 'host-1',
          title: 'Colombo City Center EV Station',
          description: 'Ultra fast charging located at CCC parking level 2.',
          connectorType: 'TYPE_2',
          powerOutputKw: 22,
          address: 'CCC, Sir James Pieris Mawatha',
          city: 'Colombo 02',
          province: 'Western',
          latitude: 6.9157,
          longitude: 79.8505,
          photos: const [],
          amenities: const ['WiFi', 'Shopping', 'Restrooms'],
          isActive: true,
          qrCodeToken: 'CCC-EV-QR-TOKEN-12345',
          avgRating: 4.8,
          totalReviews: 120,
          distanceMeters: _distanceMeters(latitude, longitude, 6.9157, 79.8505),
          packages: [
            ChargingPackageModel(
              id: 'pkg-1',
              listingId: 'dummy-1',
              name: 'Fast Charge',
              tier: 'EXPRESS',
              pricePerKwh: 120,
              sessionFee: 0,
              isActive: true,
            ),
          ],
        ),
        ChargerModel(
          id: 'dummy-2',
          hostId: 'host-2',
          title: 'One Galle Face Premium Charging',
          description: 'Premium fast charging hub at OGF mall.',
          connectorType: 'CSS2',
          powerOutputKw: 50,
          address: 'One Galle Face, Colombo 01',
          city: 'Colombo 01',
          province: 'Western',
          latitude: 6.9272,
          longitude: 79.8444,
          photos: const [],
          amenities: const ['WiFi', 'Dining', 'Restrooms'],
          isActive: true,
          qrCodeToken: 'OGF-EV-QR-TOKEN-67890',
          avgRating: 4.9,
          totalReviews: 340,
          distanceMeters: _distanceMeters(latitude, longitude, 6.9272, 79.8444),
          packages: [
            ChargingPackageModel(
              id: 'pkg-2',
              listingId: 'dummy-2',
              name: 'Ultra Fast',
              tier: 'EXPRESS',
              pricePerKwh: 150,
              sessionFee: 0,
              isActive: true,
            ),
          ],
        ),
      ]);
    }

    chargers.sort((a, b) {
      final aDistance = a.distanceMeters ?? double.maxFinite;
      final bDistance = b.distanceMeters ?? double.maxFinite;
      return aDistance.compareTo(bDistance);
    });

    return chargers;
  }

  Future<ChargerModel> getChargerDetails(String id) async {
    final doc = await _firestore.collection('chargers').doc(id).get();
    if (!doc.exists) {
      throw Exception('Charger not found');
    }
    return _buildChargerFromDoc(doc);
  }

  Future<List<ChargerModel>> searchChargers(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final snapshot = await _firestore
        .collection('chargers')
        .where('is_active', isEqualTo: true)
        .get();

    final chargers = <ChargerModel>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final title = (data['title'] as String? ?? '').toLowerCase();
      final address = (data['address'] as String? ?? '').toLowerCase();
      final city = (data['city'] as String? ?? '').toLowerCase();
      if (normalizedQuery.isNotEmpty &&
          !title.contains(normalizedQuery) &&
          !address.contains(normalizedQuery) &&
          !city.contains(normalizedQuery)) {
        continue;
      }
      chargers.add(await _buildChargerFromDoc(doc));
    }
    return chargers;
  }

  Future<ChargerModel> _buildChargerFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    double? distanceMeters,
  }) async {
    final data = doc.data()!;
    final packagesSnapshot = await _firestore
        .collection('chargers')
        .doc(doc.id)
        .collection('packages')
        .where('is_active', isEqualTo: true)
        .get();

    return ChargerModel(
      id: doc.id,
      hostId: data['host_id'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled Charger',
      description: data['description'] as String?,
      connectorType: data['connector_type'] as String? ?? 'TYPE_2',
      powerOutputKw: (data['power_output_kw'] as num?)?.toDouble() ?? 0,
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      province: data['province'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      photos: List<String>.from(data['photos'] as List<dynamic>? ?? const []),
      amenities: List<String>.from(
        data['amenities'] as List<dynamic>? ?? const [],
      ),
      isActive: data['is_active'] as bool? ?? true,
      qrCodeToken: data['qr_code_token'] as String? ?? '',
      avgRating: (data['avg_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (data['total_reviews'] as num?)?.toInt() ?? 0,
      distanceMeters: distanceMeters,
      packages: packagesSnapshot.docs.map((pkgDoc) {
        final pkg = pkgDoc.data();
        return ChargingPackageModel(
          id: pkgDoc.id,
          listingId: doc.id,
          name: pkg['name'] as String? ?? 'Standard',
          tier: pkg['tier'] as String? ?? 'STANDARD',
          pricePerKwh: (pkg['price_per_kwh'] as num?)?.toDouble() ?? 0,
          sessionFee: (pkg['session_fee'] as num?)?.toDouble() ?? 0,
          maxDurationMins: (pkg['max_duration_mins'] as num?)?.toInt(),
          description: pkg['description'] as String?,
          isActive: pkg['is_active'] as bool? ?? true,
        );
      }).toList(),
    );
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degToRad(double degree) => degree * pi / 180;
}
