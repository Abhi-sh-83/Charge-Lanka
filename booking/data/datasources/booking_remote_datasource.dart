import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  BookingRemoteDatasource(this._firestore, this._auth);

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to create a booking.');
    }

    final listingId = data['listing_id'] as String;
    final packageId = data['package_id'] as String;

    final listingDoc = await _firestore
        .collection('chargers')
        .doc(listingId)
        .get();
    if (!listingDoc.exists) {
      throw Exception('Selected charger listing is not available.');
    }
    final packageDoc = await _firestore
        .collection('chargers')
        .doc(listingId)
        .collection('packages')
        .doc(packageId)
        .get();
    if (!packageDoc.exists) {
      throw Exception('Selected charging package is not available.');
    }

    final listing = listingDoc.data()!;
    final package = packageDoc.data()!;

    final scheduledStart = DateTime.parse(data['scheduled_start'] as String);
    final scheduledEnd = DateTime.parse(data['scheduled_end'] as String);
    final durationHours =
        scheduledEnd.difference(scheduledStart).inMinutes / 60;
    final estimatedKwh = durationHours <= 0
        ? 1.0
        : durationHours *
              ((listing['power_output_kw'] as num?)?.toDouble() ?? 0);
    final sessionFee = (package['session_fee'] as num?)?.toDouble() ?? 0;
    final pricePerKwh = (package['price_per_kwh'] as num?)?.toDouble() ?? 0;
    final totalEstimate = (estimatedKwh * pricePerKwh) + sessionFee;
    final platformFee = totalEstimate * 0.10;
    final hostPayout = totalEstimate - platformFee;

    final bookingPayload = <String, dynamic>{
      'user_id': user.uid,
      'host_id': listing['host_id'],
      'listing_id': listingId,
      'package_id': packageId,
      'status': 'PENDING',
      'scheduled_start': Timestamp.fromDate(scheduledStart),
      'scheduled_end': Timestamp.fromDate(scheduledEnd),
      'total_estimate': totalEstimate,
      'platform_fee': platformFee,
      'host_payout': hostPayout,
      'qr_verified': false,
      'created_at': FieldValue.serverTimestamp(),
      'listing_title': listing['title'],
      'listing_address': listing['address'],
      'package_name': package['name'],
    };

    final bookingRef = await _firestore
        .collection('bookings')
        .add(bookingPayload);
    final created = await bookingRef.get();
    return _mapBookingDoc(created);
  }

  Future<List<BookingModel>> getBookingHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: user.uid)
        .get();

    final bookings = snapshot.docs.map(_mapBookingDoc).toList();
    
    // Fallback Dummy Data for Presentation / Showcase
    if (bookings.isEmpty) { 
      // Let's inject if they have less than 3 bookings
      if (bookings.length < 3) {
        bookings.addAll([
          BookingModel(
            id: 'booking-dummy-1',
            userId: user.uid,
            listingId: 'dummy-1',
            packageId: 'pkg-1',
            status: 'IN_PROGRESS',
            scheduledStart: DateTime.now().subtract(const Duration(minutes: 30)),
            scheduledEnd: DateTime.now().add(const Duration(minutes: 30)),
            totalEstimate: 1400.0,
            platformFee: 140.0,
            hostPayout: 1260.0,
            qrVerified: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            chargerTitle: 'Colombo City Center EV Station',
            chargerAddress: 'CCC, Sir James Pieris Mawatha',
            packageName: 'Fast Charge (22kW) - Level 2',
          ),
          BookingModel(
            id: 'booking-dummy-2',
            userId: user.uid,
            listingId: 'dummy-2',
            packageId: 'pkg-2',
            status: 'CONFIRMED',
            scheduledStart: DateTime.now().add(const Duration(hours: 24)),
            scheduledEnd: DateTime.now().add(const Duration(hours: 25)),
            totalEstimate: 2100.0,
            platformFee: 210.0,
            hostPayout: 1890.0,
            qrVerified: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            chargerTitle: 'One Galle Face Premium Charging',
            chargerAddress: 'One Galle Face, Colombo 01',
            packageName: 'Ultra Fast (50kW) - CSS',
          ),
          BookingModel(
            id: 'booking-dummy-3',
            userId: user.uid,
            listingId: 'dummy-3',
            packageId: 'pkg-3',
            status: 'COMPLETED',
            scheduledStart: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
            scheduledEnd: DateTime.now().subtract(const Duration(days: 2)),
            totalEstimate: 850.0,
            platformFee: 85.0,
            hostPayout: 765.0,
            qrVerified: true,
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            chargerTitle: 'Liberty Plaza EV Charging',
            chargerAddress: 'Liberty Plaza, Colombo 03',
            packageName: 'Standard Charge (7kW)',
          ),
        ]);
      }
    }

    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  Future<BookingModel> getBookingDetails(String id) async {
    final doc = await _firestore.collection('bookings').doc(id).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }
    return _mapBookingDoc(doc);
  }

  Future<BookingModel> verifyQrCode(String bookingId, String qrToken) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found.');
    }

    final booking = bookingDoc.data()!;
    final listingId = booking['listing_id'] as String?;
    if (listingId == null || listingId.isEmpty) {
      throw Exception('Invalid booking listing.');
    }

    final listingDoc = await _firestore
        .collection('chargers')
        .doc(listingId)
        .get();
    if (!listingDoc.exists) {
      throw Exception('Charger listing not found.');
    }
    final expectedToken = listingDoc.data()!['qr_code_token'] as String? ?? '';
    if (expectedToken.isEmpty || expectedToken != qrToken) {
      throw Exception('Invalid QR token.');
    }

    await bookingRef.update({
      'qr_verified': true,
      'status': 'CONFIRMED',
      'verified_at': FieldValue.serverTimestamp(),
    });

    final updated = await bookingRef.get();
    return _mapBookingDoc(updated);
  }

  Future<void> cancelBooking(String id) async {
    await _firestore.collection('bookings').doc(id).update({
      'status': 'CANCELLED',
      'cancelled_at': FieldValue.serverTimestamp(),
    });
  }

  BookingModel _mapBookingDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BookingModel(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      listingId: data['listing_id'] as String? ?? '',
      packageId: data['package_id'] as String? ?? '',
      status: data['status'] as String? ?? 'PENDING',
      scheduledStart:
          (data['scheduled_start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledEnd:
          (data['scheduled_end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalEstimate: (data['total_estimate'] as num?)?.toDouble() ?? 0,
      platformFee: (data['platform_fee'] as num?)?.toDouble() ?? 0,
      hostPayout: (data['host_payout'] as num?)?.toDouble() ?? 0,
      qrVerified: data['qr_verified'] as bool? ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      chargerTitle: data['listing_title'] as String?,
      chargerAddress: data['listing_address'] as String?,
      packageName: data['package_name'] as String?,
    );
  }
}
