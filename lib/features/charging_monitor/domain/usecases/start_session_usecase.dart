import '../entities/charging_session_entity.dart';
import '../repositories/charging_repository.dart';

class StartSessionUseCase {
  final ChargingRepository repository;
  StartSessionUseCase(this.repository);
  Future<ChargingSessionEntity> call(String bookingId) =>
      repository.startSession(bookingId);
}
