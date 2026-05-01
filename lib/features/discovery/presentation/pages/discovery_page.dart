import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';
import '../../domain/entities/charger_entity.dart';
import '../bloc/discovery_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  final _searchController = TextEditingController();
  String? _selectedConnector;

  // Default: Colombo, Sri Lanka
  static const _defaultLatLng = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _loadChargers(_defaultLatLng.latitude, _defaultLatLng.longitude);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _loadChargers(_defaultLatLng.latitude, _defaultLatLng.longitude);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _loadChargers(_defaultLatLng.latitude, _defaultLatLng.longitude);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    setState(() => _currentPosition = position);
    _loadChargers(position.latitude, position.longitude);
  }

  void _loadChargers(double lat, double lng) {
    context.read<DiscoveryBloc>().add(
      LoadNearbyChargers(
        latitude: lat,
        longitude: lng,
        connectorType: _selectedConnector,
      ),
    );
  }

  List<Marker> _buildMarkers(List<ChargerEntity> chargers) {
    return chargers.map((charger) {
      return Marker(
        point: LatLng(charger.latitude, charger.longitude),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () {
            _showQRCodeDialog(context, charger);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.ev_station_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showQRCodeDialog(BuildContext context, ChargerEntity charger) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  charger.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: charger.qrCodeToken,
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: isDark ? Colors.black87 : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GlowingButton(
                    label: 'View Station Details',
                    icon: Icons.info_outline,
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<DiscoveryBloc>().add(SelectCharger(charger));
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          return Stack(
            children: [
              // ── Map Layer ──
              BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  final chargers = state is DiscoveryLoaded
                      ? state.chargers
                      : <ChargerEntity>[];

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition != null
                          ? LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                          : _defaultLatLng,
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.voltshare_sl',
                      ),
                      MarkerLayer(
                        markers: _buildMarkers(chargers),
                      ),
                    ],
                  );
                },
              ),

              // ── Search Bar Overlay ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight)
                            .withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onSubmitted: (value) {
                          context.read<DiscoveryBloc>().add(
                            SearchChargers(value),
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'Search chargers near you...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.tune,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            onPressed: () => _showFilterSheet(context),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          fillColor: Colors.transparent,
                          filled: true,
                        ),
                      ),
                      // ── Connector Filter Chips ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 8,
                        ),
                        child: Row(
                          children: AppStrings.connectorLabels.entries.map((
                            entry,
                          ) {
                            final isSelected = _selectedConnector == entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedConnector = selected
                                        ? entry.key
                                        : null;
                                  });
                                  context.read<DiscoveryBloc>().add(
                                    FilterByConnector(_selectedConnector),
                                  );
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── QR Scan FAB ──
              Positioned(
                bottom: isWide ? 80 : 336,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'qrScan',
                  backgroundColor: AppColors.primary,
                  onPressed: () => GoRouter.of(context).push('/qr-scanner'),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                  ),
                ),
              ),

              // ── My Location FAB ──
              Positioned(
                bottom: isWide ? 24 : 280,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'location',
                  backgroundColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  onPressed: () async {
                    if (_currentPosition != null) {
                      _mapController.move(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        13,
                      );
                    }
                  },
                  child: const Icon(
                    Icons.my_location,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // ── Bottom Charger Detail Sheet ──
              BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryLoaded &&
                      state.selectedCharger != null) {
                    return _ChargerDetailSheet(
                      charger: state.selectedCharger!,
                      isWide: isWide,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Chargers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connector Type',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppStrings.connectorLabels.entries.map((entry) {
                  return FilterChip(
                    label: Text(entry.value),
                    selected: _selectedConnector == entry.key,
                    onSelected: (selected) {
                      setState(
                        () => _selectedConnector = selected ? entry.key : null,
                      );
                      Navigator.pop(context);
                      context.read<DiscoveryBloc>().add(
                        FilterByConnector(_selectedConnector),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}

class _ChargerDetailSheet extends StatelessWidget {
  final ChargerEntity charger;
  final bool isWide;

  const _ChargerDetailSheet({required this.charger, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final bookingBloc = context.read<BookingBloc>();

    return Positioned(
      bottom: 0,
      left: 0,
      right: isWide ? MediaQuery.of(context).size.width * 0.5 : 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        charger.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${charger.address}, ${charger.city}',
                        style: TextStyle(color: secondaryText, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        charger.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Specs row
            Row(
              children: [
                _SpecChip(
                  icon: Icons.bolt,
                  label: EnergyFormatter.formatPower(charger.powerOutputKw),
                ),
                const SizedBox(width: 8),
                _SpecChip(
                  icon: Icons.electrical_services,
                  label:
                      AppStrings.connectorLabels[charger.connectorType] ??
                      charger.connectorType,
                ),
                if (charger.distanceMeters != null) ...[
                  const SizedBox(width: 8),
                  _SpecChip(
                    icon: Icons.near_me,
                    label: DistanceFormatter.format(charger.distanceMeters!),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Packages
            if (charger.packages.isNotEmpty) ...[
              const Text(
                'Charging Packages',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ...charger.packages.map(
                (pkg) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: VoltCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          pkg.tier == 'EXPRESS'
                              ? Icons.flash_on
                              : pkg.tier == 'OVERNIGHT'
                              ? Icons.nightlight
                              : Icons.ev_station,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pkg.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                pkg.tierLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(pkg.pricePerKwh, noDecimals: true)}/kWh',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${charger.latitude},${charger.longitude}',
                      );
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlowingButton(
                    label: 'Book Now',
                    icon: Icons.calendar_today,
                    onPressed: () {
                      if (charger.packages.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No packages available for this charger.',
                            ),
                          ),
                        );
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => _BookingBottomSheet(
                          charger: charger,
                          bookingBloc: bookingBloc,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingBottomSheet extends StatefulWidget {
  final ChargerEntity charger;
  final BookingBloc bookingBloc;

  const _BookingBottomSheet({required this.charger, required this.bookingBloc});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  late ChargingPackageEntity _selectedPackage;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationHours = 1;

  @override
  void initState() {
    super.initState();
    _selectedPackage = widget.charger.packages.first;
    // Round time to nearest 15 mins for convenience if needed, but keeping it simple
    final now = TimeOfDay.now();
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute + 15 > 59 ? 59 : now.minute + 15);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _confirmBooking() {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    if (start.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be in the future.')),
      );
      return;
    }

    final end = start.add(Duration(hours: _durationHours));

    widget.bookingBloc.add(
      CreateBooking(
        listingId: widget.charger.id,
        packageId: _selectedPackage.id,
        scheduledStart: start,
        scheduledEnd: end,
      ),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking formally requested!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    
    // Simplistic estimated energy map: 1 hour roughly equals 7 kWh for a standard home charger.
    final estEnergy = 7.0 * _durationHours;
    final estimatedCost = _selectedPackage.pricePerKwh * estEnergy;

    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 20, 
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Schedule Booking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Select Package', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ChargingPackageEntity>(
              value: _selectedPackage,
              isExpanded: true,
              items: widget.charger.packages.map((pkg) {
                return DropdownMenuItem(
                  value: pkg,
                  child: Text('${pkg.name} - ${CurrencyFormatter.format(pkg.pricePerKwh, noDecimals: true)}/kWh'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPackage = val);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.ev_station_rounded),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Start Date & Time', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today)),
                      child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.access_time)),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Duration (Hours)', style: TextStyle(fontWeight: FontWeight.w600)),
            Slider(
              value: _durationHours.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '$_durationHours Hours',
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _durationHours = val.toInt());
              },
            ),
            Center(
              child: Text(
                'Estimated end time: ${_selectedTime.replacing(hour: (_selectedTime.hour + _durationHours) % 24).format(context)}',
                style: TextStyle(color: secondaryText, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Est. Total', style: TextStyle(color: secondaryText)),
                    Text(
                      CurrencyFormatter.format(estimatedCost, noDecimals: true),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                GlowingButton(
                  label: 'Confirm Booking',
                  icon: Icons.check_circle_outline,
                  onPressed: _confirmBooking,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
