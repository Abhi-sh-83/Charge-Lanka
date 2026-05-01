import '../../domain/entities/charger_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_datasource.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDatasource _remoteDatasource;

  DiscoveryRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<ChargerEntity>> getNearbyChargers({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String? connectorType,
  }) {
    return _remoteDatasource.getNearbyChargers(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      connectorType: connectorType,
    );
  }

  @override
  Future<ChargerEntity> getChargerDetails(String id) {
    return _remoteDatasource.getChargerDetails(id);
  }

  @override
  Future<List<ChargerEntity>> searchChargers(String query) {
    return _remoteDatasource.searchChargers(query);
  }
}
