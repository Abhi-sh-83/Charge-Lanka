import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class VerifyQrUseCase {
  final BookingRepository repository;
  VerifyQrUseCase(this.repository);

  Future<BookingEntity> call({
    required String bookingId,
    required String qrToken,
  }) {
    return repository.verifyQrCode(bookingId, qrToken);
  }
}
