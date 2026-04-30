import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../bloc/booking_bloc.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(LoadBookingHistory());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/qr-scanner'),
            tooltip: 'Scan QR to Verify',
          ),
        ],
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingHistoryLoaded) {
            if (state.bookings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No bookings yet. Discover a charger and place your first booking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryText),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) {
                final booking = state.bookings[index];
                final isActive =
                    booking.status == 'IN_PROGRESS' ||
                    booking.status == 'CONFIRMED';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VoltCard(
                    showGlow: isActive,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : (isDark
                                          ? AppColors.cardDark
                                          : const Color(0xFFF0F4FF)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isActive
                                    ? Icons.bolt
                                    : Icons.ev_station_outlined,
                                color: isActive
                                    ? AppColors.primary
                                    : secondaryText,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.chargerTitle ?? 'Charging Session',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    booking.chargerAddress ?? '-',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip.fromBookingStatus(booking.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _BookingDetail(
                              icon: Icons.inventory_2_outlined,
                              label: booking.packageName ?? '-',
                            ),
                            const SizedBox(width: 16),
                            _BookingDetail(
                              icon: Icons.calendar_today_outlined,
                              label: DateTimeFormatter.formatDate(
                                booking.scheduledStart,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _BookingDetail(
                              icon: Icons.schedule,
                              label:
                                  '${booking.scheduledStart.hour.toString().padLeft(2, '0')}:${booking.scheduledStart.minute.toString().padLeft(2, '0')}',
                            ),
                            const Spacer(),
                            Text(
                              CurrencyFormatter.format(booking.totalEstimate),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (booking.status == 'PENDING') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    context.read<BookingBloc>().add(
                                      CancelBooking(booking.id),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GlowingButton(
                                  label: 'Scan QR',
                                  icon: Icons.qr_code_scanner,
                                  onPressed: () => context.push('/qr-scanner'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (booking.status == 'IN_PROGRESS') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: GlowingButton(
                              label: 'View Live Session',
                              icon: Icons.monitor_heart,
                              onPressed: () => context.push('/charging'),
                            ),
                          ),
                        ],
                        if (booking.status == 'CONFIRMED') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/qr-scanner'),
                              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                              label: const Text('Check In (Scan QR)'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return Center(
            child: Text(
              'Loading bookings...',
              style: TextStyle(color: secondaryText),
            ),
          );
        },
      ),
    );
  }
}

class _BookingDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BookingDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
