import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';

class HostDashboardPage extends StatefulWidget {
  const HostDashboardPage({super.key});

  @override
  State<HostDashboardPage> createState() => _HostDashboardPageState();
}

class _HostDashboardPageState extends State<HostDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to access host dashboard.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          tabs: const [
            Tab(icon: Icon(Icons.ev_station), text: 'Listings'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Packages'),
            Tab(icon: Icon(Icons.analytics), text: 'Earnings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListingsTab(hostId: user.uid, firestore: _firestore),
          _PackagesTab(hostId: user.uid, firestore: _firestore),
          _EarningsTab(hostId: user.uid, firestore: _firestore),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddListingDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Charger'),
      ),
    );
  }

  void _showAddListingDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final powerController = TextEditingController();
    String connectorType = AppStrings.connectorLabels.keys.first;
    LatLng? selectedLocation;

    final provinces = [
      'Western Province',
      'Central Province',
      'Southern Province',
      'Uva Province',
      'Sabaragamuwa Province',
      'North Western Province',
      'North Central Province',
      'Northern Province',
      'Eastern Province',
    ];
    String selectedProvince = provinces.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Charger',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Charger Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedProvince,
                          decoration: const InputDecoration(
                            labelText: 'Province',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                          items: provinces.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => selectedProvince = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: connectorType,
                    decoration: const InputDecoration(
                      labelText: 'Connector Type',
                      prefixIcon: Icon(Icons.electrical_services),
                    ),
                    items: AppStrings.connectorLabels.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => connectorType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: powerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Power Output (kW)',
                      prefixIcon: Icon(Icons.bolt),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location Picker Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exact Coordinates',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                selectedLocation != null
                                    ? '${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)}'
                                    : 'No location selected',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedLocation != null
                                      ? (isDark ? Colors.white70 : Colors.black87)
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.push<LatLng>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _LocationPickerScreen(
                                  initialLocation: selectedLocation ?? const LatLng(6.9271, 79.8612),
                                ),
                              ),
                            );
                            if (result != null) {
                              setModalState(() => selectedLocation = result);
                            }
                          },
                          child: const Text('Pick on Map'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GlowingButton(
                      label: 'Create Listing',
                      icon: Icons.add_circle,
                      onPressed: () async {
                        final user = _auth.currentUser;
                        if (user == null) return;

                        final title = titleController.text.trim();
                        final address = addressController.text.trim();
                        final city = cityController.text.trim();
                        final province = selectedProvince;
                        final power = double.tryParse(
                          powerController.text.trim(),
                        );

                        if (title.isEmpty ||
                            address.isEmpty ||
                            city.isEmpty ||
                            province.isEmpty ||
                            power == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please complete all required fields.',
                              ),
                            ),
                          );
                          return;
                        }

                        if (selectedLocation == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please pick the exact charger location on the map.',
                              ),
                            ),
                          );
                          return;
                        }

                        final qrToken = _generateQrToken();
                        final listingRef = await _firestore
                            .collection('chargers')
                            .add({
                              'host_id': user.uid,
                              'title': title,
                              'description': '',
                              'connector_type': connectorType,
                              'power_output_kw': power,
                              'address': address,
                              'city': city,
                              'province': province,
                              'latitude': selectedLocation!.latitude,
                              'longitude': selectedLocation!.longitude,
                              'is_active': true,
                              'qr_code_token': qrToken,
                              'avg_rating': 0.0,
                              'total_reviews': 0,
                              'created_at': FieldValue.serverTimestamp(),
                            });

                        await listingRef.collection('packages').add({
                          'name': 'Standard Charge',
                          'tier': 'STANDARD',
                          'price_per_kwh': 45.0,
                          'session_fee': 100.0,
                          'is_active': true,
                          'created_at': FieldValue.serverTimestamp(),
                        });

                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      titleController.dispose();
      addressController.dispose();
      cityController.dispose();
      powerController.dispose();
    });
  }

  String _generateQrToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

class _ListingsTab extends StatelessWidget {
  final String hostId;
  final FirebaseFirestore firestore;

