import '../entities/charger_entity.dart';

abstract class DiscoveryRepository {
  Future<List<ChargerEntity>> getNearbyChargers({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String? connectorType,
  });

  Future<ChargerEntity> getChargerDetails(String id);

  Future<List<ChargerEntity>> searchChargers(String query);
}
