import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository repository;
  CreateBookingUseCase(this.repository);

  Future<BookingEntity> call({
    required String listingId,
    required String packageId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) {
    return repository.createBooking(
      listingId: listingId,
      packageId: packageId,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
    );
  }
}