  const _ListingsTab({required this.hostId, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('chargers')
          .where('host_id', isEqualTo: hostId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text('No chargers yet. Add your first listing.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final listing = doc.data();
            final isActive = listing['is_active'] as bool? ?? true;

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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.ev_station,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing['title'] as String? ?? 'Untitled',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                listing['address'] as String? ?? '-',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) async {
                            await firestore
                                .collection('chargers')
                                .doc(doc.id)
                                .update({'is_active': value});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatItem(
                          icon: Icons.bolt,
                          label:
                              '${((listing['power_output_kw'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} kW',
                        ),
                        const SizedBox(width: 16),
                        _StatItem(
                          icon: Icons.star,
                          label:
                              ((listing['avg_rating'] as num?)?.toDouble() ?? 0)
                                  .toStringAsFixed(1),
                        ),
                      ],
                    ),
                    if ((listing['qr_code_token'] as String?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white, // Ensure high contrast for QR scanning
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: QrImageView(
                                data: listing['qr_code_token'] as String,
                                version: QrVersions.auto,
                                size: 140,
                                gapless: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Show this code to customers to connect',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PackagesTab extends StatelessWidget {
  final String hostId;
  final FirebaseFirestore firestore;

  const _PackagesTab({required this.hostId, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return FutureBuilder<List<_HostPackageView>>(
      future: _loadPackages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final packages = snapshot.data!;
        if (packages.isEmpty) {
          return const Center(
            child: Text('No packages found for your listings.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final pkg = packages[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VoltCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(pkg.icon, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${pkg.listingTitle} • ${AppStrings.tierLabels[pkg.tier] ?? pkg.tier}',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${CurrencyFormatter.format(pkg.pricePerKwh, noDecimals: true)}/kWh',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '+ ${CurrencyFormatter.format(pkg.sessionFee, noDecimals: true)} fee',
                          style: TextStyle(color: secondaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_HostPackageView>> _loadPackages() async {
    final listingsSnapshot = await firestore
        .collection('chargers')
        .where('host_id', isEqualTo: hostId)
        .get();
    final packages = <_HostPackageView>[];

    for (final listing in listingsSnapshot.docs) {
      final listingData = listing.data();
      final packageSnapshot = await firestore
          .collection('chargers')
          .doc(listing.id)
          .collection('packages')
          .where('is_active', isEqualTo: true)
          .get();

      for (final pkgDoc in packageSnapshot.docs) {
        final pkg = pkgDoc.data();
        final tier = pkg['tier'] as String? ?? 'STANDARD';
        packages.add(
          _HostPackageView(
            listingTitle: listingData['title'] as String? ?? 'Listing',
            name: pkg['name'] as String? ?? 'Package',
            tier: tier,
            pricePerKwh: (pkg['price_per_kwh'] as num?)?.toDouble() ?? 0,
            sessionFee: (pkg['session_fee'] as num?)?.toDouble() ?? 0,
            icon: tier == 'EXPRESS'
                ? Icons.flash_on
                : tier == 'OVERNIGHT'
                ? Icons.nightlight
                : Icons.ev_station,
          ),
        );
      }
    }

    return packages;
  }
}

class _EarningsTab extends StatelessWidget {
  final String hostId;
  final FirebaseFirestore firestore;

  const _EarningsTab({required this.hostId, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return FutureBuilder<_HostEarningsSummary>(
      future: _loadSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final summary = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: VoltCard(
                      showGlow: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Earnings',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(summary.totalEarnings, noDecimals: true),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'After platform fee',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VoltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Month',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(summary.thisMonthEarnings, noDecimals: true),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.thisMonthSessions} sessions',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: VoltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Sessions',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.totalSessions}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VoltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avg Host Payout',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(summary.avgPayout, noDecimals: true),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_HostEarningsSummary> _loadSummary() async {
    final bookingsSnapshot = await firestore
        .collection('bookings')
        .where('host_id', isEqualTo: hostId)
        .where('status', isEqualTo: 'COMPLETED')
        .get();

    double totalEarnings = 0;
    double thisMonthEarnings = 0;
    int totalSessions = 0;
    int thisMonthSessions = 0;
    final now = DateTime.now();

    for (final doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final payout = (data['host_payout'] as num?)?.toDouble() ?? 0;
      final createdAt = (data['created_at'] as Timestamp?)?.toDate();
      totalEarnings += payout;
      totalSessions += 1;
      if (createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month) {
        thisMonthEarnings += payout;
        thisMonthSessions += 1;
      }
    }

    final avgPayout = totalSessions == 0 ? 0.0 : totalEarnings / totalSessions;
    return _HostEarningsSummary(
      totalEarnings: totalEarnings,
      thisMonthEarnings: thisMonthEarnings,
      totalSessions: totalSessions,
      thisMonthSessions: thisMonthSessions,
      avgPayout: avgPayout,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({required this.icon, required this.label});

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

class _HostPackageView {
  final String listingTitle;
  final String name;
  final String tier;
  final double pricePerKwh;
  final double sessionFee;
  final IconData icon;

  _HostPackageView({
    required this.listingTitle,
    required this.name,
    required this.tier,
    required this.pricePerKwh,
    required this.sessionFee,
    required this.icon,
  });
}

class _HostEarningsSummary {
  final double totalEarnings;
  final double thisMonthEarnings;
  final int totalSessions;
  final int thisMonthSessions;
  final double avgPayout;

  _HostEarningsSummary({
    required this.totalEarnings,
    required this.thisMonthEarnings,
    required this.totalSessions,
    required this.thisMonthSessions,
    required this.avgPayout,
  });
}

class _LocationPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const _LocationPickerScreen({required this.initialLocation});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
  }

  Future<void> _moveToLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final newLoc = LatLng(position.latitude, position.longitude);
    _mapController.move(newLoc, 15.0);
    setState(() {
      _currentCenter = newLoc;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Exact Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _currentCenter);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 13,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _currentCenter = position.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.voltshare_sl',
              ),
            ],
          ),
          // Crosshair
          const Center(
            child: Icon(
              Icons.location_pin,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Drag map to exactly position the pin',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToLiveLocation,
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.surfaceDark 
            : AppColors.surfaceLight,
        child: const Icon(Icons.my_location, color: AppColors.primary),
      ),
    );
  }
}

