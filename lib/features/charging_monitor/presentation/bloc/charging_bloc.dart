import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/charging_session_entity.dart';
import '../../domain/usecases/start_session_usecase.dart';
import '../../domain/usecases/stop_session_usecase.dart';

// ──── Events ────
abstract class ChargingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartSession extends ChargingEvent {
  final String bookingId;
  StartSession(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

class StopSession extends ChargingEvent {
  final String sessionId;
  StopSession(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class UpdateSessionMetrics extends ChargingEvent {
  final ChargingSessionEntity session;
  UpdateSessionMetrics(this.session);
  @override
  List<Object?> get props => [session];
}

// ──── States ────
abstract class ChargingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionIdle extends ChargingState {}

class SessionLoading extends ChargingState {}

class SessionActive extends ChargingState {
  final ChargingSessionEntity session;
  SessionActive(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionCompleted extends ChargingState {
  final ChargingSessionEntity session;
  SessionCompleted(this.session);
  @override
  List<Object?> get props => [session];
}

class SessionError extends ChargingState {
  final String message;
  SessionError(this.message);
  @override
  List<Object?> get props => [message];
}

// ──── BLoC ────
class ChargingBloc extends Bloc<ChargingEvent, ChargingState> {
  final StartSessionUseCase startSession;
  final StopSessionUseCase stopSession;

  ChargingBloc({required this.startSession, required this.stopSession})
    : super(SessionIdle()) {
    on<StartSession>(_onStart);
    on<StopSession>(_onStop);
    on<UpdateSessionMetrics>(_onUpdate);
  }

  Future<void> _onStart(StartSession event, Emitter<ChargingState> emit) async {
    emit(SessionLoading());
    try {
      final session = await startSession(event.bookingId);
      emit(SessionActive(session));
    } catch (e) {
      emit(SessionError(e.toString()));
    }
  }

  Future<void> _onStop(StopSession event, Emitter<ChargingState> emit) async {
    emit(SessionLoading());
    try {
      final session = await stopSession(event.sessionId);
      emit(SessionCompleted(session));
    } catch (e) {
      emit(SessionError(e.toString()));
    }
  }

  void _onUpdate(UpdateSessionMetrics event, Emitter<ChargingState> emit) {
    if (event.session.status == 'COMPLETED') {
      emit(SessionCompleted(event.session));
    } else {
      emit(SessionActive(event.session));
    }
  }
}
