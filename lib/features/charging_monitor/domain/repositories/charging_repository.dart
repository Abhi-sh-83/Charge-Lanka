import '../entities/charging_session_entity.dart';

abstract class ChargingRepository {
  Future<ChargingSessionEntity> startSession(String bookingId);
  Future<ChargingSessionEntity> stopSession(String sessionId);
  Stream<ChargingSessionEntity> watchSession(String sessionId);
}
