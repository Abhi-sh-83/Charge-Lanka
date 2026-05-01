import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_booking_history_usecase.dart';
import '../../domain/usecases/verify_qr_usecase.dart';

// ──── Events ────
abstract class BookingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateBooking extends BookingEvent {
  final String listingId;
  final String packageId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;

  CreateBooking({
    required this.listingId,
    required this.packageId,
    required this.scheduledStart,
    required this.scheduledEnd,
  });

  @override
  List<Object?> get props => [listingId, packageId, scheduledStart];
}

class LoadBookingHistory extends BookingEvent {}

class CancelBooking extends BookingEvent {
  final String bookingId;
  CancelBooking(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

class VerifyQR extends BookingEvent {
  final String bookingId;
  final String qrToken;
  VerifyQR({required this.bookingId, required this.qrToken});
  @override
  List<Object?> get props => [bookingId, qrToken];
}

// ──── States ────
abstract class BookingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingCreated extends BookingState {
  final BookingEntity booking;
  BookingCreated(this.booking);
  @override
  List<Object?> get props => [booking];
}

class BookingHistoryLoaded extends BookingState {
  final List<BookingEntity> bookings;
  BookingHistoryLoaded(this.bookings);
  @override
  List<Object?> get props => [bookings];
}

class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
  @override
  List<Object?> get props => [message];
}

class QRVerified extends BookingState {
  final BookingEntity booking;
  QRVerified(this.booking);
  @override
  List<Object?> get props => [booking];
}

// ──── BLoC ────
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final CreateBookingUseCase createBooking;
  final GetBookingHistoryUseCase getBookingHistory;
  final CancelBookingUseCase cancelBooking;
  final VerifyQrUseCase verifyQr;

  BookingBloc({
    required this.createBooking,
    required this.getBookingHistory,
    required this.cancelBooking,
    required this.verifyQr,
  }) : super(BookingInitial()) {
    on<CreateBooking>(_onCreate);
    on<LoadBookingHistory>(_onLoadHistory);
    on<CancelBooking>(_onCancelBooking);
    on<VerifyQR>(_onVerifyQr);
  }

  Future<void> _onCreate(
    CreateBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final booking = await createBooking(
        listingId: event.listingId,
        packageId: event.packageId,
        scheduledStart: event.scheduledStart,
        scheduledEnd: event.scheduledEnd,
      );
      emit(BookingCreated(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(
    LoadBookingHistory event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final bookings = await getBookingHistory();
      emit(BookingHistoryLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      await cancelBooking(event.bookingId);
      final bookings = await getBookingHistory();
      emit(BookingHistoryLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onVerifyQr(VerifyQR event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final booking = await verifyQr(
        bookingId: event.bookingId,
        qrToken: event.qrToken,
      );
      emit(QRVerified(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
