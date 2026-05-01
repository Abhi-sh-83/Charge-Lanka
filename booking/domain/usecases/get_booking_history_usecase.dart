import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class GetBookingHistoryUseCase {
  final BookingRepository repository;
  GetBookingHistoryUseCase(this.repository);

  Future<List<BookingEntity>> call() {
    return repository.getBookingHistory();
  }
}
