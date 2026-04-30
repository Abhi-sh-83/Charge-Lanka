import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDatasource _remoteDatasource;
  BookingRepositoryImpl(this._remoteDatasource);

  @override
  Future<BookingEntity> createBooking({
    required String listingId,
    required String packageId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) {
    return _remoteDatasource.createBooking({
      'listing_id': listingId,
      'package_id': packageId,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
    });
  }

  @override
  Future<List<BookingEntity>> getBookingHistory() {
    return _remoteDatasource.getBookingHistory();
  }

  @override
  Future<BookingEntity> getBookingDetails(String id) {
    return _remoteDatasource.getBookingDetails(id);
  }

  @override
  Future<BookingEntity> verifyQrCode(String bookingId, String qrToken) {
    return _remoteDatasource.verifyQrCode(bookingId, qrToken);
  }

  @override
  Future<void> cancelBooking(String id) {
    return _remoteDatasource.cancelBooking(id);
  }
}
