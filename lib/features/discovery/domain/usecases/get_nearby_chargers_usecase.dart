import '../entities/charger_entity.dart';
import '../repositories/discovery_repository.dart';

class GetNearbyChargersUseCase {
  final DiscoveryRepository repository;
  GetNearbyChargersUseCase(this.repository);

  Future<List<ChargerEntity>> call({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String? connectorType,
  }) {
    return repository.getNearbyChargers(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      connectorType: connectorType,
    );
  }
}
