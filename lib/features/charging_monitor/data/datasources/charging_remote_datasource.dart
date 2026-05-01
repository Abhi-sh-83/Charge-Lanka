import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/charging_session_entity.dart';

class ChargingRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  ChargingRemoteDatasource(this._firestore, this._auth);

  Future<ChargingSessionEntity> startSession(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to start charging.');
    }

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found.');
    }
    final booking = bookingDoc.data()!;
    final status = booking['status'] as String? ?? 'PENDING';
    final qrVerified = booking['qr_verified'] as bool? ?? false;
    if (!(status == 'CONFIRMED' || qrVerified)) {
      throw Exception('Booking must be QR verified before starting session.');
    }

    final sessionRef = await _firestore.collection('sessions').add({
      'booking_id': bookingId,
      'user_id': user.uid,
      'status': 'IN_PROGRESS',
      'started_at': FieldValue.serverTimestamp(),
      'ended_at': null,
      'energy_delivered_kwh': 0.0,
      'current_power_kw': 0.0,
      'battery_start_pct': null,
      'battery_end_pct': null,
      'cost_accrued': 0.0,
    });

    await bookingRef.update({
      'status': 'IN_PROGRESS',
      'active_session_id': sessionRef.id,
    });

    final created = await sessionRef.get();
    return _parseSession(
      docId: created.id,
      json: created.data() ?? <String, dynamic>{},
    );
  }

  Future<ChargingSessionEntity> stopSession(String sessionId) async {
    final sessionRef = _firestore.collection('sessions').doc(sessionId);
    final sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
      throw Exception('Charging session not found.');
    }
    final sessionData = sessionDoc.data()!;

    final bookingId = sessionData['booking_id'] as String? ?? '';
    await sessionRef.update({
      'status': 'COMPLETED',
      'ended_at': FieldValue.serverTimestamp(),
      'current_power_kw': 0.0,
    });

    if (bookingId.isNotEmpty) {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'COMPLETED',
      });
    }

    final updated = await sessionRef.get();
    return _parseSession(
      docId: updated.id,
      json: updated.data() ?? <String, dynamic>{},
    );
  }

  ChargingSessionEntity _parseSession({
    required String docId,
    required Map<String, dynamic> json,
  }) {
    return ChargingSessionEntity(
      id: docId,
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'IN_PROGRESS',
      startedAt: (json['started_at'] as Timestamp?)?.toDate(),
      endedAt: (json['ended_at'] as Timestamp?)?.toDate(),
      energyDeliveredKwh:
          (json['energy_delivered_kwh'] as num?)?.toDouble() ?? 0,
      currentPowerKw: (json['current_power_kw'] as num?)?.toDouble() ?? 0,
      batteryStartPct: (json['battery_start_pct'] as num?)?.toDouble(),
      batteryEndPct: (json['battery_end_pct'] as num?)?.toDouble(),
      costAccrued: (json['cost_accrued'] as num?)?.toDouble() ?? 0,
    );
  }
}
