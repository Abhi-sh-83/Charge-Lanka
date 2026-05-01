import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/charging_session_entity.dart';
import '../../domain/repositories/charging_repository.dart';
import '../datasources/charging_remote_datasource.dart';

class ChargingRepositoryImpl implements ChargingRepository {
  final ChargingRemoteDatasource _remoteDatasource;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChargingRepositoryImpl(this._remoteDatasource);

  @override
  Future<ChargingSessionEntity> startSession(String bookingId) {
    return _remoteDatasource.startSession(bookingId);
  }

  @override
  Future<ChargingSessionEntity> stopSession(String sessionId) {
    return _remoteDatasource.stopSession(sessionId);
  }

  @override
  Stream<ChargingSessionEntity> watchSession(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data() ?? <String, dynamic>{};
      return ChargingSessionEntity(
        id: sessionId,
        bookingId: data['booking_id'] as String? ?? '',
        userId: data['user_id'] as String? ?? '',
        status: data['status'] as String? ?? 'IN_PROGRESS',
        startedAt: (data['started_at'] as Timestamp?)?.toDate(),
        endedAt: (data['ended_at'] as Timestamp?)?.toDate(),
        energyDeliveredKwh:
            (data['energy_delivered_kwh'] as num?)?.toDouble() ?? 0,
        currentPowerKw: (data['current_power_kw'] as num?)?.toDouble() ?? 0,
        batteryStartPct: (data['battery_start_pct'] as num?)?.toDouble(),
        batteryEndPct: (data['battery_end_pct'] as num?)?.toDouble(),
        costAccrued: (data['cost_accrued'] as num?)?.toDouble() ?? 0,
      );
    });
  }
}
