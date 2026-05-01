import '../entities/booking_entity.dart';

abstract class BookingRepository {
  Future<BookingEntity> createBooking({
    required String listingId,
    required String packageId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  });

  Future<List<BookingEntity>> getBookingHistory();

  Future<BookingEntity> getBookingDetails(String id);

  Future<BookingEntity> verifyQrCode(String bookingId, String qrToken);

  Future<void> cancelBooking(String id);
}
