import 'package:equatable/equatable.dart';

class ChargingSessionEntity extends Equatable {
  final String id;
  final String bookingId;
  final String userId;
  final String status; // INITIALIZING, CHARGING, PAUSED, COMPLETED, FAULTED
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double energyDeliveredKwh;
  final double currentPowerKw;
  final double? batteryStartPct;
  final double? batteryEndPct;
  final double costAccrued;

  const ChargingSessionEntity({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.energyDeliveredKwh = 0,
    this.currentPowerKw = 0,
    this.batteryStartPct,
    this.batteryEndPct,
    this.costAccrued = 0,
  });

  Duration get elapsed {
    if (startedAt == null) return Duration.zero;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  @override
  List<Object?> get props => [id, status, energyDeliveredKwh, costAccrued];
}
