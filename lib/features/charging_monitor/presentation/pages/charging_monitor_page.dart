import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/charging_session_entity.dart';
import '../bloc/charging_bloc.dart';

class ChargingMonitorPage extends StatefulWidget {
  const ChargingMonitorPage({super.key});

  @override
  State<ChargingMonitorPage> createState() => _ChargingMonitorPageState();
}

class _ChargingMonitorPageState extends State<ChargingMonitorPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedBookingId;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  Timer? _simulationTimer;
  bool _isSimulating = false;
  double _localEnergy = 0.0;
  double _localPower = 0.0;
  double _localCost = 0.0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _preselectBooking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _preselectBooking() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: user.uid)
        .where('status', whereIn: ['CONFIRMED', 'PENDING'])
        .get();

    if (!mounted) return;
    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final aTime =
            (a.data()['created_at'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            (b.data()['created_at'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    if (docs.isNotEmpty) {
      setState(() {
        _selectedBookingId = docs.first.id;
      });
    }
  }

  void _startSimulation(ChargingSessionEntity session) {
    if (_isSimulating) return;
    _isSimulating = true;
    _localEnergy = session.energyDeliveredKwh;
    _localPower = 50.0; // Base 50kW fast charging
    _localCost = session.costAccrued;

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _localEnergy += 0.015; // Simulate 15 Wh per second
        _localPower = 48.0 + _random.nextDouble() * 4.0; // Jitter 48-52 kW
        _localCost += 2.5; // Simulate approx 2.5 LKR per second
      });
    });
  }

  void _stopSimulation(ChargingSessionEntity? session) {
    if (!_isSimulating) return;
    _isSimulating = false;
    _simulationTimer?.cancel();
    if (session != null) {
      setState(() {
        _localEnergy = session.energyDeliveredKwh;
        _localPower = session.currentPowerKw;
        _localCost = session.costAccrued;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to manage charging sessions.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR to verify booking',
            onPressed: () => context.push('/qr-scanner'),
          ),
        ],
      ),
      body: BlocConsumer<ChargingBloc, ChargingState>(
        listener: (context, state) {
          if (state is SessionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, blocState) {
          final isLoading = blocState is SessionLoading;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('sessions')
                .where('user_id', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs.toList() ?? [];
              docs.sort((a, b) {
                final aTime =
                    (a.data()['started_at'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final bTime =
                    (b.data()['started_at'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });
              final sessionDoc = docs.isNotEmpty ? docs.first : null;
              final activeSession = sessionDoc == null
                  ? null
                  : _mapSession(sessionDoc);
              final hasActiveSession =
                  activeSession != null && activeSession.status == 'IN_PROGRESS';

              // Synchronize simulation lifecycle with stream
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (hasActiveSession && !_isSimulating) {
                  _startSimulation(activeSession);
                } else if (!hasActiveSession && _isSimulating) {
                  _stopSimulation(activeSession);
                }
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSessionSummaryCard(activeSession, hasActiveSession),
                    const SizedBox(height: 16),
                    _buildSessionMetrics(hasActiveSession, activeSession),
                    const SizedBox(height: 16),
                    _buildBookingPicker(user.uid, hasActiveSession),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: hasActiveSession
                          ? OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      context.read<ChargingBloc>().add(
                                        StopSession(activeSession.id),
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.error),
                                    )
                                  : const Icon(Icons.stop_circle),
                              label: Text(
                                isLoading ? 'Stopping...' : 'Stop Charging',
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          : GlowingButton(
                              label: isLoading ? 'Starting...' : 'Start Charging',
                              icon: isLoading ? null : Icons.bolt,
                              isLoading: isLoading,
                              onPressed: (_selectedBookingId == null || isLoading)
                                  ? null
                                  : () {
                                      context.read<ChargingBloc>().add(
                                        StartSession(_selectedBookingId!),
                                      );
                                    },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionSummaryCard(
      ChargingSessionEntity? session, bool isCharging) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return VoltCard(
      showGlow: isCharging,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCharging ? 'Charging in progress' : 'No active session',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCharging
                          ? 'Session ID: ${session?.id}'
                          : 'Verify a booking QR to unlock the charger.',
                      style: TextStyle(color: secondaryText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isCharging)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.battery_charging_full_rounded,
                      color: AppColors.primaryLight,
                      size: 32,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.battery_unknown_rounded,
                  color: secondaryText,
                  size: 32,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMetrics(
      bool isCharging, ChargingSessionEntity? session) {
    final energy = isCharging ? _localEnergy : session?.energyDeliveredKwh ?? 0;
    final power = isCharging ? _localPower : session?.currentPowerKw ?? 0;
    final cost = isCharging ? _localCost : session?.costAccrued ?? 0;

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            icon: Icons.bolt,
            label: 'Energy',
            value: EnergyFormatter.formatKwh(energy),
            isActive: isCharging,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricCard(
            icon: Icons.speed,
            label: 'Power',
            value: EnergyFormatter.formatPower(power),
            isActive: isCharging,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricCard(
            icon: Icons.attach_money,
            label: 'Cost',
            value: CurrencyFormatter.format(cost),
            isActive: isCharging,
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final iconColor = isActive ? AppColors.primaryLight : AppColors.accent;

    return VoltCard(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: secondaryText)),
        ],
      ),
    );
  }

  Widget _buildBookingPicker(String userId, bool hasActiveSession) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return VoltCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Booking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Only QR-verified configuration allows you to start charging.',
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('bookings')
                .where('user_id', isEqualTo: userId)
                .where('status', whereIn: ['CONFIRMED', 'PENDING'])
                .snapshots(),
            builder: (context, snapshot) {
              final docs = (snapshot.data?.docs.toList() ?? [])
                ..sort((a, b) {
                  final aTime =
                      (a.data()['created_at'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime =
                      (b.data()['created_at'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });
              
              if (docs.isEmpty) {
                return const Text(
                  'No eligible bookings found. Scan a Host QR first.',
                );
              }

              final selectedExists = docs.any(
                (doc) => doc.id == _selectedBookingId,
              );
              final effectiveValue = selectedExists
                  ? _selectedBookingId
                  : docs.first.id;

              if (!selectedExists && _selectedBookingId != docs.first.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedBookingId = docs.first.id);
                  }
                });
              }

              return DropdownButtonFormField<String>(
                key: ValueKey(effectiveValue),
                initialValue: effectiveValue,
                items: docs.map((doc) {
                  final data = doc.data();
                  final title = data['listing_title'] as String? ?? 'Booking';
                  final status = data['status'] as String? ?? 'PENDING';
                  final verified = data['qr_verified'] as bool? ?? false;
                  final verifiedText = verified ? 'Verified' : status;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text('$title ($verifiedText)'),
                  );
                }).toList(),
                onChanged: hasActiveSession
                    ? null
                    : (value) {
                        setState(() => _selectedBookingId = value);
                      },
                decoration: const InputDecoration(
                  labelText: 'Session Booking',
                  prefixIcon: Icon(Icons.ev_station_rounded),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  ChargingSessionEntity _mapSession(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ChargingSessionEntity(
      id: doc.id,
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
  }
}

