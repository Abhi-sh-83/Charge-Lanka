import '../entities/charging_session_entity.dart';
import '../repositories/charging_repository.dart';

class StopSessionUseCase {
  final ChargingRepository repository;
  StopSessionUseCase(this.repository);
  Future<ChargingSessionEntity> call(String sessionId) =>
      repository.stopSession(sessionId);
}
